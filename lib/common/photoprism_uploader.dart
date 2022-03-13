import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/db_api.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismUploader {
  PhotoprismUploader(this.photoprismModel) {
    initialize();
  }

  PhotoprismModel photoprismModel;
  Completer<int> manualUploadFinishedCompleter;
  FlutterUploader uploader;
  String deviceName = '';
  Map<String, Album> deviceAlbums = <String, Album>{};
  int uploadsinProgress = 0;
  int failedUploads = 0;

  Future<void> initialize() async {
    await loadPreferences();
    if (!photoprismModel.autoUploadEnabled) {
      print('photo upload disabled');
      return;
    }
    initPlatformState(photoprismModel);
    getPhotosToUpload(photoprismModel);

    uploader = FlutterUploader();
    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((Object e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });

    uploader.progress.listen((UploadTaskProgress progress) {
      //print("Progress: " + progress.progress.toString());
    });

    uploader.result.listen((UploadTaskResponse result) async {
      uploadsinProgress--;
      if (result.statusCode != 200) {
        failedUploads++;
      }

      if (uploadsinProgress == 0) {
        print('Upload finished.');
        manualUploadFinishedCompleter.complete(failedUploads == 0 ? 0 : 1);
        // clear out the failedUploads count manually, to make sure we're
        // set up for the next upload
        failedUploads = 0;
      }
    }, onError: (Object ex, StackTrace stacktrace) {
      uploadsinProgress--;
      failedUploads++;

      if (uploadsinProgress == 0) {
        manualUploadFinishedCompleter.complete(failedUploads == 0 ? 0 : 1);
        // clear out the failedUploads count manually, to make sure we're
        // set up for the next upload
        failedUploads = 0;
      }
    });
  }

  Future<void> setAutoUpload(bool autoUploadEnabledNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadEnabled', autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notify();
    getPhotosToUpload(photoprismModel);
  }

  Future<void> setAutoUploadWifiOnly(bool autoUploadWifiOnlyNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadWifiOnly', autoUploadWifiOnlyNew);
    photoprismModel.autoUploadWifiOnly = autoUploadWifiOnlyNew;
    photoprismModel.notify();
  }

  Future<void> setAutoUploadLastTimeActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // get current date and time
    final DateTime now = DateTime.now();
    final String currentTime = DateFormat('dd.MM.yyyy – HH:mm').format(now);

    prefs.setString('autoUploadLastTimeActive', currentTime.toString());
    photoprismModel.autoUploadLastTimeCheckedForPhotos = currentTime.toString();
    photoprismModel.notify();
  }

  Future<void> loadPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    photoprismModel.autoUploadEnabled =
        prefs.getBool('autoUploadEnabled') ?? false;
    photoprismModel.autoUploadLastTimeCheckedForPhotos =
        prefs.getString('autoUploadLastTimeActive') ?? 'Never';
    photoprismModel.notify();
  }

  /// Starts image file picker, uploads photo(s) and imports them.
  Future<void> selectPhotoAndUpload(BuildContext context) async {
    final FilePickerResult result =
        await FilePicker.platform.pickFiles(type: FileType.media);

    // list for flutter uploader
    final List<FileItem> filesToUpload = <FileItem>[];

    // check if at least one file was selected
    if (result != null) {
      filesToUpload
          .addAll(result.files.map<FileItem>((PlatformFile file) => FileItem(
                field: 'files',
                path: file.path,
              )));

      if (result.count > 1) {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen('Uploading photos..');
      } else {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen('Uploading photo..');
      }

      final Random rng = Random.secure();
      String event = '';
      for (int i = 0; i < 12; i++) {
        event += rng.nextInt(9).toString();
      }

      print('Uploading event ' + event);

      final int status = await uploadPhoto(filesToUpload, event);

      if (status == 0) {
        print('Manual upload successful.');
        print('Importing photos..');
        photoprismModel.photoprismLoadingScreen
            .updateLoadingScreen('Importing photos..');
        final int status = await apiImportPhotoEvent(photoprismModel, event);

        if (status == 0) {
          await apiUpdateDb(photoprismModel);
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage
              .showMessage('Uploading and importing successful.');
        } else if (status == 3) {
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage
              .showMessage('Photo already imported or import failed.');
        } else {
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage.showMessage('Importing failed.');
        }
      } else {
        print('Manual upload failed.');
        await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
        photoprismModel.photoprismMessage.showMessage('Manual upload failed.');
      }
    }
  }

  Future<int> uploadPhoto(List<FileItem> filesToUpload, String event) async {
    manualUploadFinishedCompleter = Completer<int>();

    await apiGetNewSession(photoprismModel);
    for (final FileItem fileToUpload in filesToUpload) {
      await uploader.enqueue(RawUpload(
          url: photoprismModel.photoprismUrl + '/api/v1/upload/' + event,
          path: fileToUpload.path,
          method: UploadMethod.POST,
          tag: 'manual',
          headers: photoprismModel.photoprismAuth.getAuthHeaders()));
      uploadsinProgress += 1;
    }

    return manualUploadFinishedCompleter.future;
  }

  static Future<void> getPhotosToUpload(PhotoprismModel model) async {
    if (!model.autoUploadEnabled) {
      return;
    }

    if ((await photolib.PhotoManager.requestPermissionExtend()).isAuth) {
      final List<photolib.AssetPathEntity> albums =
          await photolib.PhotoManager.getAssetPathList();
      final Set<String> photosToUpload = <String>{};
      for (final photolib.AssetPathEntity album in albums) {
        if (model.albumsToUpload.contains(album.id)) {
          const int pageSize = 100;
          int page = 0;
          List<photolib.AssetEntity> entries;
          do {
            entries = await album.getAssetListPaged(page: page, size: pageSize);
            entries = filterForNonUploadedFiles(entries, model);
            photosToUpload
                .addAll(entries.map((photolib.AssetEntity e) => e.id));
            page++;
          } while (entries.length == pageSize);
        }
      }
      model.photosToUpload = photosToUpload;
    }
  }

  Future<void> initPlatformState(PhotoprismModel model) async {
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: false,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      try {
        runAutoUploadBackgroundRoutine(model, taskId);
      } finally {
        BackgroundFetch.finish(taskId);
      }
    }).then((int status) {
      model.addLogEntry(
          'AutoUploader',
          'Configuration of auto uploader successful. Status: ' +
              status.toString());
    }).catchError((Object e) {
      model.addLogEntry(
          'AutoUploader', 'ERROR: Configuration of auto uploader failed.');
    });
  }

  Future<void> runAutoUploadBackgroundRoutine(
      PhotoprismModel model, String taskId) async {
    model.addLogEntry(
        'AutoUploader', 'Starting autoupload routine. Task ID: ' + taskId);

    if (!photoprismModel.autoUploadEnabled) {
      model.addLogEntry(
          'AutoUploader', 'Auto upload disabled. Stopping autoupload routine.');
      return;
    }

    if (photoprismModel.autoUploadWifiOnly) {
      final ConnectivityResult connectivityResult =
          await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        model.addLogEntry('AutoUploader',
            'Auto upload requires Wi-Fi. Stopping autoupload routine.');
        return;
      }
    }

    if (photoprismModel.photoprismUrl == 'https://demo.photoprism.org' ||
        photoprismModel.photoprismUrl == 'https://photoprism.p4u1.de') {
      model.addLogEntry('AutoUploader',
          'Auto upload disabled for demo page. Stopping autoupload routine.');
      return;
    }

    // Set date and time when background routine was run last time.
    setAutoUploadLastTimeActive();

    await getPhotosToUpload(photoprismModel);

    deviceName = await getNameOfCurrentDevice(model);
    model.addLogEntry('AutoUploader', 'Getting device name: ' + deviceName);

    // Get list of albums from server which name is equal to current device name.
    final int status = await getRemoteAlbumsWithDeviceName(model);
    if (status == -1) {
      model.addLogEntry('AutoUploader',
          'ERROR: Album search failed. Stopping autoupload routine.');
      return;
    } else {
      model.addLogEntry('AutoUploader', 'Album search successful.');
    }

    final List<photolib.AssetPathEntity> albumList =
        await photolib.PhotoManager.getAssetPathList();

    String albumsString = '';
    int albumsCount = 0;
    for (final photolib.AssetPathEntity album in albumList) {
      if (albumsString == '') {
        albumsString += "'";
        albumsString += album.name;
        albumsString += "'";
      } else {
        albumsString += ', ';
        albumsString += "'";
        albumsString += album.name;
        albumsString += "'";
      }
      albumsCount++;
    }

    model.addLogEntry(
        'AutoUploader',
        'Found ' +
            albumsCount.toString() +
            ' albums on device: ' +
            albumsString);

    // Iterate through albums on smartphone.
    for (final photolib.AssetPathEntity album in albumList) {
      // Check if album should be uploaded to server.
      if (photoprismModel.albumsToUpload.contains(album.id)) {
        model.addLogEntry('AutoUploader',
            "Next, uploading all new photos of album '" + album.name + "'.");
        await uploadPhotosFromAlbum(album, model);
      } else {
        model.addLogEntry(
            'AutoUploader',
            "Skipping album '" +
                album.name +
                "' since it is not marked for uploading.");
      }
    }
    model.addLogEntry('AutoUploader', 'Autoupload routine finished.');
  }

  Future<int> getRemoteAlbumsWithDeviceName(PhotoprismModel model) async {
    // Get list of albums from server which name is the device name of the smartphone.
    await apiUpdateDb(model);
    final List<Album> deviceAlbumList = model.albums
        .where((Album album) => album.title.contains(deviceName))
        .toList();
    if (deviceAlbumList == null) {
      return -1;
    }

    deviceAlbums = Map<String, Album>.fromEntries(deviceAlbumList
        .map((Album album) => MapEntry<String, Album>(album.title, album)));

    return 0;
  }

  Future<void> uploadPhotosFromAlbum(
      photolib.AssetPathEntity album, PhotoprismModel model) async {
    model.addLogEntry('AutoUploader', 'Creating album for mobile uploads.');

    String albumId;
    final String albumName = '$deviceName – ${album.name}';

    if (deviceAlbums.containsKey(albumName)) {
      albumId = deviceAlbums[albumName].uid;
      model.addLogEntry(
          'AutoUploader',
          "Album '" +
              albumName +
              "' already exists in photoprism, album ID: '" +
              albumId +
              "'.");
    } else {
      model.addLogEntry('AutoUploader',
          "Album '" + albumName + "' not found, will be created.");
      albumId = await apiCreateAlbum(albumName, photoprismModel);
      if (albumId == '-1') {
        model.addLogEntry('AutoUploader',
            "ERROR: Album creation of ' " + albumName + "' failed.");
        return;
      } else {
        model.addLogEntry(
            'AutoUploader', "Album creation '" + albumName + "' successful.");
      }
    }

    final Map<String, photolib.AssetEntity> assets =
        await getPhotoAssetsAsMap(album.id);

    for (final String id in photoprismModel.photosToUpload) {
      if (!photoprismModel.autoUploadEnabled) {
        model.addLogEntry(
            'AutoUploader', 'Automatic photo upload was disabled, stopping.');
        break;
      }

      if (!assets.containsKey(id)) {
        model.addLogEntry(
            'AutoUploader',
            "ERROR: Photo which should be uploaded with ID '" +
                id +
                "' was not found on the phone.");
        continue;
      }

      final String filename = await assets[id].titleAsync;
      final io.File imageFile = await assets[id].originFile;
      final String filehash =
          (await sha1.bind(imageFile.openRead()).first).toString();

      model.addLogEntry('AutoUploader',
          "Next photo: '" + filename + "' and ID: '" + id + "'.");

      if (await isPhotoOnServerAndAddToAlbum(
          photoprismModel, id, filehash, albumId)) {
        model.addLogEntry(
            'AutoUploader',
            "Photo $filename was already uploaded and added to album '" +
                albumName +
                "'. Skipping uploading and importing.");
        continue;
      }

      model.addLogEntry('AutoUploader', "Uploading photo '" + filename + "'.");
      final bool status =
          await apiUpload(photoprismModel, filehash, filename, imageFile);
      if (status) {
        model.addLogEntry(
            'AutoUploader', "Uploading photo $filename successful'.");
      } else {
        model.addLogEntry('AutoUploader',
            "Uploading photo $filename failed'. Skipping to next photo.");
        continue;
      }

      // add uploaded photo to shared pref
      if (await apiImportPhotos(
          photoprismModel.photoprismUrl, photoprismModel, filehash)) {
        await apiUpdateDb(model);
        if (await isPhotoOnServerAndAddToAlbum(
            photoprismModel, id, filehash, albumId)) {
          model.addLogEntry('AutoUploader',
              'Photo $filename was imported and added to album.');
          continue;
        }
      } else {
        model.addLogEntry(
            'AutoUploader', 'ERROR: Photo $filename could not be imported.');
      }
      model.addLogEntry(
          'AutoUploader', 'Adding photo $filename to failed upload list.');
      saveAndSetPhotosUploadFailed(
          photoprismModel, photoprismModel.photosUploadFailed..add(id));
    }
  }

  static Future<bool> isPhotoOnServerAndAddToAlbum(
      PhotoprismModel model, String id, String filehash, String albumId) async {
    final List<File> file = await model.database.getFileFromHash(filehash);
    if (file == null || file.isEmpty || file[0].photoUID == null) {
      return false;
    }
    if (!await model.database.isPhotoAlbum(file[0].photoUID, albumId)) {
      if (await apiAddPhotosToAlbum(
              albumId, <String>[file[0].photoUID], model) !=
          0) {
        return false;
      }
    }
    saveAndSetAlreadyUploadedPhotos(
        model, model.alreadyUploadedPhotos..add(id));
    return true;
  }

  static Future<void> saveAndSetAlreadyUploadedPhotos(
      PhotoprismModel model, Set<String> alreadyUploadedPhotos) async {
    model.alreadyUploadedPhotos = alreadyUploadedPhotos;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'alreadyUploadedPhotos', alreadyUploadedPhotos.toList());
    await getPhotosToUpload(model);
  }

  static Future<void> saveAndSetPhotosUploadFailed(
      PhotoprismModel model, Set<String> photosUploadFailed) async {
    model.photosUploadFailed = photosUploadFailed;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('photosUploadFailed', photosUploadFailed.toList());
    await getPhotosToUpload(model);
  }

  static Future<void> saveAndSetAlbumsToUpload(
      PhotoprismModel model, Set<String> albumsToUpload) async {
    model.albumsToUpload = albumsToUpload;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('albumsToUpload', albumsToUpload.toList());
    await getPhotosToUpload(model);
  }

  static List<photolib.AssetEntity> filterForNonUploadedFiles(
      List<photolib.AssetEntity> entries, PhotoprismModel model,
      {bool checkServer = false}) {
    final List<photolib.AssetEntity> filteredEntries = <photolib.AssetEntity>[];
    for (final photolib.AssetEntity entry in entries) {
      if (model.alreadyUploadedPhotos.contains(entry.id)) {
        continue;
      }
      if (model.photosUploadFailed.contains(entry.id)) {
        continue;
      }
      filteredEntries.add(entry);
    }
    return filteredEntries;
  }

  static Future<void> clearFailedUploadList(PhotoprismModel model) async {
    await PhotoprismUploader.saveAndSetPhotosUploadFailed(model, <String>{});
  }

  static Future<Map<String, photolib.AssetEntity>> getPhotoAssetsAsMap(
      String id) async {
    final List<photolib.AssetPathEntity> list =
        await photolib.PhotoManager.getAssetPathList();
    final Map<String, photolib.AssetEntity> result =
        <String, photolib.AssetEntity>{};

    for (final photolib.AssetPathEntity album in list) {
      if (album.id == id) {
        const int pageSize = 100;
        int page = 0;
        List<photolib.AssetEntity> entries;
        do {
          entries = await album.getAssetListPaged(page: page, size: pageSize);
          result.addEntries(entries.map((photolib.AssetEntity asset) =>
              MapEntry<String, photolib.AssetEntity>(asset.id, asset)));
          page++;
        } while (entries.length == pageSize);
      }
    }
    return result;
  }

  // Returns the device name of the current device (smartphone).
  static Future<String> getNameOfCurrentDevice(PhotoprismModel model) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (io.Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (io.Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    model.addLogEntry(
        'AutoUploader', 'ERROR: Failed to get name of this device.');
    return '';
  }
}

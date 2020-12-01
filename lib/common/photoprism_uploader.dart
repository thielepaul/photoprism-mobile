import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/model/album.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;

class PhotoprismUploader {
  PhotoprismUploader(this.photoprismModel) {
    loadPreferences();
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
      print('Upload finished.');
      if (result.statusCode == 200) {
        if (result.tag == 'manual') {
          manualUploadFinishedCompleter.complete(0);
        } else {
          print('Auto upload success!');
          uploadFinishedCompleter.complete(0);
        }
      } else {
        if (result.tag == 'manual') {
          manualUploadFinishedCompleter.complete(2);
        } else {
          uploadFinishedCompleter.complete(2);
        }
      }
    }, onError: (Object ex, StackTrace stacktrace) {
      final UploadException exp = ex as UploadException;

      if (exp.tag == 'manual') {
        manualUploadFinishedCompleter.complete(1);
      } else {
        uploadFinishedCompleter.complete(1);
      }
    });
  }

  PhotoprismModel photoprismModel;
  Completer<int> uploadFinishedCompleter;
  Completer<int> manualUploadFinishedCompleter;
  FlutterUploader uploader;
  String deviceName = '';
  Map<String, Album> deviceAlbums = <String, Album>{};

  Future<void> setAutoUpload(bool autoUploadEnabledNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadEnabled', autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notify();
    getPhotosToUpload(photoprismModel);
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
    final List<File> files = await FilePicker.getMultiFile();

    // list for flutter uploader
    final List<FileItem> filesToUpload = <FileItem>[];

    // check if at least one file was selected
    if (files != null) {
      filesToUpload.addAll(files.map<FileItem>((File file) => FileItem(
          filename: basename(file.path),
          savedDir: dirname(file.path),
          fieldname: 'files')));

      if (files.length > 1) {
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
        final int status = await Api.importPhotoEvent(photoprismModel, event);

        if (status == 0) {
          await PhotoManager.loadMomentsTime(context, forceReload: true);
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

    await Api.getNewSession(photoprismModel);
    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + '/api/v1/upload/' + event,
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: 'manual',
        headers: photoprismModel.photoprismAuth.getAuthHeaders());

    return manualUploadFinishedCompleter.future;
  }

  static Future<void> getPhotosToUpload(PhotoprismModel model) async {
    if (!model.autoUploadEnabled) {
      return;
    }

    if (await photolib.PhotoManager.requestPermission()) {
      final List<photolib.AssetPathEntity> albums =
          await photolib.PhotoManager.getAssetPathList();
      final Set<String> photosToUpload = <String>{};
      for (final photolib.AssetPathEntity album in albums) {
        if (model.albumsToUpload.contains(album.id)) {
          List<photolib.AssetEntity> entries = await album.assetList;
          entries = filterForNonUploadedFiles(entries, model);
          photosToUpload.addAll(entries.map((photolib.AssetEntity e) => e.id));
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
        runAutoUploadBackgroundRoutine(model);
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

  Future<void> runAutoUploadBackgroundRoutine(PhotoprismModel model) async {
    model.addLogEntry('AutoUploader', 'Starting autoupload routine.');

    if (!photoprismModel.autoUploadEnabled) {
      model.addLogEntry(
          'AutoUploader', 'Auto upload disabled. Stopping autoupload routine.');
      return;
    }

    if (photoprismModel.photoprismUrl == 'https://demo.photoprism.org') {
      model.addLogEntry('AutoUploader',
          'Auto upload disabled for demo page. Stopping autoupload routine.');
      return;
    }

    // Set date and time when background routine was run last time.
    setAutoUploadLastTimeActive();

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
    final List<Album> deviceAlbumList =
        await Api.searchAlbums(photoprismModel, deviceName);
    if (deviceAlbumList == null) {
      return -1;
    }

    deviceAlbums = Map<String, Album>.fromEntries(deviceAlbumList
        .map((Album album) => MapEntry<String, Album>(album.name, album)));

    return 0;
  }

  Future<void> uploadPhotosFromAlbum(
      photolib.AssetPathEntity album, PhotoprismModel model) async {
    model.addLogEntry('AutoUploader', 'Creating album for mobile uploads.');

    String albumId;
    final String albumName = '$deviceName – ${album.name}';

    if (deviceAlbums.containsKey(albumName)) {
      albumId = deviceAlbums[albumName].id;
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
      albumId = await Api.createAlbum(albumName, photoprismModel);
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
      final Uint8List imageBytes = await assets[id].originBytes;
      final String filehash = sha1.convert(imageBytes).toString();

      model.addLogEntry('AutoUploader',
          "Next photo: '" + filename + "' and ID: '" + id + "'.");

      if (await isPhotoOnServerAndAddToAlbum(
          photoprismModel, id, filehash, albumId)) {
        model.addLogEntry(
            'AutoUploader',
            "Photo was already uploaded and added to album '" +
                albumName +
                "'. Skipping uploading and importing.");
        continue;
      }

      model.addLogEntry('AutoUploader', "Uploading photo '" + filename + "'.");
      final bool status =
          await Api.upload(photoprismModel, filehash, filename, imageBytes);
      if (status) {
        model.addLogEntry('AutoUploader', "Uploading photo successful'.");
      } else {
        model.addLogEntry(
            'AutoUploader', "Uploading photo failed'. Skipping to next photo.");
        continue;
      }

      // add uploaded photo to shared pref
      if (await Api.importPhotos(
          photoprismModel.photoprismUrl, photoprismModel, filehash)) {
        if (await isPhotoOnServerAndAddToAlbum(
            photoprismModel, id, filehash, albumId)) {
          model.addLogEntry(
              'AutoUploader', 'Photo was imported and added to album.');
          continue;
        }
      } else {
        model.addLogEntry(
            'AutoUploader', 'ERROR: Photo could not be imported.');
      }
      model.addLogEntry('AutoUploader', 'Adding photo to failed upload list.');
      saveAndSetPhotosUploadFailed(
          photoprismModel, photoprismModel.photosUploadFailed..add(id));
    }
  }

  static Future<bool> isPhotoOnServerAndAddToAlbum(
      PhotoprismModel model, String id, String filehash, String albumId) async {
    final String photoUUID = await Api.getUuidFromHash(model, filehash);
    if (photoUUID.isEmpty) {
      return false;
    }
    if (await Api.addPhotosToAlbum(albumId, <String>[photoUUID], model) != 0) {
      return false;
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

    for (final photolib.AssetPathEntity album in list) {
      if (album.id == id) {
        return Map<String, photolib.AssetEntity>.fromEntries(
            (await album.assetList).map((photolib.AssetEntity asset) =>
                MapEntry<String, photolib.AssetEntity>(asset.id, asset)));
      }
    }
    return <String, photolib.AssetEntity>{};
  }

  // Returns the device name of the current device (smartphone).
  static Future<String> getNameOfCurrentDevice(PhotoprismModel model) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
    model.addLogEntry(
        'AutoUploader', 'ERROR: Failed to get name of this device.');
    return '';
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;

class PhotoprismUploader {
  PhotoprismUploader(this.photoprismModel) {
    loadPreferences();
    initPlatformState();
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

  Future<void> setAutoUpload(bool autoUploadEnabledNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadEnabled', autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notify();
    getPhotosToUpload(photoprismModel);
  }

  Future<void> setAutoUploadLastTimeActive() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // get time
    final DateTime now = DateTime.now();
    final String currentTime = DateFormat('dd.MM.yyyy – kk:mm').format(now);
    print(currentTime.toString());
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

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + '/api/v1/upload/' + event,
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: 'manual',
        headers: photoprismModel.photoprismHttpBasicAuth.getAuthHeader());

    return manualUploadFinishedCompleter.future;
  }

  static Future<void> getPhotosToUpload(PhotoprismModel model) async {
    if (!model.autoUploadEnabled) {
      return;
    }

    if (await photolib.PhotoManager.requestPermission()) {
      final List<photolib.AssetPathEntity> albums =
          await photolib.PhotoManager.getAssetPathList(
              type: photolib.RequestType.image);
      final Set<String> photosToUpload = <String>{};
      for (final photolib.AssetPathEntity album in albums) {
        if (model.albumsToUpload.contains(album.name)) {
          List<photolib.AssetEntity> entries = await album.assetList;
          entries = filterForNonUploadedFiles(entries, model);
          photosToUpload.addAll(entries.map((photolib.AssetEntity e) => e.id));
        }
      }
      model.photosToUpload = photosToUpload;
    }
  }

  Future<void> initPlatformState() async {
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
        backgroundUpload(taskId);
      } finally {
        BackgroundFetch.finish(taskId);
      }
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((Object e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  Future<void> backgroundUpload(String taskId) async {
    print('[BackgroundFetch] Event received');

    if (!photoprismModel.autoUploadEnabled) {
      print('Auto upload disabled.');
      BackgroundFetch.finish(taskId);
      return;
    }

    if (photoprismModel.photoprismUrl == 'https://demo.photoprism.org') {
      print('Auto upload disabled for demo page!');
      BackgroundFetch.finish(taskId);
      return;
    }

    setAutoUploadLastTimeActive();
    final Map<String, photolib.AssetEntity> assets =
        await getAllPhotoAssetsAsMap();
    for (final String id in photoprismModel.photosToUpload) {
      if (!photoprismModel.autoUploadEnabled) {
        print('automatic photo upload was disabled, breaking');
        break;
      }

      print('########## Upload new photo ##########');
      String filename = (await assets[id].file).uri.pathSegments.last;

      Uint8List imageBytes = await assets[id].originBytes;

      if (filename.toLowerCase().split('.').last == 'heic') {
        imageBytes =
            Uint8List.fromList(await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: assets[id].height,
          minWidth: assets[id].width,
          quality: 90,
          format: CompressFormat.jpeg,
          keepExif: true,
        ));
        filename = filename.substring(0, filename.length - 4) + 'jpg';
      }

      final String filehash = sha1.convert(imageBytes).toString();

      if (await Api.isPhotoOnServer(photoprismModel, filehash)) {
        saveAndSetAlreadyUploadedPhotos(
            photoprismModel, photoprismModel.alreadyUploadedPhotos..add(id));
        continue;
      }

      print('Uploading $filename');
      await Api.upload(photoprismModel, filehash, filename, imageBytes);

      final int status = await Api.importPhotos(
          photoprismModel.photoprismUrl, photoprismModel, filehash);

      // add uploaded photo to shared pref
      if (status == 0) {
        saveAndSetAlreadyUploadedPhotos(
            photoprismModel, photoprismModel.alreadyUploadedPhotos..add(id));
        print('############################################');
        continue;
      }
      saveAndSetPhotosUploadFailed(
          photoprismModel, photoprismModel.photosUploadFailed..add(id));
    }
    print('All new photos uploaded.');
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

  static Future<Map<String, photolib.AssetEntity>>
      getAllPhotoAssetsAsMap() async {
    final List<photolib.AssetPathEntity> list =
        await photolib.PhotoManager.getAssetPathList(
            type: photolib.RequestType.image);
    final Map<String, photolib.AssetEntity> assets =
        <String, photolib.AssetEntity>{};
    for (final photolib.AssetPathEntity album in list) {
      assets.addEntries((await album.assetList).map(
          (photolib.AssetEntity asset) =>
              MapEntry<String, photolib.AssetEntity>(asset.id, asset)));
    }
    return assets;
  }
}

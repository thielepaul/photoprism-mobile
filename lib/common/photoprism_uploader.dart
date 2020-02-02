import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';

import '../api/api.dart';
import '../model/photoprism_model.dart';

class PhotoprismUploader {
  PhotoprismUploader(this.photoprismModel) {
    loadPreferences();
    initPlatformState();
    getPhotosToUpload();

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
  List<FileSystemEntity> entries;

  Future<void> setAutoUpload(bool autoUploadEnabledNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoUploadEnabled', autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notify();
  }

  Future<void> setautoUploadLastTimeActive() async {
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
    photoprismModel.autoUploadFolder =
        prefs.getString('uploadFolder') ?? '/storage/emulated/0/DCIM/Camera';
    photoprismModel.autoUploadLastTimeCheckedForPhotos =
        prefs.getString('autoUploadLastTimeActive') ?? 'Never';
    photoprismModel.notify();
  }

  Future<void> setUploadFolder(String autoUploadFolderNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('uploadFolder', autoUploadFolderNew);
    photoprismModel.autoUploadFolder = autoUploadFolderNew;
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

  Future<void> getPhotosToUpload() async {
    if (FileSystemEntity.typeSync(photoprismModel.autoUploadFolder) !=
        FileSystemEntityType.notFound) {
      final Directory dir = Directory(photoprismModel.autoUploadFolder);
      entries = dir.listSync(recursive: false).toList();

      // remove all but jpg files
      final List<FileSystemEntity> newEntries = <FileSystemEntity>[];
      for (final FileSystemEntity entry in entries) {
        if (entry.path.length > 3 &&
            (entry.path.substring(entry.path.length - 4) == '.jpg' ||
                entry.path.substring(entry.path.length - 4) == '.JPG')) {
          newEntries.add(entry);
          print('Adding ' + entry.path);
        }
      }
      entries = newEntries;

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> alreadyUploadedPhotos =
          prefs.getStringList('alreadyUploadedPhotos') ?? <String>[];

      final List<String> entriesToUpload = <String>[];
      for (final FileSystemEntity entry in entries) {
        if (!alreadyUploadedPhotos.contains(entry.path)) {
          entriesToUpload.add(entry.path);
        }
      }
      photoprismModel.photosToUpload = entriesToUpload;
      photoprismModel.notify();
    } else {
      photoprismModel.photosToUpload = <String>[];
      photoprismModel.notify();
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
            requiredNetworkType: BackgroundFetchConfig.NETWORK_TYPE_NONE),
        () async {
      print('[BackgroundFetch] Event received');

      if (photoprismModel.autoUploadEnabled) {
        if (photoprismModel.photoprismUrl != 'https://demo.photoprism.org') {
          setautoUploadLastTimeActive();
          final Directory dir = Directory(photoprismModel.autoUploadFolder);
          entries = dir.listSync(recursive: false).toList();

          // remove all but jpg files
          final List<FileSystemEntity> newEntries = <FileSystemEntity>[];
          for (final FileSystemEntity entry in entries) {
            if (entry.path.length > 3 &&
                (entry.path.substring(entry.path.length - 4) == '.jpg' ||
                    entry.path.substring(entry.path.length - 4) == '.JPG')) {
              newEntries.add(entry);
              print('Adding ' + entry.path);
            }
          }
          entries = newEntries;

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final List<String> alreadyUploadedPhotos =
              prefs.getStringList('alreadyUploadedPhotos') ?? <String>[];

          for (final FileSystemEntity entry in entries) {
            if (!alreadyUploadedPhotos.contains(entry.path)) {
              final List<FileSystemEntity> entriesToUpload =
                  <FileSystemEntity>[];
              entriesToUpload.add(entry);
              print('########## Upload new photo ##########');
              print('Uploading ' + entry.path);
              await uploadPhotoAuto(entriesToUpload);

              final int status = await Api.importPhotos(
                  photoprismModel.photoprismUrl,
                  photoprismModel,
                  sha1.convert(await _readFileByte(entry.path)).toString());

              // add uploaded photo to shared pref
              if (status == 0) {
                final SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                final List<String> alreadyUploadedPhotos =
                    prefs.getStringList('alreadyUploadedPhotos') ?? <String>[];

                if (!alreadyUploadedPhotos.contains(entry.path)) {
                  alreadyUploadedPhotos.add(entry.path);
                }
                prefs.setStringList(
                    'alreadyUploadedPhotos', alreadyUploadedPhotos);

                getPhotosToUpload();
                print('############################################');
              }
            }
          }
          print('All new photos uploaded.');
        } else {
          print('Auto upload disabled for demo page!');
        }
      } else {
        print('Auto upload disabled.');
      }
      BackgroundFetch.finish();
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((Object e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    final Uri myUri = Uri.parse(filePath);
    final File imageFile = File.fromUri(myUri);
    Uint8List bytes;
    await imageFile.readAsBytes().then((Uint8List value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    }).catchError((Error onError) {
      print('Exception Error while reading image from path:' +
          onError.toString());
    });
    return bytes;
  }

  Future<int> uploadPhotoAuto(List<FileSystemEntity> files) async {
    final List<FileItem> filesToUpload = <FileItem>[];

    filesToUpload.addAll(files.map<FileItem>((FileSystemEntity file) =>
        FileItem(
            filename: basename(file.path),
            savedDir: dirname(file.path),
            fieldname: 'files')));

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + '/api/v1/upload/mobile',
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: 'upload 1',
        headers: photoprismModel.photoprismHttpBasicAuth.getAuthHeader());
    print('Waiting uploadPhoto()');
    uploadFinishedCompleter = Completer<int>();
    return uploadFinishedCompleter.future;
  }
}

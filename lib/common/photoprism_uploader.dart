import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';

import '../api/api.dart';
import '../api/photos.dart';
import '../model/photoprism_model.dart';

class PhotoprismUploader {
  PhotoprismModel photoprismModel;
  Completer uploadFinishedCompleter;
  FlutterUploader uploader;
  List<FileSystemEntity> entries;

  PhotoprismUploader(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
    loadPreferences();
    initPlatformState();

    uploader = FlutterUploader();
    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });

    uploader.progress.listen((progress) {
      //print("Progress: " + progress.progress.toString());
    });

    uploader.result.listen((result) async {
      print("Upload finished.");
      print(result.statusCode == 200);
      if (result.statusCode == 200) {
        if (result.tag == "manual") {
          print("Manual upload success!");
          importPhotos();
        } else {
          print("Auto upload success!");
          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> alreadyUploadedPhotos =
              prefs.getStringList("alreadyUploadedPhotos") ?? List<String>();

          // add uploaded photos to shared pref
          if (entries.length > 0) {
            entries.forEach((e) {
              if (!alreadyUploadedPhotos.contains(e.path)) {
                alreadyUploadedPhotos.add(e.path);
              }
            });
          }

          prefs.setStringList("alreadyUploadedPhotos", alreadyUploadedPhotos);
          uploadFinishedCompleter.complete();
        }
      } else {
        print("Upload error!");
      }
    }, onError: (ex, stacktrace) {
      print("Error upload!");
      uploadFinishedCompleter.complete();
    });
  }

  void setAutoUpload(bool autoUploadEnabledNew) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("autoUploadEnabled", autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notifyListeners();
  }

  void setautoUploadLastTimeActive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // get time
    DateTime now = DateTime.now();
    String currentTime = DateFormat('dd.MM.yyyy – kk:mm').format(now);
    print(currentTime.toString());
    prefs.setString("autoUploadLastTimeActive", currentTime.toString());
    photoprismModel.autoUploadLastTimeActive = currentTime.toString();
    photoprismModel.notifyListeners();
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    photoprismModel.autoUploadEnabled =
        prefs.getBool("autoUploadEnabled") ?? false;
    photoprismModel.autoUploadFolder =
        prefs.getString("uploadFolder") ?? "/storage/emulated/0/DCIM/Camera";
    photoprismModel.autoUploadLastTimeActive =
        prefs.getString("autoUploadLastTimeActive") ?? "Never";
    photoprismModel.notifyListeners();
  }

  Future<void> setUploadFolder(autoUploadFolderNew) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("uploadFolder", autoUploadFolderNew);
    photoprismModel.autoUploadFolder = autoUploadFolderNew;
    photoprismModel.notifyListeners();
  }

  startManualPhotoUpload() async {
    List<File> files = await FilePicker.getMultiFile();
    List<FileItem> filesToUpload = [];

    if (files.length > 0) {
      files.forEach((f) {
        filesToUpload.add(FileItem(
            filename: basename(f.path),
            savedDir: dirname(f.path),
            fieldname: "files"));
      });

      if (files.length > 1) {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen("Uploading photos..");
      } else {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen("Uploading photo..");
      }

      await uploader.enqueue(
          url: photoprismModel.photoprismUrl + "/api/v1/upload/test",
          files: filesToUpload,
          method: UploadMethod.POST,
          showNotification: false,
          tag: "manual");
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
        if (photoprismModel.photoprismUrl != "https://demo.photoprism.org") {
          setautoUploadLastTimeActive();
          Directory dir = Directory(photoprismModel.autoUploadFolder);
          entries = dir.listSync(recursive: false).toList();

          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> alreadyUploadedPhotos =
              prefs.getStringList("alreadyUploadedPhotos") ?? List<String>();

          for (var entry in entries) {
            if (!alreadyUploadedPhotos.contains(entry.path)) {
              List<FileSystemEntity> entriesToUpload = [];
              entriesToUpload.add(entry);
              print("Uploading " + entry.path);
              await uploadPhoto(entriesToUpload);
            }
          }
          Api.importPhotos(photoprismModel.photoprismUrl);
          print("All new photos uploaded.");
        } else {
          print("Auto upload disabled for demo page!");
        }
      } else {
        print("Auto upload disabled.");
      }
      BackgroundFetch.finish();
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  void importPhotos() async {
    print("Importing photos");
    photoprismModel.photoprismLoadingScreen
        .updateLoadingScreen("Importing photos..");
    var status = await Api.importPhotos(photoprismModel.photoprismUrl);

    if (status == 0) {
      await Photos.loadPhotos(
          photoprismModel, photoprismModel.photoprismUrl, "");
    } else {
      // error
    }
    photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
  }

  Future uploadPhoto(List<FileSystemEntity> files) async {
    List<FileItem> filesToUpload = [];

    files.forEach((f) {
      filesToUpload.add(FileItem(
          filename: basename(f.path),
          savedDir: dirname(f.path),
          fieldname: "files"));
    });

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + "/api/v1/upload/test",
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: "upload 1");
    print("Waiting uploadPhoto()");
    uploadFinishedCompleter = Completer();
    return uploadFinishedCompleter.future;
  }
}

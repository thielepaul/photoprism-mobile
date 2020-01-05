import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';

import '../api/api.dart';
import '../api/photos.dart';
import '../model/photoprism_model.dart';

class PhotoprismUploader {
  bool autoUploadEnabled = false;
  String autoUploadFolder = "/storage/emulated/0/DCIM/Camera";
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
    autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notifyListeners();
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoUploadEnabled = prefs.getBool("autoUploadEnabled") ?? false;
    autoUploadFolder =
        prefs.getString("uploadFolder") ?? "/storage/emulated/0/DCIM/Camera";
    photoprismModel.notifyListeners();
  }

  Future<void> setUploadFolder(autoUploadFolderNew) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("uploadFolder", autoUploadFolderNew);
    autoUploadFolder = autoUploadFolderNew;
    photoprismModel.notifyListeners();
  }

  uploadImage() async {
    List<File> files = await FilePicker.getMultiFile();
    List<FileItem> filesToUpload = [];

    files.forEach((f) {
      filesToUpload.add(FileItem(
          filename: basename(f.path),
          savedDir: dirname(f.path),
          fieldname: "files"));
    });

    photoprismModel.showLoadingScreen("Uploading photo(s)..");

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + "/api/v1/upload/test",
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: "manual");
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

      if (autoUploadEnabled) {
        if (photoprismModel.photoprismUrl != "https://demo.photoprism.org") {
          Directory dir = Directory(autoUploadFolder);
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
    photoprismModel.updateLoadingScreen("Importing photos..");
    var status = await Api.importPhotos(photoprismModel.photoprismUrl);

    if (status == 0) {
      await Photos.loadPhotos(
          photoprismModel, photoprismModel.photoprismUrl, "");
    } else {
      // error
    }
    photoprismModel.hideLoadingScreen();
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

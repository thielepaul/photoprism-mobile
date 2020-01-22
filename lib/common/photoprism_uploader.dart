import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';
import 'package:background_fetch/background_fetch.dart';

import '../api/api.dart';
import '../pages/photos_page.dart';
import '../model/photoprism_model.dart';

class PhotoprismUploader {
  PhotoprismModel photoprismModel;
  Completer uploadFinishedCompleter;
  Completer manualUploadFinishedCompleter;
  FlutterUploader uploader;
  List<FileSystemEntity> entries;

  PhotoprismUploader(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
    loadPreferences();
    initPlatformState();
    getPhotosToUpload();

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
      if (result.statusCode == 200) {
        if (result.tag == "manual") {
          manualUploadFinishedCompleter.complete(0);
        } else {
          print("Auto upload success!");
          uploadFinishedCompleter.complete(0);
        }
      } else {
        if (result.tag == "manual") {
          manualUploadFinishedCompleter.complete(2);
        } else {
          uploadFinishedCompleter.complete(2);
        }
      }
    }, onError: (ex, stacktrace) {
      final exp = ex as UploadException;

      if (exp.tag == "manual") {
        manualUploadFinishedCompleter.complete(1);
      } else {
        uploadFinishedCompleter.complete(1);
      }
    });
  }

  void setAutoUpload(bool autoUploadEnabledNew) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("autoUploadEnabled", autoUploadEnabledNew);
    photoprismModel.autoUploadEnabled = autoUploadEnabledNew;
    photoprismModel.notify();
  }

  void setautoUploadLastTimeActive() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // get time
    DateTime now = DateTime.now();
    String currentTime = DateFormat('dd.MM.yyyy – kk:mm').format(now);
    print(currentTime.toString());
    prefs.setString("autoUploadLastTimeActive", currentTime.toString());
    photoprismModel.autoUploadLastTimeCheckedForPhotos = currentTime.toString();
    photoprismModel.notify();
  }

  void loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    photoprismModel.autoUploadEnabled =
        prefs.getBool("autoUploadEnabled") ?? false;
    photoprismModel.autoUploadFolder =
        prefs.getString("uploadFolder") ?? "/storage/emulated/0/DCIM/Camera";
    photoprismModel.autoUploadLastTimeCheckedForPhotos =
        prefs.getString("autoUploadLastTimeActive") ?? "Never";
    photoprismModel.notify();
  }

  Future<void> setUploadFolder(autoUploadFolderNew) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("uploadFolder", autoUploadFolderNew);
    photoprismModel.autoUploadFolder = autoUploadFolderNew;
    photoprismModel.notify();
  }

  /// Starts image file picker, uploads photo(s) and imports them.
  void selectPhotoAndUpload() async {
    List<File> files = await FilePicker.getMultiFile();

    // list for flutter uploader
    List<FileItem> filesToUpload = [];

    // check if at least one file was selected
    if (files != null) {
      files.forEach((file) {
        filesToUpload.add(FileItem(
            filename: basename(file.path),
            savedDir: dirname(file.path),
            fieldname: "files"));
      });

      if (files.length > 1) {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen("Uploading photos..");
      } else {
        photoprismModel.photoprismLoadingScreen
            .showLoadingScreen("Uploading photo..");
      }

      var rng = new Random.secure();
      String event = "";
      for (var i = 0; i < 12; i++) {
        event += rng.nextInt(9).toString();
      }

      print("Uploading event " + event);

      int status = await uploadPhoto(filesToUpload, event);

      if (status == 0) {
        print("Manual upload successful.");
        print("Importing photos..");
        photoprismModel.photoprismLoadingScreen
            .updateLoadingScreen("Importing photos..");
        var status = await Api.importPhotoEvent(photoprismModel, event);

        if (status == 0) {
          await PhotosPage.loadPhotos(
              photoprismModel, photoprismModel.photoprismUrl, "");
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage
              .showMessage("Uploading and importing successful.");
        } else if (status == 3) {
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage
              .showMessage("Photo already imported or import failed.");
        } else {
          await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
          photoprismModel.photoprismMessage.showMessage("Importing failed.");
        }
      } else {
        print("Manual upload failed.");
        await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
        photoprismModel.photoprismMessage.showMessage("Manual upload failed.");
      }
    }
  }

  Future uploadPhoto(List<FileItem> filesToUpload, String event) async {
    manualUploadFinishedCompleter = Completer();

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + "/api/v1/upload/" + event,
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: "manual",
        headers: photoprismModel.photoprismHttpBasicAuth.getAuthHeader());

    return manualUploadFinishedCompleter.future;
  }

  void getPhotosToUpload() async {
    if (FileSystemEntity.typeSync(photoprismModel.autoUploadFolder) !=
        FileSystemEntityType.notFound) {
      Directory dir = Directory(photoprismModel.autoUploadFolder);
      entries = dir.listSync(recursive: false).toList();

      // remove all but jpg files
      List<FileSystemEntity> newEntries = [];
      for (var entry in entries) {
        if (entry.path.length > 3 &&
            (entry.path.substring(entry.path.length - 4) == ".jpg" ||
                entry.path.substring(entry.path.length - 4) == ".JPG")) {
          newEntries.add(entry);
          print("Adding " + entry.path);
        }
      }
      entries = newEntries;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> alreadyUploadedPhotos =
          prefs.getStringList("alreadyUploadedPhotos") ?? List<String>();

      List<String> entriesToUpload = [];
      for (var entry in entries) {
        if (!alreadyUploadedPhotos.contains(entry.path)) {
          entriesToUpload.add(entry.path);
        }
      }
      photoprismModel.photosToUpload = entriesToUpload;
      photoprismModel.notify();
    } else {
      photoprismModel.photosToUpload = [];
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
        if (photoprismModel.photoprismUrl != "https://demo.photoprism.org") {
          setautoUploadLastTimeActive();
          Directory dir = Directory(photoprismModel.autoUploadFolder);
          entries = dir.listSync(recursive: false).toList();

          // remove all but jpg files
          List<FileSystemEntity> newEntries = [];
          for (var entry in entries) {
            if (entry.path.length > 3 &&
                (entry.path.substring(entry.path.length - 4) == ".jpg" ||
                    entry.path.substring(entry.path.length - 4) == ".JPG")) {
              newEntries.add(entry);
              print("Adding " + entry.path);
            }
          }
          entries = newEntries;

          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> alreadyUploadedPhotos =
              prefs.getStringList("alreadyUploadedPhotos") ?? List<String>();

          for (var entry in entries) {
            if (!alreadyUploadedPhotos.contains(entry.path)) {
              List<FileSystemEntity> entriesToUpload = [];
              entriesToUpload.add(entry);
              print("########## Upload new photo ##########");
              print("Uploading " + entry.path);
              await uploadPhotoAuto(entriesToUpload);

              int status = await Api.importPhotos(
                  photoprismModel.photoprismUrl,
                  photoprismModel,
                  sha1.convert(await _readFileByte(entry.path)).toString());

              // add uploaded photo to shared pref
              if (status == 0) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> alreadyUploadedPhotos =
                    prefs.getStringList("alreadyUploadedPhotos") ??
                        List<String>();

                if (!alreadyUploadedPhotos.contains(entry.path)) {
                  alreadyUploadedPhotos.add(entry.path);
                }
                prefs.setStringList(
                    "alreadyUploadedPhotos", alreadyUploadedPhotos);

                getPhotosToUpload();
                print("############################################");
              }
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

  Future<Uint8List> _readFileByte(String filePath) async {
    Uri myUri = Uri.parse(filePath);
    File imageFile = new File.fromUri(myUri);
    Uint8List bytes;
    await imageFile.readAsBytes().then((value) {
      bytes = Uint8List.fromList(value);
      print('reading of bytes is completed');
    }).catchError((onError) {
      print('Exception Error while reading image from path:' +
          onError.toString());
    });
    return bytes;
  }

  Future uploadPhotoAuto(List<FileSystemEntity> files) async {
    List<FileItem> filesToUpload = [];

    files.forEach((f) {
      filesToUpload.add(FileItem(
          filename: basename(f.path),
          savedDir: dirname(f.path),
          fieldname: "files"));
    });

    await uploader.enqueue(
        url: photoprismModel.photoprismUrl + "/api/v1/upload/mobile",
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: "upload 1",
        headers: photoprismModel.photoprismHttpBasicAuth.getAuthHeader());
    print("Waiting uploadPhoto()");
    uploadFinishedCompleter = Completer();
    return uploadFinishedCompleter.future;
  }
}

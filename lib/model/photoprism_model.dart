import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:path/path.dart';

class PhotoprismModel extends ChangeNotifier {
  String applicationColor = "#424242";
  String photoprismUrl = "https://demo.photoprism.org";
  List<Photo> photoList;
  Map<String, Album> albums;
  bool isLoading = false;
  int selectedPageIndex = 0;
  DragSelectGridViewController gridController = DragSelectGridViewController();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;
  BuildContext context;
  ProgressDialog pr;
  FlutterUploader uploader;
  List<FileSystemEntity> entries;
  String autoUploadFolder = "/storage/emulated/0/DCIM/Camera";
  Completer c;
  PhotoprismUploader photoprismUploader;

  PhotoprismModel() {
    initialize();
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

      if (photoprismUploader.autoUploadEnabled) {
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
        print("Auto upload disabled.");
      }
      BackgroundFetch.finish();
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });
  }

  void getUploadFolder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoUploadFolder =
        prefs.getString("uploadFolder") ?? "/storage/emulated/0/DCIM/Camera";
    notifyListeners();
  }

  Future<void> setUploadFolder(folder) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("uploadFolder", folder);
    autoUploadFolder = folder;
    notifyListeners();
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
        url: photoprismUrl + "/api/v1/upload/test",
        files: filesToUpload,
        method: UploadMethod.POST,
        showNotification: false,
        tag: "upload 1");
    print("Waiting uploadPhoto()");
    c = Completer();
    return c.future;
  }

  DragSelectGridViewController getGridController() {
    try {
      gridController.hasListeners;
    } catch (_) {
      gridController = DragSelectGridViewController();
      gridController.addListener(notifyListeners);
    }
    return gridController;
  }

  showLoadingScreen(String message) {
    pr = new ProgressDialog(context);
    pr.style(message: message);
    pr.show();
    notifyListeners();
  }

  updateLoadingScreen(String message) {
    pr.update(message: message);
  }

  hideLoadingScreen() {
    Future.delayed(Duration(milliseconds: 500)).then((value) {
      pr.hide().whenComplete(() {});
    });
    notifyListeners();
  }

  initialize() async {
    await loadPhotoprismUrl();
    await getUploadFolder();
    loadApplicationColor();
    Photos.loadPhotosFromNetworkOrCache(this, photoprismUrl, "");
    Albums.loadAlbumsFromNetworkOrCache(this, photoprismUrl);
    photoprismUploader = new PhotoprismUploader(this);
    initPlatformState();
    gridController.addListener(notifyListeners);
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
          c.complete();
        }
      } else {
        print("Upload error!");
      }
    }, onError: (ex, stacktrace) {
      print("Error upload!");
      c.complete();
    });
  }

  void setSelectedPageIndex(int index) {
    selectedPageIndex = index;
    notifyListeners();
  }

  void setAlbumList(List<Album> albumList) {
    this.albums =
        Map.fromIterable(albumList, key: (e) => e.id, value: (e) => e);
    saveAlbumListToSharedPrefs();
    notifyListeners();
  }

  void setPhotoList(List<Photo> photoList) {
    this.photoList = photoList;
    savePhotoListToSharedPrefs('photosList', photoList);
    notifyListeners();
  }

  void setPhotoListOfAlbum(List<Photo> photoList, String albumId) {
    print("setPhotoListOfAlbum: albumId: " + albumId);
    albums[albumId].photoList = photoList;
    savePhotoListToSharedPrefs('photosList' + albumId, photoList);
    notifyListeners();
  }

  Future saveAlbumListToSharedPrefs() async {
    print("saveAlbumListToSharedPrefs");
    var key = 'albumList';
    List<Album> albumList = albums.entries.map((e) => e.value).toList();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(albumList));
  }

  Future savePhotoListToSharedPrefs(key, photoList) async {
    print("savePhotoListToSharedPrefs: key: " + key);
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(photoList));
  }

  Future<void> setPhotoprismUrl(url) async {
    await savePhotoprismUrlToPrefs(url);
    this.photoprismUrl = url;
    notifyListeners();
  }

  void createAlbum() async {
    print("Creating new album");
    showLoadingScreen("Creating new album..");
    var status = await Api.createAlbum('New album', photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(this, photoprismUrl);
    } else {
      // error
    }
    hideLoadingScreen();
  }

  void renameAlbum(
      String albumId, String oldAlbumName, String newAlbumName) async {
    if (oldAlbumName != newAlbumName) {
      print("Renaming album " + oldAlbumName + " to " + newAlbumName);
      showLoadingScreen("Renaming album..");
      var status = await Api.renameAlbum(albumId, newAlbumName, photoprismUrl);

      if (status == 0) {
        Albums.loadAlbums(this, photoprismUrl);
        Photos.loadPhotos(this, photoprismUrl, albumId);
      } else {
        // error
      }
      hideLoadingScreen();
    } else {
      print("Renaming skipped: New and old album name identical.");
    }
  }

  void deleteAlbum(String albumId) async {
    print("Deleting album " + albumId);
    showLoadingScreen("Deleting album..");
    var status = await Api.deleteAlbum(albumId, photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(this, photoprismUrl);
    } else {
      // error
    }
    hideLoadingScreen();
  }

  void addPhotosToAlbum(albumId, List<String> photoUUIDs) async {
    print("Adding photos to album " + albumId);
    showLoadingScreen("Adding photos to album..");
    var status = await Api.addPhotosToAlbum(albumId, photoUUIDs, photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(this, photoprismUrl);
    } else {
      // error
    }
    hideLoadingScreen();
  }

  void importPhotos() async {
    print("Importing photos");
    updateLoadingScreen("Importing photos..");
    var status = await Api.importPhotos(photoprismUrl);

    if (status == 0) {
      await Photos.loadPhotos(this, photoprismUrl, "");
    } else {
      // error
    }
    hideLoadingScreen();
  }

  loadPhotoprismUrl() async {
    // load photoprism url from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String photoprismUrl = prefs.getString("url");
    if (photoprismUrl != null) {
      this.photoprismUrl = photoprismUrl;
    }
  }

  void loadApplicationColor() async {
    // try to load application color from shared preference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationColor = prefs.getString("applicationColor");
    if (applicationColor != null) {
      print("loading color scheme from cache");
      this.applicationColor = applicationColor;
      notifyListeners();
    }

    // load color scheme from server
    try {
      http.Response response =
          await http.get(this.photoprismUrl + '/api/v1/settings');

      final settingsJson = json.decode(response.body);
      final themeSetting = settingsJson["theme"];

      final themesJson = await rootBundle.loadString('assets/themes.json');
      final parsedThemes = json.decode(themesJson);

      final currentTheme = parsedThemes[themeSetting];

      this.applicationColor = currentTheme["navigation"];

      // save new color scheme to shared preferences
      prefs.setString("applicationColor", this.applicationColor);
      notifyListeners();
    } catch (_) {
      print("Could not get color scheme from server!");
    }
  }

  Future savePhotoprismUrlToPrefs(url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("url", url);
  }

  void setPhotoViewScaleState(PhotoViewScaleState scaleState) {
    photoViewScaleState = scaleState;
    notifyListeners();
  }
}

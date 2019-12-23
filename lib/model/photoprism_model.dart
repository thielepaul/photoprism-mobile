import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:progress_dialog/progress_dialog.dart';

class PhotoprismModel extends ChangeNotifier {
  String applicationColor = "#424242";
  String photoprismUrl = "https://demo.photoprism.org";
  List<Photo> photoList;
  Map<String, Album> albums;
  bool isLoading = false;
  int selectedPageIndex = 0;
  DragSelectGridViewController gridController = DragSelectGridViewController();
  bool showAppBar = true;
  Key globalKeyPhotoView = GlobalKey();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;
  bool photoViewMultiTouch = false;
  BuildContext context;
  ProgressDialog pr;

  PhotoprismModel() {
    initialize();
    gridController.addListener(notifyListeners);
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

  hideLoadingScreen() {
    Future.delayed(Duration(milliseconds: 500)).then((value) {
      pr.hide().whenComplete(() {
      });
    });
    notifyListeners();
  }

  initialize() async {
    await loadPhotoprismUrl();
    loadApplicationColor();
    Photos.loadPhotosFromNetworkOrCache(this, photoprismUrl, "");
    Albums.loadAlbumsFromNetworkOrCache(this, photoprismUrl);
  }

  void setShowAppBar(bool showAppBar) {
    this.showAppBar = showAppBar;
    notifyListeners();
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

  void setPhotoViewMultiTouch(bool multiTouch) {
    photoViewMultiTouch = multiTouch;
    notifyListeners();
  }
}

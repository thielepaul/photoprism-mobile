import 'dart:async';
import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/common/photoprism_album_manager.dart';
import 'package:photoprism/common/photoprism_config.dart';
import 'package:photoprism/common/photoprism_loading_screen.dart';
import 'package:photoprism/common/photoprism_photo_manager.dart';
import 'package:photoprism/common/photoprism_settings_manager.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismModel extends ChangeNotifier {
  String photoprismUrl = "https://demo.photoprism.org";
  List<Photo> photoList;
  Map<String, Album> albums;
  bool isLoading = false;
  int selectedPageIndex = 0;
  DragSelectGridViewController gridController = DragSelectGridViewController();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;

  PhotoprismUploader photoprismUploader;
  PhotoprismConfig photoprismConfig;
  PhotoprismSettingsManager photoprismSettingsManager;
  PhotoprismPhotoManager photoprismPhotoManager;
  PhotoprismAlbumManager photoprismAlbumManager;
  PhotoprismLoadingScreen photoprismLoadingScreen;

  PhotoprismModel() {
    initialize();
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

  initialize() async {
    photoprismUploader = new PhotoprismUploader(this);
    photoprismConfig = new PhotoprismConfig(this);
    photoprismSettingsManager = new PhotoprismSettingsManager(this);
    photoprismPhotoManager = new PhotoprismPhotoManager(this);
    photoprismAlbumManager = new PhotoprismAlbumManager(this);
    photoprismLoadingScreen = new PhotoprismLoadingScreen(this);

    await photoprismSettingsManager.loadPhotoprismUrl();
    photoprismConfig.loadApplicationColor();
    Photos.loadPhotosFromNetworkOrCache(this, photoprismUrl, "");
    Albums.loadAlbumsFromNetworkOrCache(this, photoprismUrl);
    gridController.addListener(notifyListeners);
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
    await photoprismSettingsManager.savePhotoprismUrlToPrefs(url);
    this.photoprismUrl = url;
    notifyListeners();
  }

  void setPhotoViewScaleState(PhotoViewScaleState scaleState) {
    photoViewScaleState = scaleState;
    notifyListeners();
  }
}

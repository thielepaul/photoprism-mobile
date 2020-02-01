// import 'dart:convert';

import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismCommonHelper {
  PhotoprismModel photoprismModel;
  PhotoprismCommonHelper(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  static Future<void> saveAsJsonToSharedPrefs(String key, data) async {
    print("saveToSharedPrefs: key: " + key);
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(data));
  }

  static Future<void> getCachedDataFromSharedPrefs(BuildContext context) async {
    print("getDataFromSharedPrefs");
    SharedPreferences sp = await SharedPreferences.getInstance();

    if (sp.containsKey("photos")) {
      final Map<int, Photo> photos = json
          .decode(sp.getString("photos"))
          .map<int, Photo>(
              (key, value) => MapEntry(int.parse(key), Photo.fromJson(value)));
      PhotoManager.saveAndSetPhotos(context, photos, null);
    }

    if (sp.containsKey("momentsTime")) {
      final List<MomentsTime> momentsTime = json
          .decode(sp.getString("momentsTime"))
          .map<MomentsTime>((value) => MomentsTime.fromJson(value))
          .toList();
      PhotoManager.saveAndSetMomentsTime(context, momentsTime);
    }

    if (sp.containsKey("albums")) {
      final Map<int, Album> albums = json
          .decode(sp.getString("albums"))
          .map<int, Album>(
              (key, value) => MapEntry(int.parse(key), Album.fromJson(value)));
      for (int albumId in albums.keys) {
        if (sp.containsKey("photos" + albumId.toString())) {}
        albums[albumId].photos = json
            .decode(sp.getString("photos" + albumId.toString()))
            .map<int, Photo>((key, value) =>
                MapEntry(int.parse(key), Photo.fromJson(value)));
      }
      AlbumManager.saveAndSetAlbums(context, albums);
    }
  }

  loadPhotoprismUrl() async {
    // load photoprism url from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String photoprismUrl = prefs.getString("url");
    if (photoprismUrl != null) {
      photoprismModel.photoprismUrl = photoprismUrl;
    }
  }

  Future savePhotoprismUrlToPrefs(url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("url", url);
  }

  void setSelectedPageIndex(int index) {
    photoprismModel.selectedPageIndex = index;
    photoprismModel.notify();
  }

  Future<void> setPhotoprismUrl(url) async {
    await savePhotoprismUrlToPrefs(url);
    photoprismModel.photoprismUrl = url;
    photoprismModel.notify();
  }

  void setPhotoViewScaleState(PhotoViewScaleState scaleState) {
    photoprismModel.photoViewScaleState = scaleState;
    photoprismModel.notify();
  }

  DragSelectGridViewController getGridController() {
    try {
      photoprismModel.gridController.addListener(photoprismModel.notify);
    } catch (_) {
      print("gridcontroller has no listeners");
      photoprismModel.gridController = DragSelectGridViewController();
      photoprismModel.gridController.addListener(photoprismModel.notify);
    }
    return photoprismModel.gridController;
  }
}

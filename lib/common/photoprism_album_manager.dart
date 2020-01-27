import 'dart:convert';

import 'package:photoprism/pages/albums_page.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismAlbumManager {
  PhotoprismModel photoprismModel;

  PhotoprismAlbumManager(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void setAlbumList(List<Album> albumList) {
    photoprismModel.albums =
        Map.fromIterable(albumList, key: (e) => e.id, value: (e) => e);
    saveAlbumListToSharedPrefs();
    photoprismModel.notify();
  }

  void setPhotoListOfAlbum(List<Photo> photoList, String albumId) {
    print("setPhotoListOfAlbum: albumId: " + albumId);
    photoprismModel.albums[albumId].photoList = photoList;
    savePhotoListToSharedPrefs('photosList' + albumId, photoList);
    photoprismModel.notify();
  }

  Future savePhotoListToSharedPrefs(key, photoList) async {
    print("savePhotoListToSharedPrefs: key: " + key);
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(photoList));
  }

  Future saveAlbumListToSharedPrefs() async {
    print("saveAlbumListToSharedPrefs");
    var key = 'albumList';
    List<Album> albumList =
        photoprismModel.albums.entries.map((e) => e.value).toList();
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(albumList));
  }

  void addPhotosToAlbum(albumId, List<String> photoUUIDs) async {
    print("Adding photos to album " + albumId);
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Adding photos to album..");
    var status =
        await Api.addPhotosToAlbum(albumId, photoUUIDs, photoprismModel);

    if (status == 0) {
      await AlbumsPage.loadAlbums(
          photoprismModel, photoprismModel.photoprismUrl);
      await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
      photoprismModel.photoprismMessage
          .showMessage("Adding photos to album successfull.");
    } else {
      await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
      photoprismModel.photoprismMessage
          .showMessage("Adding photos to album failed.");
    }
  }
}

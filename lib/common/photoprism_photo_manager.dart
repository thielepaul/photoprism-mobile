import 'dart:collection';
import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/pages/photos_page.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:synchronized/synchronized.dart';

class PhotoprismPhotoManager {
  PhotoprismModel photoprismModel;
  List<MomentsTime> momentsTime;
  List<MomentsTime> cummulativeMonthCount = List();
  int photosCount;
  Map<int, Photo> photos = HashMap();
  Map<String, Map<int, Photo>> albumPhotos = HashMap();
  Lock lock = new Lock();

  PhotoprismPhotoManager(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  Future savePhotoListToSharedPrefs(key, photoList) async {
    print("savePhotoListToSharedPrefs: key: " + key);
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(photoList));
  }

  void setPhotoList(List<Photo> photoList) {
    photoprismModel.photoList = photoList;
    savePhotoListToSharedPrefs('photosList', photoList);
    photoprismModel.notify();
  }

  void archivePhotos(List<String> photoUUIDs) async {
    print("Archive photos");
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Archive photos..");
    var status = await Api.archivePhotos(photoUUIDs, photoprismModel);

    if (status == 0) {
      photoprismModel.gridController.selection = Selection({});
      await PhotosPage.loadPhotos(
          photoprismModel, photoprismModel.photoprismUrl, "");
      await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
      photoprismModel.photoprismMessage
          .showMessage("Photos archived successfully.");
    } else {
      await photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
      photoprismModel.photoprismMessage.showMessage("Archiving photos failed.");
    }
  }

  void setMomentsTime(List<MomentsTime> moments) {
    momentsTime = moments;
    photosCount = moments.map((v) => v.count).reduce((v, e) => v + e);
    momentsTime.forEach((m) {
      if (cummulativeMonthCount.length > 0) {
        m.count += cummulativeMonthCount.last.count;
      }
      cummulativeMonthCount.add(m);
    });
    photoprismModel.notify();
  }

  Future<void> loadPhoto(
      int index, String albumId, PhotoprismModel model) async {
    return await lock.synchronized(() async {
      if (albumId == "") {
        if (photos.containsKey(index)) {
          return;
        }
      } else {
        if (albumPhotos.containsKey(albumId) &&
            albumPhotos[albumId].containsKey(index)) {
          return;
        }
      }
      int offset = index - (index % 100);
      http.Response response = await http.get(
          model.photoprismUrl +
              '/api/v1/photos' +
              '?count=100' +
              '&offset=' +
              offset.toString() +
              '&album=' +
              albumId,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());
      final parsed = json.decode(response.body).cast<Map<String, dynamic>>();
      if (albumId == "") {
        photos.addAll(Map.fromIterables(
            List<int>.generate(parsed.length, (i) => i + offset),
            parsed.map<Photo>((json) => Photo.fromJson(json)).toList()));
      } else {
        if (!albumPhotos.containsKey(albumId)) {
          albumPhotos[albumId] = HashMap();
        }
        albumPhotos[albumId].addAll(Map.fromIterables(
            List<int>.generate(parsed.length, (i) => i + offset),
            parsed.map<Photo>((json) => Photo.fromJson(json)).toList()));
      }
      return;
    });
  }
}

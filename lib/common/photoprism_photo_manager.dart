import 'dart:convert';

import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismPhotoManager {
  PhotoprismModel photoprismModel;

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
}

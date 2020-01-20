import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/pages/photos_page.dart';
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

  void archivePhotos(List<String> photoUUIDs) async {
    print("Archive photos");
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Archive photos..");
    var status =
        await Api.archivePhotos(photoUUIDs, photoprismModel.photoprismUrl);

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
}

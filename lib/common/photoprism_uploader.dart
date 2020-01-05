import 'package:shared_preferences/shared_preferences.dart';

import '../model/photoprism_model.dart';

class PhotoprismUploader {
  bool autoUploadEnabled = false;
  PhotoprismModel photoprismModel;

  PhotoprismUploader(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
    getAutoUploadState();
  }

  void setAutoUpload(bool newState) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("autoUploadEnabled", newState);
    autoUploadEnabled = newState;
    photoprismModel.notifyListeners();
  }

  void getAutoUploadState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    autoUploadEnabled = prefs.getBool("autoUploadEnabled") ?? false;
    photoprismModel.notifyListeners();
  }
}

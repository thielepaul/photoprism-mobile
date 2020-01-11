import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismSettingsManager {
  PhotoprismModel photoprismModel;
  PhotoprismSettingsManager(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
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
}

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismCommonHelper {
  PhotoprismModel photoprismModel;
  PhotoprismCommonHelper(PhotoprismModel photoprismModel) {
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

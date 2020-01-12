import 'package:flushbar/flushbar.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismMessage {
  PhotoprismModel photoprismModel;
  PhotoprismMessage(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void showMessage(String message) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 2),
    )..show(photoprismModel.photoprismLoadingScreen.context);
  }
}

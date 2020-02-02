import 'package:flushbar/flushbar.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismMessage {
  PhotoprismMessage(this.photoprismModel);
  PhotoprismModel photoprismModel;

  void showMessage(String message) {
    final Flushbar<String> flushbar = Flushbar<String>(
      message: message,
      duration: const Duration(seconds: 2),
    );
    flushbar.show(photoprismModel.photoprismLoadingScreen.context);
  }
}

import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismMessage {
  PhotoprismModel photoprismModel;
  PhotoprismMessage(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void showMessage(String message) {
    final snackBar =
        SnackBar(content: Text(message), duration: const Duration(minutes: 5));
    photoprismModel.scaffoldKey.currentState.showSnackBar(snackBar);
  }
}

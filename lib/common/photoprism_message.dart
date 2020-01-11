import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismMessage {
  PhotoprismModel photoprismModel;
  PhotoprismMessage(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void showMessage(String message) {
    final snackBar = SnackBar(content: Text('Test Snack Bar!'));
    Scaffold.of(photoprismModel.photoprismLoadingScreen.context)
        .showSnackBar(snackBar);
  }
}

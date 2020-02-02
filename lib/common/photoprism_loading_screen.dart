import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:progress_dialog/progress_dialog.dart';

class PhotoprismLoadingScreen {
  PhotoprismLoadingScreen(this.photoprismModel);
  PhotoprismModel photoprismModel;
  ProgressDialog pr;
  BuildContext context;

  void showLoadingScreen(String message) {
    pr = ProgressDialog(context);
    pr.style(message: message);
    pr.show();
    photoprismModel.notify();
  }

  void updateLoadingScreen(String message) {
    pr.update(message: message);
  }

  Future<void> hideLoadingScreen() {
    Completer<void> hideLoadingScreenCompleter;
    Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
      pr.hide().whenComplete(() {
        hideLoadingScreenCompleter.complete();
      });
    });
    photoprismModel.notify();
    hideLoadingScreenCompleter = Completer<void>();
    return hideLoadingScreenCompleter.future;
  }
}

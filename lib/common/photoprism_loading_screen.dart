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
    if (pr != null) {
      return;
    }
    pr = ProgressDialog(context);
    pr.style(message: message);
    pr.show();
    photoprismModel.notify();
  }

  void updateLoadingScreen(String message) {
    if (pr != null) {
      pr.update(message: message);
    }
  }

  Future<void> hideLoadingScreen() async {
    if (pr != null) {
      Completer<void> hideLoadingScreenCompleter;
      Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
        pr.hide().whenComplete(() {
          hideLoadingScreenCompleter.complete();
          pr = null;
        });
      });
      photoprismModel.notify();
      hideLoadingScreenCompleter = Completer<void>();
      return hideLoadingScreenCompleter.future;
    }
  }
}

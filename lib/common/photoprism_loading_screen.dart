import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismLoadingScreen {
  PhotoprismLoadingScreen(this.photoprismModel);
  PhotoprismModel photoprismModel;
  late BuildContext context;
  GlobalKey dialogKey = GlobalKey();
  StreamController<String>? messages;

  void showLoadingScreen(String message) {
    if (messages != null) {
      return;
    }
    messages = StreamController<String>();
    messages!.add(message);
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialog(
            key: dialogKey,
            children: <Widget>[
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(
                      height: 10,
                      width: 10,
                    ),
                    Flexible(
                        child: StreamBuilder<String>(
                            stream: messages!.stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<String> msgSnapshot) {
                              return Text(msgSnapshot.data ?? '');
                            }))
                  ])),
            ],
          );
        });
    photoprismModel.notify();
  }

  void updateLoadingScreen(String message) {
    if (messages != null) {
      messages!.add(message);
    }
  }

  Future<void> hideLoadingScreen() async {
    if (messages == null) {
      return;
    }

    final Completer<void> hideLoadingScreenCompleter = Completer<void>();
    Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
      final BuildContext? dialogContext = dialogKey.currentContext;
      if (dialogContext != null) {
        Navigator.of(dialogContext).pop();
      }
      hideLoadingScreenCompleter.complete();
      messages = null;
    });
    photoprismModel.notify();
    return hideLoadingScreenCompleter.future;
  }
}

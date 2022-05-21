import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismLoadingScreen {
  PhotoprismLoadingScreen(this.photoprismModel);
  PhotoprismModel photoprismModel;
  BuildContext context;
  GlobalKey dialogKey = GlobalKey();
  StreamController<String> messages;

  void showLoadingScreen(String message) {
    messages = StreamController<String>();
    messages.add(message);
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleDialog(
            key: dialogKey,
            children: <Widget>[
              Center(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                          child: Row(children: <Widget>[
                        const CircularProgressIndicator(),
                        const SizedBox(
                          height: 10,
                          width: 10,
                        ),
                        StreamBuilder<String>(
                            stream: messages.stream,
                            builder: (BuildContext context,
                                AsyncSnapshot<String> msgSnapshot) {
                              return Text(msgSnapshot.data);
                            })
                      ])))),
            ],
          );
        });
    photoprismModel.notify();
  }

  void updateLoadingScreen(String message) {
    if (messages != null) {
      messages.add(message);
    }
  }

  Future<void> hideLoadingScreen() async {
    final Completer<void> hideLoadingScreenCompleter = Completer<void>();
    Future<void>.delayed(const Duration(milliseconds: 500)).then((_) {
      Navigator.of(dialogKey.currentContext, rootNavigator: true).pop();
      hideLoadingScreenCompleter.complete();
    });
    photoprismModel.notify();
    return hideLoadingScreenCompleter.future;
  }
}

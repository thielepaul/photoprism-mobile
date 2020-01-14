import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AutoUploadQueue extends StatelessWidget {
  PhotoprismModel _model;

  AutoUploadQueue(PhotoprismModel model) {
    this._model = model;
  }

  @override
  Widget build(BuildContext context) {
    this._model = Provider.of<PhotoprismModel>(context);
    return Scaffold(
        appBar: AppBar(title: Text("Auto upload queue")),
        body: ListView.builder(
            itemCount: _model.photosToUpload.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text(_model.photosToUpload[index]));
            }));
  }
}

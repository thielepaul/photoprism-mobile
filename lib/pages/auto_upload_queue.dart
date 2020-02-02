import 'package:flutter/material.dart';
import 'package:photoprism/model/photoprism_model.dart';

class AutoUploadQueue extends StatelessWidget {
  const AutoUploadQueue(PhotoprismModel model) : _model = model;

  final PhotoprismModel _model;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Auto upload queue')),
        body: ListView.builder(
            itemCount: _model.photosToUpload.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text(_model.photosToUpload[index]));
            }));
  }
}

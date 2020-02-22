import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;

class FileList extends StatefulWidget {
  const FileList({Key key, this.files, this.title = ''}) : super(key: key);
  final List<String> files;
  final String title;

  @override
  _FileListState createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  Future<Map<String, photolib.AssetEntity>> assetsFuture =
      PhotoprismUploader.getAllPhotoAssetsAsMap();

  Map<String, String> filenames = <String, String>{};

  Future<void> getFileName(String id) async {
    assetsFuture.then((Map<String, photolib.AssetEntity> assets) =>
        assets[id].file.then((File file) => setState(() {
              filenames[id] = file.uri.toString();
            })));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ListView.builder(
            itemCount: widget.files.length,
            itemBuilder: (BuildContext context, int index) {
              final String id = widget.files[index];
              filenames[id] ?? getFileName(id);
              return ListTile(title: Text(filenames[id] ?? id));
            }));
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart' as photolib;
import 'package:photoprism/model/photoprism_model.dart';

class FileList extends StatefulWidget {
  const FileList(this.model, {Key? key, required this.files, this.title = ''})
      : super(key: key);
  final List<String> files;
  final String title;
  final PhotoprismModel model;

  @override
  _FileListState createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  Map<String, photolib.AssetEntity?> assets = <String, photolib.AssetEntity?>{};

  @override
  void initState() {
    for (final String id in widget.files) {
      photolib.AssetEntity.fromId(id)
          .then((photolib.AssetEntity? value) => setState(() {
                assets[id] = value;
              }));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ListView.builder(
            itemCount: widget.files.length,
            itemBuilder: (BuildContext context, int index) {
              final String id = widget.files[index];
              return ListTile(
                leading: assets[id] == null
                    ? null
                    : FutureBuilder<Uint8List?>(
                        future: assets[id]!.thumbnailData,
                        builder: (BuildContext context,
                            AsyncSnapshot<Uint8List?> snapshot) {
                          if (snapshot.data == null) {
                            return Container(
                              height: 1,
                              width: 1,
                            );
                          }
                          return AspectRatio(
                              aspectRatio: 1,
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ));
                        }),
                title: assets[id] == null
                    ? Text(id)
                    : FutureBuilder<String>(
                        future: assets[id]!.titleAsync,
                        builder: (BuildContext context,
                                AsyncSnapshot<String> snapshot) =>
                            Text(snapshot.data ?? '')),
                subtitle: assets[id] == null
                    ? null
                    : Text(DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(assets[id]!.createDateTime)),
              );
            }));
  }
}

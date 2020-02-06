import 'package:flutter/material.dart';

class FileList extends StatelessWidget {
  const FileList({this.files, this.title = ''});

  final List<String> files;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView.builder(
            itemCount: files.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(title: Text(files[index]));
            }));
  }
}

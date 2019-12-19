import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumView extends StatelessWidget {
  final String photoprismUrl;
  final Album album;
  final String _albumTitle;
  final BuildContext context;

  AlbumView(this.context, this.album, this.photoprismUrl)
      : _albumTitle = album.name;

  void deleteAlbum(int choice) {
    if (choice == 0) {
      print("renaming album");
    } else if (choice == 1) {
      print("deleting album");
      _deleteDialog(context);
    }
  }

  _deleteDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Delete Album'),
            content: Text('Are you sure you want to delete this album?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Delete'),
                onPressed: () {
                  // close dialog
                  Navigator.pop(context);

                  // go back to albums
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_albumTitle),
        actions: <Widget>[
          // overflow menu
          PopupMenuButton<int>(
            onSelected: deleteAlbum,
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 0,
                child: Text("Rename album"),
              ),
              PopupMenuItem(
                value: 1,
                child: Text("Delete album"),
              ),
            ],
          ),
        ],
        backgroundColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
      ),
      body: Photos(context, photoprismUrl, album.id).getGridView(),
    );
  }
}

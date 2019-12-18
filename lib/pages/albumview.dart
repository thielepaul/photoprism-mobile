import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

import '../main.dart';

class AlbumView extends StatelessWidget {
  Widget _photosGridView = Text(
    "none",
    key: ValueKey('photosGridView'),
  );
  String photoprismUrl = "";
  ScrollController _scrollController;
  Album album;
  String _albumTitle = "";
  TextEditingController _urlTextFieldController = TextEditingController();
  BuildContext context;

  AlbumView(BuildContext context, Album album, String photoprismUrl) {
    this.album = album;
    this._albumTitle = album.name;
    this.photoprismUrl = photoprismUrl;
    this.context = context;

    initialize();
  }

  void initialize() async {
    print("init albumview");
    _scrollController = new ScrollController()..addListener(_scrollListener);
  }

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await Photos.loadMorePhotos(context, photoprismUrl, album.id);
    }
  }

  // @override
  // void dispose() {
  //   _scrollController.removeListener(_scrollListener);
  //   super.dispose();
  // }

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
      body: Photos.getGridView(
          context, photoprismUrl, _scrollController, album.id),
    );
  }
}

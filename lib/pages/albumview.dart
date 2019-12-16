import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/hexcolor.dart';
import 'package:photoprism/model/album.dart';

import '../main.dart';

class AlbumView extends StatefulWidget {
  Album album;
  String photoprismUrl;

  AlbumView(Album album, String photoprismUrl) {
    this.album = album;
    this.photoprismUrl = photoprismUrl;
  }

  @override
  _AlbumViewState createState() => _AlbumViewState(album, photoprismUrl);
}

class _AlbumViewState extends State<AlbumView> {
  GridView _photosGridView = GridView.count(
    crossAxisCount: 1,
  );
  String photoprismUrl = "";
  Photos photos;
  ScrollController _scrollController;
  Album album;
  String _albumTitle = "";
  TextEditingController _urlTextFieldController = TextEditingController();

  _AlbumViewState(Album album, String photoprismUrl) {
    this.album = album;
    this.photos = Photos.withAlbum(album);
    this._albumTitle = album.name;
    this.photoprismUrl = photoprismUrl;
  }

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await photos.loadMorePhotos(photoprismUrl);

      GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
      setState(() {
        _photosGridView = gridView;
      });
    }
  }

  void loadPhotos() async {
    await photos.loadPhotosFromNetworkOrCache(photoprismUrl);
    GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
    setState(() {
      _photosGridView = gridView;
    });
  }

  void refreshPhotos() async {
    loadPhotos();
    settings.loadSettings(photoprismUrl);
  }

  @override
  void initState() {
    super.initState();
    refreshPhotos();
    _scrollController = new ScrollController()..addListener(_scrollListener); // fehler?
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void deleteAlbum(int choice) {
    if (choice == 0) {
      print("renaming album");

    }
    else if (choice == 1) {
      print("deleting album");
      setState(() {
        _deleteDialog(context);
      });
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
        backgroundColor: HexColor(settings.applicationColor),
      ),
      body: _photosGridView,
    );
  }
}
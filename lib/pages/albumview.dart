import 'package:flutter/material.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/hexcolor.dart';
import 'package:photoprism/model/album.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class AlbumView extends StatefulWidget {
  Album album;

  AlbumView(Album album) {
    this.album = album;
  }

  @override
  _AlbumViewState createState() => _AlbumViewState(album);
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

  _AlbumViewState(Album album) {
    this.album = album;
    this.photos = Photos.withAlbum(album);
    this._albumTitle = album.name;
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
    await photos.loadPhotos(photoprismUrl);
    GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
    setState(() {
      _photosGridView = gridView;
    });
  }

  void refreshPhotos() async {
    await getPhotoprismUrl();
    loadPhotos();
    settings.loadSettings(photoprismUrl);
  }

  Future getPhotoprismUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _url = prefs.getString("url");
    setState(() {
      photoprismUrl = _url;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshPhotos();
    _scrollController = new ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_albumTitle),
        backgroundColor: HexColor(settings.applicationColor),
      ),
      body: _photosGridView,
    );
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:photoprism/pages/albumview.dart';
import 'package:photoprism/pages/photoview.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photoprism/settings.dart';
import 'package:photoprism/hexcolor.dart';

import 'api/photos.dart';

final uploader = FlutterUploader();
Settings settings = Settings();

void main() => runApp(MyApp());

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photoprism',
      theme: ThemeData(),
      home: MainPage(title: 'Photoprism'),
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  GridView _photosGridView = GridView.count(
    crossAxisCount: 1,
  );
  GridView _albumsGridView = GridView.count(
    crossAxisCount: 1,
  );
  PageController _pageController;
  int _selectedPageIndex = 0;
  TextEditingController _urlTextFieldController = TextEditingController();
  String photoprismUrl = "";
  Photos photos = Photos();
  ScrollController _scrollController;

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await photos.loadMorePhotos(photoprismUrl);

      GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
      setState(() {
        _photosGridView = gridView;
      });
    }
  }

  Future setPhotoprismUrl(String _url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("url", _url);
    setState(() {
      photoprismUrl = _url;
    });
  }

  Future getPhotoprismUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _url = prefs.getString("url");
    setState(() {
      photoprismUrl = _url;
    });
  }

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void loadPhotos() async {
    await photos.loadPhotos(photoprismUrl);
    GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
    setState(() {
      _photosGridView = gridView;
    });
  }

  Future loadAlbums() async {
    http.Response response =
        await http.get(photoprismUrl + '/api/v1/albums?count=1000');
    final parsed = json.decode(response.body).cast<Map<String, dynamic>>();

    List<Album> albumList =
        parsed.map<Album>((json) => Album.fromJson(json)).toList();

    GridView albumsGridView = GridView.builder(
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: albumList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AlbumView(albumList[index])),
                );
              },
              child: GridTile(
                child: Image.network(
                  photoprismUrl +
                      '/api/v1/albums/' +
                      albumList[index].id +
                      '/thumbnail/tile_224',
                ),
                footer: GestureDetector(
                  child: GridTileBar(
                    backgroundColor: Colors.black45,
                    title: _GridTitleText(albumList[index].name),
                  ),
                ),
              ));
        });

    setState(() {
      _albumsGridView = albumsGridView;
    });
  }

  void refreshPhotos() async {
    await getPhotoprismUrl();
    loadAlbums();
    loadPhotos();
    settings.loadSettings(photoprismUrl);
  }

  Future<void> refreshPhotosPull() async {
    print('refreshing photos..');
    await getPhotoprismUrl();
    loadPhotos();
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');
    await getPhotoprismUrl();
    loadAlbums();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _selectedPageIndex = 0;
    refreshPhotos();
    _scrollController = new ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  _settingsDisplayUrlDialog(BuildContext context) async {
    _urlTextFieldController.text = photoprismUrl;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter Photoprism URL'),
            content: TextField(
              controller: _urlTextFieldController,
              decoration:
                  InputDecoration(hintText: "https://demo.photoprism.org"),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                onPressed: () {
                  setPhotoprismUrl(_urlTextFieldController.text);
                  // refreshPhotos();
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  settingsPage() => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Text("Photoprism URL"),
            subtitle: Text(photoprismUrl),
            onTap: () {
              setState(() {
                _settingsDisplayUrlDialog(context);
              });
            },
          ),
        ],
      );

  photosPage() => _photosGridView;

  albumsPage() => _albumsGridView;

  navigationBar() => BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            title: Text('Photos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            title: Text('Albums'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
        currentIndex: _selectedPageIndex,
        selectedItemColor: HexColor(settings.applicationColor),
        onTap: _onTappedNavigationBar,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: HexColor(settings.applicationColor),
      ),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(child: photosPage(), onRefresh: refreshPhotosPull),
            RefreshIndicator(child: albumsPage(), onRefresh: refreshAlbumsPull),
            settingsPage(),
          ]),
      bottomNavigationBar: navigationBar(),
    );
  }
}

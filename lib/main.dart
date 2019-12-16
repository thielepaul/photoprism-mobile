import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:photoprism/api/albums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photoprism/settings.dart';
import 'package:photoprism/hexcolor.dart';

import 'api/photos.dart';

final uploader = FlutterUploader();
Settings settings = Settings();

void main() => runApp(MyApp());

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
  Albums albums = Albums();
  ScrollController _scrollController;

  String applicationColor = "#000000";

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
    if (_url == null) {
      _url = "https://demo.photoprism.org";
    }
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
    await photos.loadPhotosFromNetworkOrCache(photoprismUrl);
    GridView gridView = photos.getGridView(photoprismUrl, _scrollController);
    setState(() {
      _photosGridView = gridView;
    });
  }

  void loadAlbums() async {
    await albums.loadAlbumsFromNetworkOrCache(photoprismUrl);
    GridView gridView = albums.getGridView(photoprismUrl);
    setState(() {
      _albumsGridView = gridView;
    });
  }

  void refreshPhotos() async {
    await getPhotoprismUrl();
    String col = await settings.loadSettings(photoprismUrl);
    setState(() {
      applicationColor = col;
    });
    loadAlbums();
    loadPhotos();
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }

  Future<void> refreshPhotosPull() async {
    print('refreshing photos..');
    await getPhotoprismUrl();
    await photos.loadPhotos(photoprismUrl);
    loadPhotos();
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');
    await getPhotoprismUrl();
    await albums.loadAlbums(photoprismUrl);
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

  void setNewPhotoprismUrl(url) async {
    Navigator.of(context).pop();
    String col = await settings.loadSettings(url);
    setState(() {
      applicationColor = col;
    });
    await setPhotoprismUrl(url);
    await emptyCache();
    await refreshPhotosPull();
    await refreshAlbumsPull();
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
                textColor: HexColor(applicationColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Save'),
                textColor: HexColor(applicationColor),
                onPressed: () {
                  setNewPhotoprismUrl(_urlTextFieldController.text);
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
          ListTile(
            title: Text("Empty cache"),
            onTap: () {
              emptyCache();
            },
          )
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
        selectedItemColor: HexColor(applicationColor),
        onTap: _onTappedNavigationBar,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: HexColor(applicationColor),
      ),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(child: photosPage(), onRefresh: refreshPhotosPull, color: HexColor(applicationColor)),
            RefreshIndicator(child: albumsPage(), onRefresh: refreshAlbumsPull, color: HexColor(applicationColor)),
            settingsPage(),
          ]),
      bottomNavigationBar: navigationBar(),
    );
  }
}

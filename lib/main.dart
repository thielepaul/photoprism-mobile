import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'api/photos.dart';
import 'model/photoprism_model.dart';

final uploader = FlutterUploader();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PhotoprismModel(),
      child: MyApp(),
    ),
  );
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
  Widget _photosGridView = Text(
    "loading",
    key: ValueKey('photosGridView'),
  );
  GridView _albumsGridView = GridView.count(
    crossAxisCount: 1,
    key: ValueKey('albumsGridView'),
  );
  PageController _pageController;
  int _selectedPageIndex = 0;
  Albums albums = Albums();
  ScrollController _scrollController;

  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await Photos.loadMorePhotos(
          context, Provider.of<PhotoprismModel>(context).photoprismUrl, "");

      setState(() {
        _photosGridView = Photos.getGridView(
            context,
            Provider.of<PhotoprismModel>(context).photoprismUrl,
            _scrollController,
            "");
      });
    }
  }

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }

  Future<void> refreshPhotosPull() async {
    print('refreshing photos..');
    await Photos.loadPhotos(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl, "");

    await Photos.loadPhotosFromNetworkOrCache(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl, "");
    setState(() {
      _photosGridView = Photos.getGridView(
          context,
          Provider.of<PhotoprismModel>(context).photoprismUrl,
          _scrollController,
          "");
    });
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');
    await albums.loadAlbums(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl);

    await albums.loadAlbumsFromNetworkOrCache(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl);
    GridView gridView =
        albums.getGridView(Provider.of<PhotoprismModel>(context).photoprismUrl);
    setState(() {
      _albumsGridView = gridView;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _selectedPageIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());

    _scrollController = new ScrollController()..addListener(_scrollListener);
  }

  void initialize() {
    refreshPhotosPull();
    refreshAlbumsPull();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  photosPage() => _photosGridView;
  albumsPage() => _albumsGridView;

  @override
  Widget build(BuildContext context) {
    var photorismModel = Provider.of<PhotoprismModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: HexColor(photorismModel.applicationColor),
      ),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(
                child: photosPage(),
                onRefresh: refreshPhotosPull,
                color: HexColor(photorismModel.applicationColor)),
            RefreshIndicator(
                child: albumsPage(),
                onRefresh: refreshAlbumsPull,
                color: HexColor(photorismModel.applicationColor)),
            Settings(),
          ]),
      bottomNavigationBar: BottomNavigationBar(
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
        selectedItemColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
        onTap: _onTappedNavigationBar,
      ),
    );
  }
}

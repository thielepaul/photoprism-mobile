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
      home: MainPage('Photoprism', context),
    );
  }
}

class MainPage extends StatelessWidget {
  MainPage(String title, BuildContext context) {
    this.title = title;
    _pageController = PageController(initialPage: 0);
    _scrollController = ScrollController()..addListener(_scrollListener);
    this.context = context;
  }
  String title;
  PageController _pageController;
  ScrollController _scrollController;
  BuildContext context;


  void _scrollListener() async {
    if (_scrollController.position.extentAfter < 500) {
      await Photos.loadMorePhotos(
          context, Provider.of<PhotoprismModel>(context).photoprismUrl, "");
    }
  }

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    Provider.of<PhotoprismModel>(context).setSelectedPageIndex(index);
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
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');
    await Albums.loadAlbums(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl);

    await Albums.loadAlbumsFromNetworkOrCache(
        context, Provider.of<PhotoprismModel>(context).photoprismUrl);
  }

  void initialize() {
    // WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  @override
  Widget build(BuildContext context) {
    var photorismModel = Provider.of<PhotoprismModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: HexColor(photorismModel.applicationColor),
      ),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(
                child: Photos.getGridView(
                    context,
                    Provider.of<PhotoprismModel>(context).photoprismUrl,
                    _scrollController,
                    ""),
                onRefresh: refreshPhotosPull,
                color: HexColor(photorismModel.applicationColor)),
            RefreshIndicator(
                child: Albums.getGridView(
                    Provider.of<PhotoprismModel>(context).photoprismUrl),
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
        currentIndex: Provider.of<PhotoprismModel>(context).selectedPageIndex,
        selectedItemColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
        onTap: _onTappedNavigationBar,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'api/photos.dart';
import 'model/photoprism_model.dart';
// use this for debugging animations
// import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  // use this for debugging animations
  // timeDilation = 10.0;
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
      title: 'PhotoPrism',
      theme: ThemeData(),
      home: MainPage('PhotoPrism', context),
    );
  }
}

class MainPage extends StatelessWidget {
  final String title;
  final PageController _pageController;
  final BuildContext context;

  MainPage(this.title, this.context) : _pageController = PageController(initialPage: 0);

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    Provider.of<PhotoprismModel>(context).setSelectedPageIndex(index);
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }

  Future<void> refreshPhotosPull() async {
    print('refreshing photos..');

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    await Photos.loadPhotos(model, model.photoprismUrl, "");

    await Photos.loadPhotosFromNetworkOrCache(model, model.photoprismUrl, "");
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    await Albums.loadAlbums(model, model.photoprismUrl);

    await Albums.loadAlbumsFromNetworkOrCache(model, model.photoprismUrl);
  }

  AppBar getAppBar(context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    if (model.selectedPageIndex == 0) {
      return AppBar(
        title: model
            .gridController
            .selection
            .selectedIndexes
            .length > 0
            ? Text("Selected " +
            model
                .gridController
                .selection
                .selectedIndexes
                .length
                .toString() +
            " photos")
            : Text(title),
        backgroundColor: HexColor(model.applicationColor),
        actions: model
            .gridController
            .selection
            .selectedIndexes
            .length > 0
            ? <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add to album',
            onPressed: () {
              _selectAlbumDialog(context);
            },
          ),
        ]
            : <Widget>[
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Upload photo',
            onPressed: () {
              model
                  .photoprismUploader
                  .startManualPhotoUpload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh photos',
            onPressed: () {
              refreshPhotosPull();
            },
          )
        ],
      );
    } else if (model.selectedPageIndex == 1) {
      return AppBar(
        title: Text(title),
        backgroundColor:
        HexColor(model.applicationColor),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create album',
            onPressed: () {
              model.createAlbum();
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(title),
        backgroundColor: HexColor(model.applicationColor),
      );
    }
  }

  _selectAlbumDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select album'),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                  itemCount: Albums.getAlbumList(context).length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return GestureDetector(
                        onTap: () {
                          addPhotosToAlbum(
                              Albums.getAlbumList(context)[index].id, context);
                        },
                        child: Card(
                            child: ListTile(
                                title: Text(
                                    Albums.getAlbumList(context)[index].name))));
                  }),
            ),
          );
        });
  }

  addPhotosToAlbum(albumId, context) async {
    Navigator.pop(context);

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<String> selectedPhotos = [];

    model
        .gridController
        .selection
        .selectedIndexes
        .forEach((element) {
      selectedPhotos.add(Photos.getPhotoList(context, "")[element].photoUUID);
    });

    model.gridController.clear();
    await model.addPhotosToAlbum(albumId, selectedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    model.context = context;

    return Scaffold(
      appBar: getAppBar(context),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(
                child: Photos(
                    context: context,
                    photoprismUrl: model.photoprismUrl,
                    albumId: ""),
                onRefresh: refreshPhotosPull,
                color: HexColor(model.applicationColor)),
            RefreshIndicator(
                child: Albums(
                    photoprismUrl: model.photoprismUrl),
                onRefresh: refreshAlbumsPull,
                color: HexColor(model.applicationColor)),
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
        currentIndex: model.selectedPageIndex,
        selectedItemColor: HexColor(model.applicationColor),
        onTap: _onTappedNavigationBar,
      ),
    );
  }
}

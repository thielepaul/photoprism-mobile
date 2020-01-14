import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/pages/album_detail_view.dart';
import 'package:photoprism/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'api/api.dart';
import 'api/photos.dart';
import 'model/album.dart';
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
  @override
  Widget build(BuildContext context) {
    final Color applicationColor =
        HexColor(Provider.of<PhotoprismModel>(context).applicationColor);

    return MaterialApp(
      title: 'PhotoPrism',
      theme: ThemeData(
        primaryColor: applicationColor,
        accentColor: applicationColor,
        textSelectionColor: applicationColor,
        textSelectionHandleColor: applicationColor,
        cursorColor: applicationColor,
        inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: applicationColor))),
      ),
      home: MainPage('PhotoPrism'),
    );
  }
}

class MainPage extends StatelessWidget {
  final String title;
  final PageController _pageController;
  BuildContext context;

  MainPage(this.title) : _pageController = PageController(initialPage: 0);

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    Provider.of<PhotoprismModel>(context)
        .photoprismCommonHelper
        .setSelectedPageIndex(index);
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
        title: model.gridController.selection.selectedIndexes.length > 0
            ? Text(model.gridController.selection.selectedIndexes.length
                .toString())
            : Text(title),
        backgroundColor: HexColor(model.applicationColor),
        leading: model.gridController.selection.selectedIndexes.length > 0
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  model.gridController.selection = Selection({});
                },
              )
            : null,
        actions: model.gridController.selection.selectedIndexes.length > 0
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.archive),
                  tooltip: 'Archive photos',
                  onPressed: () {
                    archiveSelectedPhotos();
                  },
                ),
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
                    model.photoprismUploader.selectPhotoAndUpload();
                  },
                )
              ],
      );
    } else if (model.selectedPageIndex == 1) {
      return AppBar(
        title: Text(title),
        backgroundColor: HexColor(model.applicationColor),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create album',
            onPressed: () {
              //model.photoprismAlbumManager.createAlbum();
              createAlbum();
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(title),
      );
    }
  }

  void createAlbum() async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    var uuid = await Api.createAlbum("New album", model.photoprismUrl);

    if (uuid == "-1") {
      model.photoprismMessage.showMessage("Creating album failed.");
    } else {
      List<Album> albums = Albums.getAlbumList(this.context);

      int length = 0;
      if (albums != null) {
        length = albums.length;
      }

      albums.add(Album(id: uuid, name: "New album", imageCount: 0));
      model.photoprismAlbumManager.setAlbumList(albums);

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) =>
                AlbumDetailView(Albums.getAlbumList(context)[length])),
      );
    }
  }

  archiveSelectedPhotos() async {
    List<String> selectedPhotos = [];
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos.add(Photos.getPhotoList(context, "")[element].photoUUID);
    });
    model.photoprismPhotoManager.archivePhotos(selectedPhotos);
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
                                title: Text(Albums.getAlbumList(context)[index]
                                    .name))));
                  }),
            ),
          );
        });
  }

  addPhotosToAlbum(albumId, context) async {
    Navigator.pop(context);

    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<String> selectedPhotos = [];

    model.gridController.selection.selectedIndexes.forEach((element) {
      selectedPhotos.add(Photos.getPhotoList(context, "")[element].photoUUID);
    });

    model.gridController.clear();
    await model.photoprismAlbumManager
        .addPhotosToAlbum(albumId, selectedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    model.photoprismLoadingScreen.context = context;

    return Scaffold(
      appBar: getAppBar(context),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(
                child: Photos(context: context, albumId: ""),
                onRefresh: refreshPhotosPull),
            RefreshIndicator(
                child: Albums(photoprismUrl: model.photoprismUrl),
                onRefresh: refreshAlbumsPull),
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
        onTap: _onTappedNavigationBar,
      ),
    );
  }
}

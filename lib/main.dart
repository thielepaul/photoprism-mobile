import 'package:flutter/material.dart';
import 'package:photoprism/pages/albums_page.dart';
import 'package:photoprism/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/pages/photos_page.dart';
import 'package:photoprism/model/photoprism_model.dart';
// use this for debugging animations
// import 'package:flutter/scheduler.dart' show timeDilation;

void main() {
  // use this for debugging animations
  // timeDilation = 10.0;
  runApp(
    ChangeNotifierProvider<PhotoprismModel>(
      create: (BuildContext context) => PhotoprismModel(),
      child: PhotoprismApp(),
    ),
  );
}

class PhotoprismApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color applicationColor =
        HexColor(Provider.of<PhotoprismModel>(context).applicationColor);

    return MaterialApp(
      title: 'PhotoPrism',
      theme: ThemeData(
        primaryColor: applicationColor,
        accentColor: applicationColor,
        colorScheme: ColorScheme.light(
          primary: applicationColor,
        ),
        textSelectionColor: applicationColor,
        textSelectionHandleColor: applicationColor,
        cursorColor: applicationColor,
        inputDecorationTheme: InputDecorationTheme(
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: applicationColor))),
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  MainPage() : _pageController = PageController(initialPage: 0);
  final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    model.photoprismLoadingScreen.context = context;

    if (!model.dataFromCacheLoaded) {
      model.loadDataFromCache(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('PhotoPrism'),
        ),
      );
    }

    return Scaffold(
      body: PageView(
          controller: _pageController,
          children: <Widget>[
            const PhotosPage(albumId: null),
            const AlbumsPage(),
            SettingsPage(),
          ],
          physics: const NeverScrollableScrollPhysics()),
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
        onTap: (int index) {
          _pageController.jumpToPage(index);
          model.photoprismCommonHelper.setSelectedPageIndex(index);
        },
      ),
    );
  }
}

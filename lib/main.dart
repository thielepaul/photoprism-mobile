import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photoprism/model/filter_photos.dart';
import 'package:photoprism/pages/albums_page.dart';
import 'package:photoprism/pages/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'package:photoprism/common/db_init.dart';
import 'package:photoprism/pages/photos_page.dart';
import 'package:photoprism/model/photoprism_model.dart';
// use this for debugging animations
// import 'package:flutter/scheduler.dart' show timeDilation;

enum PageIndex { Photos, Albums, Settings }

void main() {
  // use this for debugging animations
  // timeDilation = 10.0;
  runApp(
    EasyLocalization(
        supportedLocales: const <Locale>[
          Locale('en', 'US'),
          Locale('de', 'DE'),
          Locale('fr', 'FR')
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: ChangeNotifierProvider<PhotoprismModel>(
          create: (BuildContext context) =>
              PhotoprismModel(connectDbAsync, const FlutterSecureStorage()),
          child: PhotoprismApp(),
        )),
  );
}

class PhotoprismApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color applicationColor =
        HexColor(Provider.of<PhotoprismModel>(context).applicationColor);

    return MaterialApp(
      title: 'PhotoPrism',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primaryColor: applicationColor,
        accentColor: applicationColor,
        colorScheme: ColorScheme.light(
          primary: applicationColor,
        ),
        textSelectionColor: applicationColor,
        textSelectionHandleColor: applicationColor,
        cursorColor: applicationColor,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: applicationColor, foregroundColor: Colors.white),
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
    if (!model.initialized) {
      model.initialize();
      return Container();
    }
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
      appBar: model.selectedPageIndex == PageIndex.Photos
          ? PhotosPage.appBar(context)
          : null,
      body: PageView(
          controller: _pageController,
          children: <Widget>[
            const PhotosPage(),
            const AlbumsPage(),
            SettingsPage(),
          ],
          physics: const NeverScrollableScrollPhysics()),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: const Icon(Icons.photo), label: 'photos'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.photo_album), label: 'albums'.tr()),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings), label: 'settings'.tr()),
        ],
        currentIndex: model.selectedPageIndex.index,
        onTap: (int index) async {
          if (index != _pageController.page) {
            model.gridController.clear();
            model.albumUid = null;
            model.filterPhotos = await FilterPhotos.fromSharedPrefs();
            model.updatePhotosSubscription();
          }
          _pageController.jumpToPage(index);
          model.photoprismCommonHelper
              .setSelectedPageIndex(PageIndex.values[index]);
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

import 'dart:async';
import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/api/db_api.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/common/photoprism_auth.dart';
import 'package:photoprism/common/photoprism_remote_config_loader.dart';
import 'package:photoprism/common/photoprism_loading_screen.dart';
import 'package:photoprism/common/photoprism_message.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/photos_from_db.dart';
import 'package:photoprism/model/dbtimestamps.dart';
import 'package:photoprism/model/filter_photos.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:sqlite3/sqlite3.dart';

class PhotoprismModel extends ChangeNotifier {
  PhotoprismModel(this.dbConnection, this.secureStorage);
  // general
  String photoprismUrl = 'https://demo.photoprism.org';
  Config config;
  Lock dbLoadingLock = Lock();
  bool _dataFromCacheLoaded = false;
  bool _initializing = false;
  bool initialized = false;
  List<String> log;
  MyDatabase database;
  StreamSubscription<int> photosStreamSubscription;
  PhotosFromDb photos;
  StreamSubscription<List<Album>> albumsStreamSubscription;
  List<Album> albums;
  StreamSubscription<Map<String, int>> albumCountsStreamSubscription;
  Map<String, int> albumCounts;
  DbTimestamps dbTimestamps;
  FilterPhotos filterPhotos;
  String albumUid;
  Future<MyDatabase> Function() dbConnection;
  FlutterSecureStorage secureStorage;

  // theming
  String applicationColor = '#424242';

  // photoprism uploader
  bool autoUploadEnabled = false;
  String autoUploadLastTimeCheckedForPhotos = 'Never';
  Set<String> _albumsToUpload = <String>{};
  Set<String> _photosToUpload = <String>{};
  Set<String> _photosUploadFailed = <String>{};
  Set<String> _alreadyUploadedPhotos = <String>{};

  // runtime data
  bool isLoading = false;
  PageIndex selectedPageIndex = PageIndex.Photos;
  DragSelectGridViewController _gridController = DragSelectGridViewController();
  DragSelectGridViewController get gridController {
    try {
      _gridController.addListener(notify);
    } catch (_) {
      _gridController = DragSelectGridViewController();
      _gridController.addListener(notify);
    }
    return _gridController;
  }

  ScrollController scrollController = ScrollController();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;
  BuildContext context;

  // helpers
  PhotoprismUploader photoprismUploader;
  PhotoprismRemoteSettingsLoader photoprismRemoteConfigLoader;
  PhotoprismCommonHelper photoprismCommonHelper;
  PhotoprismLoadingScreen photoprismLoadingScreen;
  PhotoprismMessage photoprismMessage;
  PhotoprismAuth photoprismAuth;

  Future<void> initialize() async {
    if (_initializing) {
      return;
    }
    _initializing = true;
    print('initialize model');
    photoprismLoadingScreen = PhotoprismLoadingScreen(this);
    photoprismRemoteConfigLoader = PhotoprismRemoteSettingsLoader(this);
    photoprismCommonHelper = PhotoprismCommonHelper(this);
    photoprismMessage = PhotoprismMessage(this);
    photos = PhotosFromDb(this);

    photoprismAuth = PhotoprismAuth(this, secureStorage);

    if (io.Platform.isAndroid) {
      final String cachebase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cachebase;
    }

    database = await dbConnection();

    // uploader needs photoprismAuth to be initialized
    await photoprismAuth.initialize();

    await photoprismRemoteConfigLoader.loadApplicationColor();
    gridController.addListener(notifyListeners);

    await loadLog();

    photoprismUploader = PhotoprismUploader(this);

    dbTimestamps = await DbTimestamps.fromSharedPrefs();
    filterPhotos = await FilterPhotos.fromSharedPrefs();

    updatePhotosSubscription();
    updateAlbumsSubscription();

    await photoprismCommonHelper.loadPhotoprismUrl();

    initialized = true;
    notifyListeners();
    await DbApi.updateDb(this);
  }

  Future<void> resetDatabase() async {
    photosStreamSubscription = null;
    albumsStreamSubscription = null;
    albumCountsStreamSubscription = null;
    print('closing database');
    await database.close();
    await database.deleteDatabase();
    print('create new database');
    database = await dbConnection();
    await updatePhotosSubscription();
    await updateAlbumsSubscription();
    await dbTimestamps.clear();
  }

  Future<void> loadLog() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final List<String> logList = sp.getStringList('photoprism_log');

    if (logList == null) {
      log = <String>[];
    } else {
      log = logList;
    }
    notifyListeners();
    return 0;
  }

  Future<void> addLogEntry(String type, String message) async {
    final DateTime now = DateTime.now();
    final String currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    log.insert(0, currentTime.toString() + ' [' + type + ']\n' + message);
    print(currentTime.toString() + ' [' + type + '] ' + message);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setStringList('photoprism_log', log);
    notifyListeners();
    return 0;
  }

  Future<void> clearLog() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setStringList('photoprism_log', null);

    log = <String>[];
    notifyListeners();
    return 0;
  }

  void setConfig(Config newValue) {
    config = newValue;
    PhotoprismCommonHelper.saveAsJsonToSharedPrefs('config', config);
    notifyListeners();
  }

  set alreadyUploadedPhotos(Set<String> newValue) {
    _alreadyUploadedPhotos = newValue;
    notifyListeners();
  }

  Set<String> get alreadyUploadedPhotos =>
      Set<String>.from(_alreadyUploadedPhotos);

  set albumsToUpload(Set<String> newValue) {
    _albumsToUpload = newValue;
    notifyListeners();
  }

  Set<String> get albumsToUpload => Set<String>.from(_albumsToUpload);

  set photosToUpload(Set<String> newValue) {
    _photosToUpload = newValue;
    notifyListeners();
  }

  Set<String> get photosToUpload => Set<String>.from(_photosToUpload);

  set photosUploadFailed(Set<String> newValue) {
    _photosUploadFailed = newValue;
    notifyListeners();
  }

  Set<String> get photosUploadFailed => Set<String>.from(_photosUploadFailed);

  Future<void> loadDataFromCache(BuildContext context) async {
    await PhotoprismCommonHelper.getCachedDataFromSharedPrefs(context);
    _dataFromCacheLoaded = true;
    notifyListeners();
  }

  bool get dataFromCacheLoaded => _dataFromCacheLoaded;

  void notify() => notifyListeners();

  Future<void> updatePhotosSubscription() async {
    print('updatePhotosSubscription');
    if (database == null) {
      return;
    }
    if (photosStreamSubscription != null) {
      await photosStreamSubscription.cancel();
    }
    final Stream<int> photosStream =
        database.photosWithFileCount(filterPhotos, albumUid: albumUid);
    photosStreamSubscription = photosStream.listen((int value) {
      print('got photo update from database count: ' + value.toString());
      photos ??= PhotosFromDb(this);
      if (photos.length == 0 && value == 0) {
        print('ignoring photo update because nothing changed');
        return;
      }
      photos.count = value;
      notifyListeners();
    });
  }

  Future<void> updateAlbumsSubscription() async {
    print('updateAlbumsSubscription');
    if (database == null) {
      return;
    }
    if (albumsStreamSubscription != null) {
      await albumsStreamSubscription.cancel();
    }
    if (albumCountsStreamSubscription != null) {
      await albumCountsStreamSubscription.cancel();
    }
    final Stream<List<Album>> albumsStream = database.allAlbums;
    albumsStreamSubscription = albumsStream.listen((List<Album> value) {
      print('got album update from database count: ' + value.length.toString());
      albums = value;
      notifyListeners();
    });
    final Stream<Map<String, int>> albumCountsStream =
        database.allAlbumCounts();
    albumCountsStreamSubscription =
        albumCountsStream.listen((Map<String, int> value) {
      print('got albumCount update from database count: ' +
          value.length.toString());
      albumCounts = value;
      notifyListeners();
    });
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    print('closing database');
    await database.close();
  }
}

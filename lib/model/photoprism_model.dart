import 'dart:async';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/common/photoprism_auth.dart';
import 'package:photoprism/common/photoprism_remote_config_loader.dart';
import 'package:photoprism/common/photoprism_loading_screen.dart';
import 'package:photoprism/common/photoprism_message.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/dbtimestamps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:photoprism/api/api.dart';

class PhotoprismModel extends ChangeNotifier {
  PhotoprismModel() {
    initialize();
  }
  // general
  String photoprismUrl = 'https://demo.photoprism.org';
  Config config;
  Lock photoLoadingLock = Lock();
  Lock albumLoadingLock = Lock();
  bool _dataFromCacheLoaded = false;
  List<String> log;
  MyDatabase database;
  StreamSubscription<List<PhotoWithFile>> photosStreamSubscription;
  List<PhotoWithFile> photos;
  StreamSubscription<List<Album>> albumsStreamSubscription;
  List<Album> albums;
  StreamSubscription<Map<String, int>> albumCountsStreamSubscription;
  Map<String, int> albumCounts;
  DbTimestamps dbTimestamps;
  bool ascending = false;
  String albumUid;

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
    loadLog();
    photoprismLoadingScreen = PhotoprismLoadingScreen(this);
    photoprismRemoteConfigLoader = PhotoprismRemoteSettingsLoader(this);
    photoprismCommonHelper = PhotoprismCommonHelper(this);
    photoprismMessage = PhotoprismMessage(this);

    photoprismAuth = PhotoprismAuth(this);

    await photoprismCommonHelper.loadPhotoprismUrl();
    await photoprismAuth.initialize();

    // uploader needs photoprismAuth to be initialized
    photoprismUploader = PhotoprismUploader(this);

    photoprismRemoteConfigLoader.loadApplicationColor();
    gridController.addListener(notifyListeners);

    database = MyDatabase();

    updatePhotosSubscription();
    updateAlbumsSubscription();

    dbTimestamps = await DbTimestamps.fromSharedPrefs();
    await Api.updateDb(this);
  }

  Future<void> resetDatabase() async {
    await database.close();
    await database.deleteDatabase();
    database = MyDatabase();
    updatePhotosSubscription();
    updateAlbumsSubscription();
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

  void updatePhotosSubscription() {
    if (photosStreamSubscription != null) {
      photosStreamSubscription.cancel();
    }
    final Stream<List<PhotoWithFile>> photosStream =
        database.photosWithFile(ascending, albumUid: albumUid);
    photosStreamSubscription = photosStream.listen((List<PhotoWithFile> value) {
      print('got photo update from database');
      photos = value;
      notifyListeners();
    });
  }

  void updateAlbumsSubscription() {
    if (albumsStreamSubscription != null) {
      albumsStreamSubscription.cancel();
    }
    if (albumCountsStreamSubscription != null) {
      albumCountsStreamSubscription.cancel();
    }
    final Stream<List<Album>> albumsStream = database.allAlbums;
    albumsStreamSubscription = albumsStream.listen((List<Album> value) {
      print('got album update from database');
      albums = value;
      notifyListeners();
    });
    final Stream<Map<String, int>> albumCountsStream =
        database.allAlbumCounts();
    albumCountsStreamSubscription =
        albumCountsStream.listen((Map<String, int> value) {
      print('got albumCount update from database');
      albumCounts = value;
      notifyListeners();
    });
  }
}

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/photoprism_auth.dart';
import 'package:photoprism/common/photoprism_remote_config_loader.dart';
import 'package:photoprism/common/photoprism_loading_screen.dart';
import 'package:photoprism/common/photoprism_message.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';

class PhotoprismModel extends ChangeNotifier {
  PhotoprismModel() {
    initialize();
  }
  // general
  String photoprismUrl = 'https://demo.photoprism.org';
  Config config;
  List<MomentsTime> momentsTime;
  Map<int, Photo> photos;
  Map<int, Album> albums;
  Map<int, Photo> videos = <int, Photo>{};
  Lock photoLoadingLock = Lock();
  Lock albumLoadingLock = Lock();
  bool _dataFromCacheLoaded = false;
  List<String> log;

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
    notifyListeners();
  }

  void setMomentsTime(List<MomentsTime> newValue) {
    momentsTime = newValue;
    notifyListeners();
  }

  void setPhotos(Map<int, Photo> newValue) {
    photos = newValue;
    notifyListeners();
  }

  void setAlbums(Map<int, Album> newValue, {bool notify = true}) {
    albums = newValue;
    if (notify) {
      notifyListeners();
    }
  }

  void setVideos(Map<int, Photo> newValue) {
    videos = newValue;
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
}

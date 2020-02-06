import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/photoprism_http_basic_auth.dart';
import 'package:photoprism/common/photoprism_remote_config_loader.dart';
import 'package:photoprism/common/photoprism_loading_screen.dart';
import 'package:photoprism/common/photoprism_message.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:synchronized/synchronized.dart';

class PhotoprismModel extends ChangeNotifier {
  PhotoprismModel() {
    initialize();
  }
  // general
  String photoprismUrl = 'https://demo.photoprism.org';
  List<MomentsTime> momentsTime;
  Map<int, Photo> photos;
  Map<int, Album> albums;
  Lock photoLoadingLock = Lock();
  Lock albumLoadingLock = Lock();
  bool _dataFromCacheLoaded = false;

  // theming
  String applicationColor = '#424242';

  // photoprism uploader
  bool autoUploadEnabled = false;
  String autoUploadFolder = '/storage/emulated/0/DCIM/Camera';
  String autoUploadLastTimeCheckedForPhotos = 'Never';
  List<String> _photosToUpload = <String>[];
  List<String> _alreadyUploadedPhotos = <String>[];

  // runtime data
  bool isLoading = false;
  int selectedPageIndex = 0;
  DragSelectGridViewController gridController = DragSelectGridViewController();
  ScrollController scrollController = ScrollController();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;
  BuildContext context;

  // helpers
  PhotoprismUploader photoprismUploader;
  PhotoprismRemoteConfigLoader photoprismRemoteConfigLoader;
  PhotoprismCommonHelper photoprismCommonHelper;
  PhotoprismLoadingScreen photoprismLoadingScreen;
  PhotoprismMessage photoprismMessage;
  PhotoprismHttpBasicAuth photoprismHttpBasicAuth;

  Future<void> initialize() async {
    photoprismLoadingScreen = PhotoprismLoadingScreen(this);
    photoprismUploader = PhotoprismUploader(this);
    photoprismRemoteConfigLoader = PhotoprismRemoteConfigLoader(this);
    photoprismCommonHelper = PhotoprismCommonHelper(this);
    photoprismMessage = PhotoprismMessage(this);
    photoprismHttpBasicAuth = PhotoprismHttpBasicAuth(this);

    await photoprismCommonHelper.loadPhotoprismUrl();
    await photoprismHttpBasicAuth.initialized;
    photoprismRemoteConfigLoader.loadApplicationColor();
    gridController.addListener(notifyListeners);
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

  set alreadyUploadedPhotos(List<String> newValue) {
    _alreadyUploadedPhotos = newValue;
    notifyListeners();
  }

  List<String> get alreadyUploadedPhotos =>
      List<String>.from(_alreadyUploadedPhotos);

  set photosToUpload(List<String> newValue) {
    _photosToUpload = newValue;
    notifyListeners();
  }

  List<String> get photosToUpload => List<String>.from(_photosToUpload);

  Future<void> loadDataFromCache(BuildContext context) async {
    await PhotoprismCommonHelper.getCachedDataFromSharedPrefs(context);
    _dataFromCacheLoaded = true;
    notifyListeners();
  }

  bool get dataFromCacheLoaded => _dataFromCacheLoaded;

  void notify() => notifyListeners();
}

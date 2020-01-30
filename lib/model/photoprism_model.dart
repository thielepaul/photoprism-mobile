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
import 'package:synchronized/synchronized.dart';

import 'moments_time.dart';

class PhotoprismModel extends ChangeNotifier {
  // general
  String photoprismUrl = "https://demo.photoprism.org";
  List<MomentsTime> momentsTime = [];
  Map<int, Photo> photos = {};
  Map<int, Album> albums = {};
  Lock photoLoadingLock = Lock();
  Lock albumLoadingLock = Lock();

  // theming
  String applicationColor = "#424242";

  // photoprism uploader
  bool autoUploadEnabled = false;
  String autoUploadFolder = "/storage/emulated/0/DCIM/Camera";
  String autoUploadLastTimeCheckedForPhotos = "Never";
  List<String> photosToUpload = [];

  // runtime data
  bool isLoading = false;
  int selectedPageIndex = 0;
  DragSelectGridViewController gridController = DragSelectGridViewController();
  PhotoViewScaleState photoViewScaleState = PhotoViewScaleState.initial;
  BuildContext context;

  // helpers
  PhotoprismUploader photoprismUploader;
  PhotoprismRemoteConfigLoader photoprismRemoteConfigLoader;
  PhotoprismCommonHelper photoprismCommonHelper;
  PhotoprismLoadingScreen photoprismLoadingScreen;
  PhotoprismMessage photoprismMessage;
  PhotoprismHttpBasicAuth photoprismHttpBasicAuth;

  PhotoprismModel() {
    initialize();
  }

  initialize() async {
    photoprismUploader = new PhotoprismUploader(this);
    photoprismRemoteConfigLoader = new PhotoprismRemoteConfigLoader(this);
    photoprismCommonHelper = new PhotoprismCommonHelper(this);
    photoprismLoadingScreen = new PhotoprismLoadingScreen(this);
    photoprismMessage = new PhotoprismMessage(this);
    photoprismHttpBasicAuth = new PhotoprismHttpBasicAuth(this);

    await photoprismCommonHelper.loadPhotoprismUrl();
    await photoprismHttpBasicAuth.initialized;
    photoprismRemoteConfigLoader.loadApplicationColor();
    // TODO: load if necessary
    // PhotosPage.loadPhotosFromNetworkOrCache(this, photoprismUrl, "");
    // Api.loadMomentsTime(this);
    // AlbumsPage.loadAlbumsFromNetworkOrCache(this, photoprismUrl);
    gridController.addListener(notifyListeners);
  }

  setMomentsTime(List<MomentsTime> newValue) {
    momentsTime = newValue;
    notifyListeners();
  }

  setPhotos(Map<int, Photo> newValue) {
    photos = newValue;
    notifyListeners();
  }

  setAlbums(Map<int, Album> newValue) {
    albums = newValue;
    notifyListeners();
  }

  void notify() => notifyListeners();
}

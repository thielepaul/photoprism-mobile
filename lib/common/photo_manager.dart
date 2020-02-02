import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/widgets.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:provider/provider.dart';

class PhotoManager {
  const PhotoManager();

  static Map<int, Photo> getPhotos(BuildContext context, int albumId) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (albumId == null && model.photos != null) {
      return model.photos;
    }
    if (model.albums != null && model.albums[albumId] != null) {
      return model.albums[albumId].photos;
    }
    return {};
  }

  static Future<void> saveAndSetPhotos(
      BuildContext context, Map<int, Photo> photos, int albumId) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (albumId == null) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs('photos',
          photos.map((key, value) => MapEntry(key.toString(), value)));
      model.setPhotos(photos);
      return;
    }
    if (model.albums != null && model.albums[albumId] != null) {
      model.albums[albumId].photos = photos;
      await AlbumManager.saveAndSetAlbums(context, model.albums);
      return;
    }
  }

  static void archivePhotos(
      BuildContext context, List<String> photoUUIDs, int albumId) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    model.photoprismLoadingScreen.showLoadingScreen("Archive photos..");
    var status = await Api.archivePhotos(photoUUIDs, model);
    if (status == 0) {
      model.gridController.selection = Selection({});
      await PhotoManager.loadMomentsTime(context, forceReload: true);
      model.photoprismLoadingScreen.hideLoadingScreen();
    } else {
      model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Archiving photos failed.");
    }
  }

  static Future<void> saveAndSetMomentsTime(
      BuildContext context, List<MomentsTime> moments) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
        "momentsTime", moments);
    model.setMomentsTime(moments);
  }

  static int getPhotosCount(BuildContext context, int albumId) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (albumId == null && model.momentsTime != null) {
      return model.momentsTime.map((v) => v.count).reduce((v, e) => v + e);
    }
    if (model.albums != null && model.albums[albumId] != null) {
      return model.albums[albumId].imageCount;
    }
    return 0;
  }

  static List<MomentsTime> getCummulativeMonthCount(BuildContext context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<MomentsTime> cummulativeMonthCount = [];
    if (model.momentsTime == null) {
      return cummulativeMonthCount;
    }
    model.momentsTime.forEach((v) {
      MomentsTime m = MomentsTime(year: v.year, month: v.month, count: v.count);
      if (cummulativeMonthCount.length > 0) {
        m.count += cummulativeMonthCount.last.count;
      }
      cummulativeMonthCount.add(m);
    });
    return cummulativeMonthCount;
  }

  static Future<void> loadMomentsTime(BuildContext context,
      {bool forceReload = false}) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    await model.photoLoadingLock.synchronized(() async {
      if (model.momentsTime != null && !forceReload) {
        return;
      }
      List<MomentsTime> momentsTime = await Api.loadMomentsTime(context);
      await saveAndSetMomentsTime(context, momentsTime);
    });
    if (model.selectedPageIndex == 0) {
      print("reload photos");
      await loadPhoto(context, getPhotoIndexInScrollView(context, null), null,
          forceReload: true);
    } else {
      await saveAndSetPhotos(context, {}, null);
    }
    return;
  }

  static Future<void> loadPhoto(BuildContext context, int index, int albumId,
      {bool forceReload = false}) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    return await model.photoLoadingLock.synchronized(() async {
      // early stop in case an old request wants a photo that has been removed
      if (albumId != null &&
          model.albums != null &&
          model.albums[albumId] != null &&
          index >= model.albums[albumId].imageCount) {
        return;
      }
      if (getPhotos(context, albumId).containsKey(index) && !forceReload) {
        return;
      }
      int offset = index - (index % 100);
      Map<int, Photo> photos;
      if (forceReload) {
        photos = {};
      } else {
        photos = getPhotos(context, albumId);
      }
      photos.addAll(await Api.loadPhotos(context, albumId, offset));
      saveAndSetPhotos(context, photos, albumId);
      return;
    });
  }

  static String getPhotoThumbnailUrl(
      BuildContext context, int index, int albumId) {
    if (getPhotos(context, albumId)[index] == null) {
      return null;
    }
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    String filehash = PhotoManager.getPhotos(context, albumId)[index].fileHash;
    return model.photoprismUrl + '/api/v1/thumbnails/' + filehash + '/tile_224';
  }

  static int getPhotoIndexInScrollView(BuildContext context, int albumId) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    try {
      double currentPhoto = PhotoManager.getPhotosCount(context, albumId) *
          model.scrollController.offset /
          (model.scrollController.position.maxScrollExtent -
              model.scrollController.position.minScrollExtent);
      if (currentPhoto.isNaN || currentPhoto.isInfinite) {
        return 0;
      }
      return currentPhoto.floor();
    } catch (_) {
      return 0;
    }
  }
}

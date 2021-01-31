import 'package:flutter/widgets.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo_old.dart' as photo_old;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:provider/provider.dart';

class PhotoManager {
  const PhotoManager();

  static Map<int, photo_old.Photo> getPhotos(
      BuildContext context, int albumId, bool videosPage) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (videosPage) {
      return model.videos;
    }
    if (albumId == null && model.photosOld != null) {
      return model.photosOld;
    }
    if (model.albums != null && model.albums[albumId] != null) {
      return model.albums[albumId].photos;
    }
    return <int, photo_old.Photo>{};
  }

  static Future<void> saveAndSetPhotos(BuildContext context,
      Map<int, photo_old.Photo> photos, int albumId, bool videosPage) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (videosPage) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
          'videos',
          photos.map((int key, photo_old.Photo value) =>
              MapEntry<String, photo_old.Photo>(key.toString(), value)));
      model.setVideos(photos);
      return;
    }
    if (albumId == null) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
          'photos',
          photos.map((int key, photo_old.Photo value) =>
              MapEntry<String, photo_old.Photo>(key.toString(), value)));
      model.setPhotos(photos);
      return;
    }
    if (model.albums != null && model.albums[albumId] != null) {
      model.albums[albumId].photos = photos;
      await AlbumManager.saveAndSetAlbums(context, model.albums);
      return;
    }
  }

  static Future<void> archivePhotos(
      BuildContext context, List<String> photoUUIDs) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    model.photoprismLoadingScreen.showLoadingScreen('Archive photos..');
    final int status = await Api.archivePhotos(photoUUIDs, model);
    if (status == 0) {
      model.gridController.clear();
      await PhotoManager.loadMomentsTime(context, forceReload: true);
      model.photoprismLoadingScreen.hideLoadingScreen();
    } else {
      model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage('Archiving photos failed.');
    }
  }

  static Future<void> saveAndSetMomentsTime(
      BuildContext context, List<MomentsTime> moments) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
        'momentsTime', moments);
    model.setMomentsTime(moments);
  }

  static int getPhotosCount(
      BuildContext context, int albumId, bool videosPage) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (videosPage) {
      if (model.config != null) {
        return model.config.countVideos;
      }
      return 0;
    }
    if (albumId == null &&
        model.momentsTime != null &&
        model.momentsTime.isNotEmpty) {
      return model.momentsTime
          .map((MomentsTime v) => v.count)
          .reduce((int v, int e) => v + e);
    }
    if (model.albums != null && model.albums[albumId] != null) {
      return model.albums[albumId].imageCount;
    }
    return 0;
  }

  static List<MomentsTime> getCummulativeMonthCount(BuildContext context) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final List<MomentsTime> cummulativeMonthCount = <MomentsTime>[];
    if (model.momentsTime == null) {
      return cummulativeMonthCount;
    }
    for (final MomentsTime v in model.momentsTime) {
      final MomentsTime m =
          MomentsTime(year: v.year, month: v.month, count: v.count);
      if (cummulativeMonthCount.isNotEmpty) {
        m.count += cummulativeMonthCount.last.count;
      }
      cummulativeMonthCount.add(m);
    }
    return cummulativeMonthCount;
  }

  static Future<void> loadMomentsTime(BuildContext context,
      {bool forceReload = false}) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    await model.photoLoadingLock.synchronized(() async {
      if (model.momentsTime != null && !forceReload) {
        return;
      }
      final List<MomentsTime> momentsTime = await Api.loadMomentsTime(context);
      await saveAndSetMomentsTime(context, momentsTime);
    });
    if (model.selectedPageIndex == PageIndex.Photos) {
      print('reload photos');
    } else {
      await saveAndSetPhotos(context, <int, photo_old.Photo>{}, null, false);
    }
    return;
  }

  static String getPhotoThumbnailUrl(
      BuildContext context, int index, int albumId, bool videosPage) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    if (model.config == null) {
      return null;
    }
    final String filehash = model.photos[index].file.hash;
    return model.photoprismUrl +
        '/api/v1/t/' +
        filehash +
        '/' +
        model.config.previewToken +
        '/tile_224';
  }

  static int getPhotoIndexInScrollView(BuildContext context, int albumId) {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    try {
      final double currentPhoto =
          PhotoManager.getPhotosCount(context, albumId, false) *
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

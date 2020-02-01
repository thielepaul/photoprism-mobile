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
    if (albumId == null) {
      return model.photos;
    }
    if (model.albums[albumId] != null) {
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
    if (model.albums[albumId] != null) {
      model.albums[albumId].photos = photos;
      await AlbumManager.saveAndSetAlbums(context, model.albums);
      return;
    }
  }

  static Future<void> resetPhotos(BuildContext context, int albumId) async {
    await saveAndSetPhotos(context, {}, albumId);
  }

  static void archivePhotos(
      BuildContext context, List<String> photoUUIDs, int albumId) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    var status = await Api.archivePhotos(photoUUIDs, model);
    if (status == 0) {
      model.gridController.selection = Selection({});
      PhotoManager.resetPhotos(context, albumId);
    } else {
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
    if (albumId == null) {
      return model.momentsTime.map((v) => v.count).reduce((v, e) => v + e);
    }
    if (model.albums[albumId] != null) {
      return model.albums[albumId].imageCount;
    }
    return 0;
  }

  static List<MomentsTime> getCummulativeMonthCount(BuildContext context) {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    List<MomentsTime> cummulativeMonthCount = [];
    model.momentsTime.forEach((v) {
      MomentsTime m = MomentsTime(year: v.year, month: v.month, count: v.count);
      if (cummulativeMonthCount.length > 0) {
        m.count += cummulativeMonthCount.last.count;
      }
      cummulativeMonthCount.add(m);
    });
    return cummulativeMonthCount;
  }

  static Future<void> loadPhoto(
      BuildContext context, int index, int albumId) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return await model.photoLoadingLock.synchronized(() async {
      if (getPhotos(context, albumId).containsKey(index)) {
        return;
      }
      int offset = index - (index % 100);
      Map<int, Photo> photos = getPhotos(context, albumId);
      photos.addAll(await Api.loadPhotos(context, albumId, offset));
      saveAndSetPhotos(context, photos, albumId);
      return;
    });
  }

  static String getPhotoUrl(BuildContext context, int index, int albumId) {
    if (getPhotos(context, albumId)[index] == null) {
      return null;
    }
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    String filehash = PhotoManager.getPhotos(context, albumId)[index].fileHash;
    return model.photoprismUrl + '/api/v1/thumbnails/' + filehash + '/tile_224';
  }
}

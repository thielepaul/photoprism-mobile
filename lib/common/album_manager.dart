import 'package:flutter/widgets.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumManager {
  static Future<void> saveAndSetAlbums(
      BuildContext context, Map<int, Album> albums,
      {bool notify = true}) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
        'albums',
        albums.map<String, Album>((int key, Album value) =>
            MapEntry<String, Album>(key.toString(), value)));
    for (final int albumId in albums.keys) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
          'photos' + albumId.toString(),
          albums[albumId].photos.map<String, Photo>((int key, Photo value) =>
              MapEntry<String, Photo>(key.toString(), value)));
    }
    model.setAlbums(albums, notify: notify);
  }

  static Future<void> addPhotosToAlbum(
      BuildContext context, int albumId, List<String> photoUUIDs) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    print('Adding photos to album ' + model.albums[albumId].id);
    model.photoprismLoadingScreen.showLoadingScreen('Adding photos to album..');
    final int status =
        await Api.addPhotosToAlbum(model.albums[albumId].id, photoUUIDs, model);

    if (status == 0) {
      final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      await loadAlbums(context, 0, forceReload: true);
      await PhotoManager.saveAndSetPhotos(context, <int, Photo>{}, albumId);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage
          .showMessage('Adding photos to album successfull.');
    } else {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage('Adding photos to album failed.');
    }
  }

  static Future<void> loadAlbums(BuildContext context, int offset,
      {bool forceReload = false, int loadPhotosForAlbumId}) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    await model.albumLoadingLock.synchronized(() async {
      if (model.albums != null && !forceReload) {
        return;
      }
      final Map<int, Album> albums = await Api.loadAlbums(context, offset);
      return await saveAndSetAlbums(context, albums,
          notify: loadPhotosForAlbumId == null);
    });
    if (loadPhotosForAlbumId != null) {
      return PhotoManager.loadPhoto(
          context,
          PhotoManager.getPhotoIndexInScrollView(context, loadPhotosForAlbumId),
          loadPhotosForAlbumId,
          forceReload: true);
    }
    return;
  }
}

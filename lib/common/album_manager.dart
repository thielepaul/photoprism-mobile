import 'package:flutter/widgets.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photo_old.dart' as photo_old;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumManager {
  static Future<void> saveAndSetAlbums(
      BuildContext context, Map<int, AlbumOld> albums,
      {bool notify = true}) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
        'albums',
        albums.map<String, AlbumOld>((int key, AlbumOld value) =>
            MapEntry<String, AlbumOld>(key.toString(), value)));
    for (final int albumId in albums.keys) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
          'photos' + albumId.toString(),
          albums[albumId].photos.map<String, photo_old.Photo>(
              (int key, photo_old.Photo value) =>
                  MapEntry<String, photo_old.Photo>(key.toString(), value)));
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
      await PhotoManager.saveAndSetPhotos(
          context, <int, photo_old.Photo>{}, albumId, false);
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
      final Map<int, AlbumOld> albums = await Api.loadAlbums(context, offset);
      return await saveAndSetAlbums(context, albums,
          notify: loadPhotosForAlbumId == null);
    });
    if (loadPhotosForAlbumId != null) {}
    return;
  }
}

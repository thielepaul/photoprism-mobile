import 'package:flutter/widgets.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumManager {
  static Future<void> saveAndSetAlbums(
      BuildContext context, Map<int, Album> albums) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
        'albums', albums.map((key, value) => MapEntry(key.toString(), value)));
    for (int albumId in albums.keys) {
      await PhotoprismCommonHelper.saveAsJsonToSharedPrefs(
          'photos' + albumId.toString(),
          albums[albumId]
              .photos
              .map((key, value) => MapEntry(key.toString(), value)));
    }
    model.setAlbums(albums);
  }

  static Future<void> resetAlbums(BuildContext context) async {
    await saveAndSetAlbums(context, {});
  }

  static void addPhotosToAlbum(
      BuildContext context, albumId, List<String> photoUUIDs) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    print("Adding photos to album " + albumId);
    model.photoprismLoadingScreen.showLoadingScreen("Adding photos to album..");
    var status = await Api.addPhotosToAlbum(albumId, photoUUIDs, model);

    if (status == 0) {
      PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      await resetAlbums(context);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage
          .showMessage("Adding photos to album successfull.");
    } else {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Adding photos to album failed.");
    }
  }

  static Future<void> loadAlbums(BuildContext context, offset) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    return await model.albumLoadingLock.synchronized(() async {
      if (model.albums.length != 0) {
        return;
      }
      Map<int, Album> albums = model.albums;
      albums.addAll(await Api.loadAlbums(context, offset));
      saveAndSetAlbums(context, albums);
      return;
    });
  }
}

import 'package:flutter/widgets.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/photoprism_common_helper.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class AlbumManager {
  static Future<void> saveAndSetAlbums(
      BuildContext context, Map<String, Album> albums) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    await PhotoprismCommonHelper.saveAsJsonToSharedPrefs('albums', albums);
    model.setAlbums(albums);
  }

  static Future<void> resetAlbums(BuildContext context) async {
    await saveAndSetAlbums(context, {});
  }

  static void createAlbum(BuildContext context) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    print("Creating new album");
    model.photoprismLoadingScreen.showLoadingScreen("Creating new album..");
    String status = await Api.createAlbum('New album', model);

    if (status == "-1") {
      PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Creating album failed.");
    } else {
      await resetAlbums(context);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Album created successfully.");
    }
  }

  static void renameAlbum(BuildContext context, String albumId,
      String oldAlbumName, String newAlbumName) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    if (oldAlbumName != newAlbumName) {
      PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      print("Renaming album " + oldAlbumName + " to " + newAlbumName);
      model.photoprismLoadingScreen.showLoadingScreen("Renaming album..");
      var status = await Api.renameAlbum(albumId, newAlbumName, model);

      if (status == 0) {
        PhotoprismModel model = Provider.of<PhotoprismModel>(context);
        await resetAlbums(context);
        PhotoManager.resetPhotos(context, albumId);
        await model.photoprismLoadingScreen.hideLoadingScreen();
        model.photoprismMessage.showMessage("Renaming album successfully.");
      } else {
        await model.photoprismLoadingScreen.hideLoadingScreen();
        model.photoprismMessage.showMessage("Renaming album failed.");
      }
    } else {
      print("Renaming skipped: New and old album name identical.");
      model.photoprismMessage
          .showMessage("Renaming skipped: New and old album name identical.");
    }
  }

  static void deleteAlbum(BuildContext context, String albumId) async {
    PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    print("Deleting album " + albumId);
    model.photoprismLoadingScreen.showLoadingScreen("Deleting album..");
    var status = await Api.deleteAlbum(albumId, model);

    if (status == 0) {
      PhotoprismModel model = Provider.of<PhotoprismModel>(context);
      await resetAlbums(context);
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Album deleted successfully.");
    } else {
      await model.photoprismLoadingScreen.hideLoadingScreen();
      model.photoprismMessage.showMessage("Deleting album failed.");
    }
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
}

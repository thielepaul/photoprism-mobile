import 'package:photoprism/api/albums.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/photoprism_model.dart';

class PhotoprismAlbumManager {
  PhotoprismModel photoprismModel;

  PhotoprismAlbumManager(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void createAlbum() async {
    print("Creating new album");
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Creating new album..");
    var status =
        await Api.createAlbum('New album', photoprismModel.photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(photoprismModel, photoprismModel.photoprismUrl);
    } else {
      // error
    }
    photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
  }

  void renameAlbum(
      String albumId, String oldAlbumName, String newAlbumName) async {
    if (oldAlbumName != newAlbumName) {
      print("Renaming album " + oldAlbumName + " to " + newAlbumName);
      photoprismModel.photoprismLoadingScreen
          .showLoadingScreen("Renaming album..");
      var status = await Api.renameAlbum(
          albumId, newAlbumName, photoprismModel.photoprismUrl);

      if (status == 0) {
        Albums.loadAlbums(photoprismModel, photoprismModel.photoprismUrl);
        Photos.loadPhotos(
            photoprismModel, photoprismModel.photoprismUrl, albumId);
      } else {
        // error
      }
      photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
    } else {
      print("Renaming skipped: New and old album name identical.");
    }
  }

  void deleteAlbum(String albumId) async {
    print("Deleting album " + albumId);
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Deleting album..");
    var status = await Api.deleteAlbum(albumId, photoprismModel.photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(photoprismModel, photoprismModel.photoprismUrl);
      photoprismModel.photoprismMessage
          .showMessage("Album deleted successfully.");
    } else {
      // error
    }
    photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
  }

  void addPhotosToAlbum(albumId, List<String> photoUUIDs) async {
    print("Adding photos to album " + albumId);
    photoprismModel.photoprismLoadingScreen
        .showLoadingScreen("Adding photos to album..");
    var status = await Api.addPhotosToAlbum(
        albumId, photoUUIDs, photoprismModel.photoprismUrl);

    if (status == 0) {
      await Albums.loadAlbums(photoprismModel, photoprismModel.photoprismUrl);
    } else {
      // error
    }
    photoprismModel.photoprismLoadingScreen.hideLoadingScreen();
  }
}

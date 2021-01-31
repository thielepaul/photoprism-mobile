// import 'dart:convert';

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/photo_manager.dart';
import 'package:photoprism/common/album_manager.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo_old.dart' as photo_old;
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismCommonHelper {
  PhotoprismCommonHelper(this.photoprismModel);
  final PhotoprismModel photoprismModel;

  static Future<void> saveAsJsonToSharedPrefs(String key, dynamic data) async {
    print('saveToSharedPrefs: key: ' + key);
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, json.encode(data));
  }

  static Future<void> getCachedDataFromSharedPrefs(BuildContext context) async {
    print('getDataFromSharedPrefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    if (sp.containsKey('photos')) {
      try {
        final Map<int, photo_old.Photo> photos = json
                .decode(sp.getString('photos'))
                .map<int, photo_old.Photo>((String key, dynamic value) =>
                    MapEntry<int, photo_old.Photo>(
                        int.parse(key),
                        photo_old.Photo.fromJson(
                            value as Map<String, dynamic>)))
            as Map<int, photo_old.Photo>;
        PhotoManager.saveAndSetPhotos(context, photos, null, false);
      } catch (_) {
        sp.remove('photos');
      }
    }

    if (sp.containsKey('momentsTime')) {
      try {
        final List<MomentsTime> momentsTime = json
            .decode(sp.getString('momentsTime'))
            .map<MomentsTime>((dynamic value) =>
                MomentsTime.fromJson(value as Map<String, dynamic>))
            .toList() as List<MomentsTime>;
        PhotoManager.saveAndSetMomentsTime(context, momentsTime);
      } catch (_) {
        sp.remove('momentsTime');
      }
    }

    if (sp.containsKey('albums')) {
      Map<int, Album> albums;
      try {
        albums = json.decode(sp.getString('albums')).map<int, Album>(
                (String key, dynamic value) => MapEntry<int, Album>(
                    int.parse(key),
                    Album.fromJson(value as Map<String, dynamic>)))
            as Map<int, Album>;
      } catch (_) {
        sp.remove('albums');
      }
      for (final int albumId in albums.keys) {
        if (sp.containsKey('photos' + albumId.toString())) {
          try {
            albums[albumId].photos = json
                    .decode(sp.getString('photos' + albumId.toString()))
                    .map<int, photo_old.Photo>((String key, dynamic value) =>
                        MapEntry<int, photo_old.Photo>(
                            int.parse(key),
                            photo_old.Photo.fromJson(
                                value as Map<String, dynamic>)))
                as Map<int, photo_old.Photo>;
          } catch (_) {
            sp.remove('photos' + albumId.toString());
          }
        }
      }
      AlbumManager.saveAndSetAlbums(context, albums);
    }

    if (sp.containsKey('videos')) {
      try {
        final Map<int, photo_old.Photo> photos = json
                .decode(sp.getString('videos'))
                .map<int, photo_old.Photo>((String key, dynamic value) =>
                    MapEntry<int, photo_old.Photo>(
                        int.parse(key),
                        photo_old.Photo.fromJson(
                            value as Map<String, dynamic>)))
            as Map<int, photo_old.Photo>;
        PhotoManager.saveAndSetPhotos(context, photos, null, true);
      } catch (_) {
        sp.remove('videos');
      }
    }

    if (sp.containsKey('alreadyUploadedPhotos')) {
      try {
        PhotoprismUploader.saveAndSetAlreadyUploadedPhotos(
            model, sp.getStringList('alreadyUploadedPhotos').toSet());
      } catch (_) {
        sp.remove('alreadyUploadedPhotos');
      }
    }

    if (sp.containsKey('photosUploadFailed')) {
      try {
        PhotoprismUploader.saveAndSetPhotosUploadFailed(
            model, sp.getStringList('photosUploadFailed').toSet());
      } catch (_) {
        sp.remove('photosUploadFailed');
      }
    }

    if (sp.containsKey('albumsToUpload')) {
      try {
        PhotoprismUploader.saveAndSetAlbumsToUpload(
            model, sp.getStringList('albumsToUpload').toSet());
      } catch (_) {
        sp.remove('albumsToUpload');
      }
    }

    if (sp.containsKey('config')) {
      try {
        model.config = Config.fromJson(
            json.decode(sp.getString('config')) as Map<String, dynamic>);
      } catch (_) {
        sp.remove('config');
      }
    }
  }

  Future<void> loadPhotoprismUrl() async {
    // load photoprism url from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String photoprismUrl = prefs.getString('url');
    if (photoprismUrl != null) {
      photoprismModel.photoprismUrl = photoprismUrl;
    }
  }

  Future<void> savePhotoprismUrlToPrefs(String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('url', url);
  }

  void setSelectedPageIndex(PageIndex index) {
    photoprismModel.selectedPageIndex = index;
    photoprismModel.notify();
  }

  Future<void> setPhotoprismUrl(String url) async {
    await savePhotoprismUrlToPrefs(url);
    photoprismModel.photoprismUrl = url;
    photoprismModel.notify();
  }

  void setPhotoViewScaleState(PhotoViewScaleState scaleState) {
    photoprismModel.photoViewScaleState = scaleState;
    photoprismModel.notify();
  }
}

// import 'dart:convert';

import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photoprism/common/photoprism_uploader.dart';
import 'package:photoprism/main.dart';
import 'package:photoprism/model/config.dart';
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
    final PhotoprismModel model =
        Provider.of<PhotoprismModel>(context, listen: false);

    if (sp.containsKey('albumsToUpload')) {
      try {
        PhotoprismUploader.saveAndSetAlbumsToUpload(
            model, sp.getStringList('albumsToUpload')!.toSet());
      } catch (_) {
        sp.remove('albumsToUpload');
      }
    }

    if (sp.containsKey('config')) {
      try {
        model.config = Config.fromJson(
            json.decode(sp.getString('config')!) as Map<String, dynamic>);
      } catch (_) {
        sp.remove('config');
      }
    }

    if (sp.containsKey('theme_mode')) {
      try {
        model.themeMode = EnumToString.fromString<ThemeMode>(
            ThemeMode.values, sp.getString('theme_mode')!);
      } catch (_) {
        sp.remove('theme_mode');
      }
    }
  }

  Future<void> loadPhotoprismUrl() async {
    // load photoprism url from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? photoprismUrl = prefs.getString('url');
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

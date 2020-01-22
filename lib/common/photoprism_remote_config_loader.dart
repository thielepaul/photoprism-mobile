import 'dart:convert';

import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class PhotoprismRemoteConfigLoader {
  PhotoprismModel photoprismModel;

  PhotoprismRemoteConfigLoader(PhotoprismModel photoprismModel) {
    this.photoprismModel = photoprismModel;
  }

  void loadApplicationColor() async {
    // try to load application color from shared preference
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String applicationColor = prefs.getString("applicationColor");
    if (applicationColor != null) {
      print("loading color scheme from cache");
      photoprismModel.applicationColor = applicationColor;
      photoprismModel.notify();
    }

    // load color scheme from server
    try {
      http.Response response = await http.get(
          photoprismModel.photoprismUrl + '/api/v1/settings',
          headers: photoprismModel.photoprismHttpBasicAuth.getAuthHeader());

      try {
        final settingsJson = json.decode(response.body);
        final themeSetting = settingsJson["theme"];

        final themesJson = await rootBundle.loadString('assets/themes.json');
        final parsedThemes = json.decode(themesJson);

        final currentTheme = parsedThemes[themeSetting];

        photoprismModel.applicationColor = currentTheme["navigation"];

        // save new color scheme to shared preferences
        prefs.setString("applicationColor", photoprismModel.applicationColor);
        photoprismModel.notify();
      } catch (_) {
        print("Could not parse color scheme!");
      }
    } catch (_) {
      print("Could not get color scheme from server!");
    }
  }
}

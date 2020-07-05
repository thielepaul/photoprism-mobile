import 'dart:convert';

import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

class PhotoprismRemoteSettingsLoader {
  PhotoprismRemoteSettingsLoader(this.photoprismModel);
  PhotoprismModel photoprismModel;

  Future<void> loadApplicationColor() async {
    // try to load application color from shared preference
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String applicationColor = prefs.getString('applicationColor');
    if (applicationColor != null) {
      print('loading color scheme from cache');
      photoprismModel.applicationColor = applicationColor;
      photoprismModel.notify();
    }

    // load color scheme from server
    try {
      final http.Response response = await Api.httpAuth(
              photoprismModel,
              () => http.get(photoprismModel.photoprismUrl + '/api/v1/settings',
                  headers: photoprismModel.photoprismAuth.getAuthHeaders()))
          as http.Response;

      try {
        final Map<String, String> settingsJson = json
                .decode(response.body)
                .map<String, String>((String key, dynamic value) =>
                    MapEntry<String, String>(key, value.toString()))
            as Map<String, String>;
        final String themeSetting = settingsJson['theme'];

        final String themesJson =
            await rootBundle.loadString('assets/themes.json');
        final Map<String, Map<String, String>> parsedThemes = json
                .decode(themesJson)
                .map<String, Map<String, String>>((String key, dynamic value) =>
                    MapEntry<String, Map<String, String>>(
                        key,
                        (value as Map<String, dynamic>).map<String, String>(
                            (String key, dynamic value) =>
                                MapEntry<String, String>(key, value.toString()))))
            as Map<String, Map<String, String>>;

        final Map<String, String> currentTheme = parsedThemes[themeSetting];

        photoprismModel.applicationColor = currentTheme['navigation'];

        // save new color scheme to shared preferences
        prefs.setString('applicationColor', photoprismModel.applicationColor);
        photoprismModel.notify();
      } catch (_) {
        print('Could not parse color scheme!');
      }
    } catch (_) {
      print('Could not get color scheme from server!');
    }
  }
}

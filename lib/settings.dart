import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;

import 'main.dart';

class Settings {
  String theme = "";
  String settingsJson = "";
  String parsedSettingsJson = "";
  String applicationColor = "#000000";
  String photoprismURL = "";

  Future loadSettings(photoprismURL) async {
    print("loading settings..");

    try {
      http.Response response = await http.get(
          photoprismURL + '/api/v1/settings');

      final parsed = json.decode(response.body);
      this.theme = parsed["theme"];

      this.settingsJson = await rootBundle.loadString('assets/themes.json');

      final parsedSettings = json.decode(this.settingsJson);

      final a = parsedSettings[this.theme];

      print("Color: ");
      print(a["primary"]);
      this.applicationColor = a["navigation"];
    }
    catch(_) {
      // TODO: load cached color
      this.applicationColor = "#424242";
    }

    return this.applicationColor;
  }
}
import 'package:photoprism/model/photoprism_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismHttpBasicAuth {
  PhotoprismModel model;
  final FlutterSecureStorage secureStorage;
  bool enabled = false;
  String user = "";
  String password = "";

  PhotoprismHttpBasicAuth(this.model)
      : secureStorage = new FlutterSecureStorage() {
    initialize();
  }

  Future initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool enabledStored = prefs.getBool("httpBasicAuthEnabled");
    if (enabledStored != null) {
      enabled = enabledStored;
    }

    String userStored = await secureStorage.read(key: "httpBasicUser");
    if (userStored != null) {
      user = userStored;
    }

    String passwordStored = await secureStorage.read(key: "httpBasicPassword");
    if (passwordStored != null) {
      password = passwordStored;
    }

    model.notify();
  }

  Future setEnabled(bool value) async {
    enabled = value;
    model.notify();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("httpBasicAuthEnabled", enabled);
  }

  Future setUser(String userNew) async {
    user = userNew;
    model.notify();
    await secureStorage.write(key: "httpBasicUser", value: user);
  }

  Future setPassword(String passwordNew) async {
    password = passwordNew;
    model.notify();
    await secureStorage.write(key: "httpBasicPassword", value: password);
  }
}

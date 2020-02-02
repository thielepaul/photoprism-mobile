import 'dart:convert';

import 'package:photoprism/model/photoprism_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismHttpBasicAuth {
  PhotoprismHttpBasicAuth(this.model)
      : secureStorage = const FlutterSecureStorage() {
    initialized = initialize();
  }

  PhotoprismModel model;
  final FlutterSecureStorage secureStorage;
  bool enabled = false;
  String user = '';
  String password = '';
  Future<void> initialized;

  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool enabledStored = prefs.getBool('httpBasicAuthEnabled');
    if (enabledStored != null) {
      enabled = enabledStored;
    }

    final String userStored = await secureStorage.read(key: 'httpBasicUser');
    if (userStored != null) {
      user = userStored;
    }

    final String passwordStored =
        await secureStorage.read(key: 'httpBasicPassword');
    if (passwordStored != null) {
      password = passwordStored;
    }

    model.notify();
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    model.notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('httpBasicAuthEnabled', enabled);
  }

  Future<void> setUser(String userNew) async {
    user = userNew;
    model.notify();
    await secureStorage.write(key: 'httpBasicUser', value: user);
  }

  Future<void> setPassword(String passwordNew) async {
    password = passwordNew;
    model.notify();
    await secureStorage.write(key: 'httpBasicPassword', value: password);
  }

  Map<String, String> getAuthHeader() {
    if (enabled) {
      return <String, String>{
        'Authorization':
            'Basic ' + utf8.fuse(base64).encode(user + ':' + password)
      };
    }
    return <String, String>{};
  }
}

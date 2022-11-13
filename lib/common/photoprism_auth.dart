import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismAuth {
  PhotoprismAuth(this.model, this.secureStorage);

  PhotoprismModel model;
  final FlutterSecureStorage secureStorage;
  bool enabled = false;
  String user = 'admin';
  String password = '';
  String sessionId = '';
  String userId = '';
  bool httpBasicEnabled = false;
  String httpBasicUser = '';
  String httpBasicPassword = '';
  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? httpBasicEnabledStored = prefs.getBool('httpBasicAuthEnabled');
    if (httpBasicEnabledStored != null) {
      httpBasicEnabled = httpBasicEnabledStored;
    }

    final String? httpBasicUserStored =
        await secureStorage.read(key: 'httpBasicUser');
    if (httpBasicUserStored != null) {
      httpBasicUser = httpBasicUserStored;
    }

    final String? httpBasicPasswordStored =
        await secureStorage.read(key: 'httpBasicPassword');
    if (httpBasicPasswordStored != null) {
      httpBasicPassword = httpBasicPasswordStored;
    }

    final bool? enabledStored = prefs.getBool('authEnabled');
    if (enabledStored != null) {
      enabled = enabledStored;
    }

    final String? sessionTokenStored =
        await secureStorage.read(key: 'sessionToken');
    if (sessionTokenStored != null) {
      sessionId = sessionTokenStored;
    }

    final String? userIdStored = await secureStorage.read(key: 'userId');
    if (userIdStored != null) {
      userId = userIdStored;
    }

    final String? userStored = await secureStorage.read(key: 'user');
    if (userStored != null) {
      user = userStored;
    }

    final String? passwordStored = await secureStorage.read(key: 'password');
    if (passwordStored != null) {
      password = passwordStored;
    }

    _initialized = true;
    await apiGetNewSession(model);
  }

  Future<void> setHttpBasicEnabled(bool value) async {
    httpBasicEnabled = value;
    model.notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('httpBasicAuthEnabled', httpBasicEnabled);
  }

  Future<void> setHttpBasicUser(String value) async {
    httpBasicUser = value;
    model.notify();
    await secureStorage.write(key: 'httpBasicUser', value: httpBasicUser);
  }

  Future<void> setHttpBasicPassword(String value) async {
    httpBasicPassword = value;
    model.notify();
    await secureStorage.write(
        key: 'httpBasicPassword', value: httpBasicPassword);
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    model.notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('authEnabled', enabled);
  }

  Future<void> setUser(String value) async {
    user = value;
    model.notify();
    await secureStorage.write(key: 'user', value: user);
  }

  Future<void> setPassword(String value) async {
    password = value;
    model.notify();
    await secureStorage.write(key: 'password', value: password);
  }

  Future<void> setSessionId(String value) async {
    sessionId = value;
    model.notify();
    await secureStorage.write(key: 'sessionToken', value: sessionId);
  }

  Future<void> setUserId(String value) async {
    userId = value;
    model.notify();
    await secureStorage.write(key: 'userId', value: userId);
  }

  Map<String, String> getAuthHeaders() {
    final Map<String, String> headers = <String, String>{};
    if (httpBasicEnabled) {
      headers['Authorization'] = 'Basic ' +
          utf8.fuse(base64).encode('$httpBasicUser:$httpBasicPassword');
    }
    if (enabled) {
      headers['X-Session-ID'] = sessionId;
    }
    return headers;
  }
}

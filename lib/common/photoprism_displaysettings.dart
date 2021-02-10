import 'package:photoprism/model/photoprism_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoprismDisplaySettings {
  PhotoprismDisplaySettings(this.model)
      : secureStorage = const FlutterSecureStorage() {
    initialized = initialize();
  }

  PhotoprismModel model;
  final FlutterSecureStorage secureStorage;
  bool showPrivate = false;
  Future<void> initialized;

  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool showPrivateStored = prefs.getBool('showPrivate');
    if (showPrivateStored != null) {
      showPrivate = showPrivateStored;
    }

    model.notify();
    return 0;
  }

  Future<void> setShowPrivate(bool value) async {
    showPrivate = value;
    model.notify();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('showPrivate', showPrivate);
  }
}

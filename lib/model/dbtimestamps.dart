import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DbTimestamps {
  DbTimestamps({
    String photosUpdatedAt,
    String photosDeletedAt,
    String filesUpdatedAt,
    String filesDeletedAt,
    String albumsUpdatedAt,
    String albumsDeletedAt,
    String photosAlbumsUpdatedAt,
    String photosAlbumsDeletedAt,
  }) {
    _photosUpdatedAt = photosUpdatedAt;
    _photosDeletedAt = photosDeletedAt;
    _filesUpdatedAt = filesUpdatedAt;
    _filesDeletedAt = filesDeletedAt;
    _albumsUpdatedAt = albumsUpdatedAt;
    _albumsDeletedAt = albumsDeletedAt;
    _photosAlbumsUpdatedAt = photosAlbumsUpdatedAt;
    _photosAlbumsDeletedAt = photosAlbumsDeletedAt;
  }

  factory DbTimestamps.fromJson(Map<String, dynamic> json) {
    return DbTimestamps(
      photosUpdatedAt: json['photosUpdatedAt'] as String,
      photosDeletedAt: json['photosDeletedAt'] as String,
      filesUpdatedAt: json['filesUpdatedAt'] as String,
      filesDeletedAt: json['filesDeletedAt'] as String,
      albumsUpdatedAt: json['albumsUpdatedAt'] as String,
      albumsDeletedAt: json['albumsDeletedAt'] as String,
      photosAlbumsUpdatedAt: json['photosAlbumsUpdatedAt'] as String,
      photosAlbumsDeletedAt: json['photosAlbumsDeletedAt'] as String,
    );
  }

  static Future<DbTimestamps> fromSharedPrefs() async {
    print('load dbTimestamps from sharedprefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();

    if (sp.containsKey(_spKey)) {
      print('found dbTimestamps in sharedprefs: ' + sp.getString(_spKey));
      // try {
      return DbTimestamps.fromJson(
          json.decode(sp.getString(_spKey)) as Map<String, dynamic>);
      // } catch (_) {
      // sp.remove(_spKey);
      // }
    }
    return DbTimestamps();
  }

  static const String _spKey = 'dbTimestamps';

  String _photosUpdatedAt;
  String _photosDeletedAt;
  String _filesUpdatedAt;
  String _filesDeletedAt;
  String _albumsUpdatedAt;
  String _albumsDeletedAt;
  String _photosAlbumsUpdatedAt;
  String _photosAlbumsDeletedAt;
  String get photosUpdatedAt => _photosUpdatedAt;
  String get photosDeletedAt => _photosDeletedAt;
  String get filesUpdatedAt => _filesUpdatedAt;
  String get filesDeletedAt => _filesDeletedAt;
  String get albumsUpdatedAt => _albumsUpdatedAt;
  String get albumsDeletedAt => _albumsDeletedAt;
  String get photosAlbumsUpdatedAt => _photosAlbumsUpdatedAt;
  String get photosAlbumsDeletedAt => _photosAlbumsDeletedAt;

  Map<String, dynamic> toJson() => <String, String>{
        'photosUpdatedAt': _photosUpdatedAt,
        'photosDeletedAt': _photosDeletedAt,
        'filesUpdatedAt': _filesUpdatedAt,
        'filesDeletedAt': _filesDeletedAt,
        'albumsUpdatedAt': _albumsUpdatedAt,
        'albumsDeletedAt': _albumsDeletedAt,
        'photosAlbumsUpdatedAt': _photosAlbumsUpdatedAt,
        'photosAlbumsDeletedAt': _photosAlbumsDeletedAt,
      };

  set photosUpdatedAt(String value) {
    _photosUpdatedAt = value;
    _saveTosharedPrefs();
  }

  set photosDeletedAt(String value) {
    _photosDeletedAt = value;
    _saveTosharedPrefs();
  }

  set filesUpdatedAt(String value) {
    _filesUpdatedAt = value;
    _saveTosharedPrefs();
  }

  set filesDeletedAt(String value) {
    _filesDeletedAt = value;
    _saveTosharedPrefs();
  }

  set albumsUpdatedAt(String value) {
    _albumsUpdatedAt = value;
    _saveTosharedPrefs();
  }

  set albumsDeletedAt(String value) {
    _albumsDeletedAt = value;
    _saveTosharedPrefs();
  }

  set photosAlbumsUpdatedAt(String value) {
    _photosAlbumsUpdatedAt = value;
    _saveTosharedPrefs();
  }

  set photosAlbumsDeletedAt(String value) {
    _photosAlbumsDeletedAt = value;
    _saveTosharedPrefs();
  }

  Future<void> _saveTosharedPrefs() async {
    print('save dbTimestamps to sharedprefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(_spKey, json.encode(this));
  }

  Future<void> clear() async {
    _photosUpdatedAt = null;
    _photosDeletedAt = null;
    _filesUpdatedAt = null;
    _filesDeletedAt = null;
    _albumsUpdatedAt = null;
    _albumsDeletedAt = null;
    _photosAlbumsUpdatedAt = null;
    _photosAlbumsDeletedAt = null;
    _saveTosharedPrefs();
  }
}

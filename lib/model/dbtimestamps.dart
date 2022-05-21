import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DbTimestamps {
  DbTimestamps(Map<String, String?> data) {
    _d = data;
  }

  bool get isEmpty => _d!.isEmpty;

  static Future<DbTimestamps> fromSharedPrefs() async {
    print('load dbTimestamps from sharedprefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();

    if (sp.containsKey(_spKey)) {
      print('found dbTimestamps in sharedprefs: ' + sp.getString(_spKey)!);
      try {
        return DbTimestamps(
            (json.decode(sp.getString(_spKey)!) as Map<String, dynamic>).map(
                (String key, dynamic value) =>
                    MapEntry<String, String>(key, value as String)));
      } catch (_) {
        sp.remove(_spKey);
      }
    }
    return DbTimestamps(<String, String?>{});
  }

  static const String _spKey = 'dbTimestamps';
  Map<String, String?>? _d;

  String? getQueryTimestamp(String table) {
    if (_d!.containsKey(table)) {
      return _d![table];
    }
    return null;
  }

  void setQueryTimestamp(String table, String? value) {
    _d![table] = value;
    _saveTosharedPrefs();
  }

  Map<String, dynamic>? toJson() => _d;

  Future<void> _saveTosharedPrefs() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(_spKey, json.encode(_d));
  }

  Future<void> clear() async {
    _d = <String, String?>{};
    _saveTosharedPrefs();
  }
}

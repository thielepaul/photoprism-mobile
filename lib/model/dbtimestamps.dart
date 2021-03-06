import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DbTimestamp {
  DbTimestamp({this.updatedAt, this.deletedAt});

  factory DbTimestamp.fromJson(Map<String, dynamic> json) {
    return DbTimestamp(
      updatedAt: json['updatedAt'] as String,
      deletedAt: json['deletedAt'] as String,
    );
  }

  String updatedAt;
  String deletedAt;

  Map<String, dynamic> toJson() => <String, String>{
        'updatedAt': updatedAt,
        'deletedAt': deletedAt,
      };
}

class DbTimestamps {
  DbTimestamps(Map<String, DbTimestamp> data) {
    _d = data;
  }

  bool get isEmpty => _d.isEmpty;

  static Future<DbTimestamps> fromSharedPrefs() async {
    print('load dbTimestamps from sharedprefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();

    if (sp.containsKey(_spKey)) {
      print('found dbTimestamps in sharedprefs: ' + sp.getString(_spKey));
      try {
        return DbTimestamps(
            (json.decode(sp.getString(_spKey)) as Map<String, dynamic>).map(
                (String key, dynamic value) => MapEntry<String, DbTimestamp>(
                    key, DbTimestamp.fromJson(value as Map<String, dynamic>))));
      } catch (_) {
        sp.remove(_spKey);
      }
    }
    return DbTimestamps(<String, DbTimestamp>{});
  }

  static const String _spKey = 'dbTimestamps';
  Map<String, DbTimestamp> _d;

  String getUpdatedAt(String table) {
    if (_d.containsKey(table)) {
      return _d[table].updatedAt;
    }
    return null;
  }

  String getDeletedAt(String table) {
    if (_d.containsKey(table)) {
      return _d[table].deletedAt;
    }
    return null;
  }

  void setUpdatedAt(String table, String value) {
    if (!_d.containsKey(table)) {
      _d[table] = DbTimestamp();
    }
    _d[table].updatedAt = value;
    _saveTosharedPrefs();
  }

  void setDeletedAt(String table, String value) {
    if (!_d.containsKey(table)) {
      _d[table] = DbTimestamp();
    }
    _d[table].deletedAt = value;
    _saveTosharedPrefs();
  }

  Map<String, dynamic> toJson() => _d;

  Future<void> _saveTosharedPrefs() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(_spKey, json.encode(_d));
  }

  Future<void> clear() async {
    _d = <String, DbTimestamp>{};
    _saveTosharedPrefs();
  }
}

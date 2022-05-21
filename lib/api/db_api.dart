import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/api/api.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/model/photoprism_model.dart';

class DbApiException implements Exception {
  const DbApiException(this.msg);
  final String msg;
  @override
  String toString() => 'DbApiException: $msg';
}

const int _resultCount = 1000;

Future<Map<String, dynamic>?> _loadDbBatch(
    PhotoprismModel model, String table, int offset, String? since) async {
  final Uri url = Uri.parse(model.photoprismUrl +
      '/api/v1/db' +
      '?count=' +
      _resultCount.toString() +
      '&table=' +
      table +
      '&offset=' +
      offset.toString() +
      (since != null ? '&since=' + since : ''));
  final http.Response response = await apiHttpAuth(model,
          () => http.get(url, headers: model.photoprismAuth.getAuthHeaders()))
      as http.Response;
  if (response.statusCode != 200) {
    print(
        'ERROR: api DB call failed with return type ${response.statusCode} ($url)');
    if (response.statusCode == 401) {
      throw const DbApiException('auth-missing');
    }
    throw const DbApiException('wrong-status-code');
  }
  if (response.headers['content-type'] != 'application/json; charset=utf-8') {
    print(
        'ERROR: api DB call failed, content type is ${response.headers["content-type"]} ($url)');
    throw const DbApiException('api-fail');
  }
  try {
    return json.decode(response.body) as Map<String, dynamic>?;
  } catch (error) {
    print(response);
    print('decoding answer from db api failed: ' + error.toString());
    throw const DbApiException('api-fail');
  }
}

Future<List<dynamic>?> _loadDbBatchUpdated(
    PhotoprismModel model, String table, int offset, String? since) async {
  final Map<String, dynamic>? parsed =
      await _loadDbBatch(model, table, offset, since);
  if (parsed == null) {
    return <dynamic>[];
  }

  if (offset == 0 &&
      parsed.containsKey('QueryTimestamp') &&
      parsed['QueryTimestamp'] != null) {
    model.dbTimestamps!
        .setQueryTimestamp(table, parsed['QueryTimestamp'] as String?);
  }
  if (parsed.containsKey('Results') && parsed['Results'] is List) {
    return parsed['Results'] as List<dynamic>?;
  }
  return <dynamic>[];
}

Future<List<dynamic>> _loadDbAll(PhotoprismModel model, String table,
    {bool deleted = true}) async {
  final List<dynamic> rowsFromApiCollected = <dynamic>[];
  List<dynamic>? rowsFromApi;
  final String? since = model.dbTimestamps!.getQueryTimestamp(table);

  while (rowsFromApi == null || rowsFromApi.length == _resultCount) {
    if (rowsFromApi != null) {
      model.photoprismLoadingScreen
          .showLoadingScreen('loading metadata from backend...');
    }
    rowsFromApi = (await _loadDbBatchUpdated(
            model, table, rowsFromApiCollected.length, since))!
        .toList();
    print('download batch of rows from db based on QueryTimestamp for table ' +
        table +
        ' got ' +
        rowsFromApi.length.toString() +
        ' rows');
    rowsFromApiCollected.addAll(rowsFromApi);
  }
  return rowsFromApiCollected;
}

Future<Iterable<Photo>> _loadPhotosDb(PhotoprismModel model) async {
  final List<dynamic> parsed = await _loadDbAll(model, 'photos');

  return parsed.map((dynamic json) => Photo.fromJson(
      json as Map<String, dynamic>,
      serializer: const CustomSerializer()));
}

Future<Iterable<File>> _loadFilesDb(PhotoprismModel model) async {
  final List<dynamic> parsed = await _loadDbAll(model, 'files');

  return parsed.map((dynamic json) => File.fromJson(
      json as Map<String, dynamic>,
      serializer: const CustomSerializer()));
}

Future<Iterable<Album>> _loadAlbumsDb(PhotoprismModel model) async {
  final List<dynamic> parsed = await _loadDbAll(model, 'albums');

  return parsed.map((dynamic json) => Album.fromJson(
      json as Map<String, dynamic>,
      serializer: const CustomSerializer()));
}

Future<Iterable<PhotosAlbum>> _loadPhotosAlbumsDb(PhotoprismModel model) async {
  final List<dynamic> parsed =
      await _loadDbAll(model, 'photos_albums', deleted: false);

  return parsed.map((dynamic json) => PhotosAlbum.fromJson(
      json as Map<String, dynamic>,
      serializer: const CustomSerializer()));
}

Future<void> _updateDbSynced(PhotoprismModel model) async {
  try {
    final Iterable<Photo> photos = await _loadPhotosDb(model);
    if (photos.isNotEmpty) {
      print('update Photo table');
      await model.database!.createOrUpdateMultiplePhotos(
          photos.map((Photo p) => p.toCompanion(false)).toList());
    }
    final Iterable<File> files = await _loadFilesDb(model);
    if (files.isNotEmpty) {
      print('update File table');
      await model.database!.createOrUpdateMultipleFiles(
          files.map((File p) => p.toCompanion(false)).toList());
    }
    final Iterable<Album> albums = await _loadAlbumsDb(model);
    if (albums.isNotEmpty) {
      print('update Album table');
      await model.database!.createOrUpdateMultipleAlbums(
          albums.map((Album p) => p.toCompanion(false)).toList());
    }
    final Iterable<PhotosAlbum> photosAlbums = await _loadPhotosAlbumsDb(model);
    if (photosAlbums.isNotEmpty) {
      print('update PhotosAlbum table');
      await model.database!.createOrUpdateMultiplePhotosAlbums(
          photosAlbums.map((PhotosAlbum p) => p.toCompanion(false)).toList());
    }
  } on SqliteException catch (e) {
    print('cannot update db, will reset db: ' + e.toString());
    model.resetDatabase();
  }
}

Future<void> apiUpdateDb(PhotoprismModel model, {BuildContext? context}) async {
  await model.dbLoadingLock.synchronized(() async {
    if (model.dbTimestamps == null) {
      return;
    }
    try {
      await _updateDbSynced(model);
    } on DbApiException catch (e) {
      print('Exception: ${e.toString()}');
      if (context != null) {
        String? msg;
        if (e.msg == 'no-connection' && model.dbTimestamps!.isEmpty) {
          msg = 'Can not connect to server ${model.photoprismUrl}';
        } else if (e.msg == 'auth-missing') {
          msg = 'Server requires authentification';
        } else if (e.msg == 'api-fail') {
          msg = 'Server API is not compatible with this version of the app';
        }
        if (msg != null) {
          await showDialog<AlertDialog>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(msg!),
                );
              });
        }
      }
    }
  });
  model.photoprismLoadingScreen.hideLoadingScreen();
}

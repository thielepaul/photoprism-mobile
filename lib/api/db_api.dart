import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moor/ffi.dart';
import 'package:photoprism/common/db.dart';
import 'package:photoprism/api/api.dart';
import 'package:photoprism/model/photoprism_model.dart';

class DbApiException implements Exception {
  const DbApiException(this.msg);
  final String msg;
  @override
  String toString() => 'DbApiException: $msg';
}

class DbApi {
  static const int resultCount = 1000;

  static Future<List<dynamic>> _loadDbBatch(
      PhotoprismModel model, String table, bool deleted, String since) async {
    final Uri url = Uri.parse(model.photoprismUrl +
        '/api/v1/db' +
        '?count=' +
        resultCount.toString() +
        '&table=' +
        table +
        '&deleted=' +
        deleted.toString() +
        (since != null ? '&since=' + since : ''));
    final http.Response response = await Api.httpAuth(model,
            () => http.get(url, headers: model.photoprismAuth.getAuthHeaders()))
        as http.Response;
    if (response == null) {
      print('ERROR: api DB call failed with response null ($url)');
      throw const DbApiException('no-connection');
    }
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
      return json.decode(response.body) as List<dynamic>;
    } catch (error) {
      print(response);
      print('decoding answer from db api failed: ' + error.toString());
      return <dynamic>[];
    }
  }

  static Future<List<dynamic>> _loadDbBatchUpdated(
      PhotoprismModel model, String table) async {
    final String since = model.dbTimestamps.getUpdatedAt(table);

    final List<dynamic> parsed = await _loadDbBatch(model, table, false, since);

    if (parsed.isNotEmpty && parsed.last['UpdatedAt'] != null) {
      model.dbTimestamps
          .setUpdatedAt(table, parsed.last['UpdatedAt'] as String);
    }
    return parsed;
  }

  static Future<List<dynamic>> _loadDbBatchDeleted(
      PhotoprismModel model, String table) async {
    final String since = model.dbTimestamps.getDeletedAt(table);

    final List<dynamic> parsed = await _loadDbBatch(model, table, true, since);

    if (parsed.isNotEmpty && parsed.last['DeletedAt'] != null) {
      model.dbTimestamps
          .setDeletedAt(table, parsed.last['DeletedAt'] as String);
    }
    return parsed;
  }

  static Future<List<dynamic>> _loadDbAll(PhotoprismModel model, String table,
      {bool deleted = true}) async {
    final List<dynamic> rowsFromApiCollected = <dynamic>[];
    List<dynamic> rowsFromApi;
    while (rowsFromApi == null || rowsFromApi.length == resultCount) {
      if (rowsFromApi != null) {
        model.photoprismLoadingScreen
            .showLoadingScreen('loading metadata from backend...');
      }
      rowsFromApi = (await _loadDbBatchUpdated(model, table)).toList();
      print('download batch of rows from db based on updatedAt for table ' +
          table +
          ' got ' +
          rowsFromApi.length.toString() +
          ' rows');
      rowsFromApiCollected.addAll(rowsFromApi);
    }
    if (deleted) {
      rowsFromApi = null;
      while (rowsFromApi == null || rowsFromApi.length == resultCount) {
        if (rowsFromApi != null) {
          model.photoprismLoadingScreen
              .showLoadingScreen('loading metadata from backend...');
        }
        rowsFromApi = (await _loadDbBatchDeleted(model, table)).toList();
        print('download batch of rows from db based on deletedAt for table ' +
            table +
            ' got ' +
            rowsFromApi.length.toString() +
            ' rows');
        rowsFromApiCollected.addAll(rowsFromApi);
      }
    }
    return rowsFromApiCollected;
  }

  static Future<Iterable<Photo>> _loadPhotosDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await _loadDbAll(model, 'photos');

    return parsed.map((dynamic json) => Photo.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<File>> _loadFilesDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await _loadDbAll(model, 'files');

    return parsed.map((dynamic json) => File.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<Album>> _loadAlbumsDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await _loadDbAll(model, 'albums');

    return parsed.map((dynamic json) => Album.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<PhotosAlbum>> _loadPhotosAlbumsDb(
      PhotoprismModel model) async {
    final List<dynamic> parsed =
        await _loadDbAll(model, 'photos_albums', deleted: false);

    return parsed.map((dynamic json) => PhotosAlbum.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<void> _updateDbSynced(PhotoprismModel model) async {
    try {
      final Iterable<Photo> photos = await _loadPhotosDb(model);
      if (photos.isNotEmpty) {
        print('update Photo table');
        await model.database.createOrUpdateMultiplePhotos(
            photos.map((Photo p) => p.toCompanion(false)).toList());
      }
      final Iterable<File> files = await _loadFilesDb(model);
      if (files.isNotEmpty) {
        print('update File table');
        await model.database.createOrUpdateMultipleFiles(
            files.map((File p) => p.toCompanion(false)).toList());
      }
      final Iterable<Album> albums = await _loadAlbumsDb(model);
      if (albums.isNotEmpty) {
        print('update Album table');
        await model.database.createOrUpdateMultipleAlbums(
            albums.map((Album p) => p.toCompanion(false)).toList());
      }
      final Iterable<PhotosAlbum> photosAlbums =
          await _loadPhotosAlbumsDb(model);
      if (photosAlbums.isNotEmpty) {
        print('update PhotosAlbum table');
        await model.database.createOrUpdateMultiplePhotosAlbums(
            photosAlbums.map((PhotosAlbum p) => p.toCompanion(false)).toList());
      }
    } on SqliteException catch (e) {
      print('cannot update db, will reset db: ' + e.toString());
      model.resetDatabase();
    }
  }

  static Future<void> updateDb(PhotoprismModel model,
      {BuildContext context}) async {
    await model.dbLoadingLock.synchronized(() async {
      if (model.dbTimestamps == null) {
        return;
      }
      try {
        await _updateDbSynced(model);
      } on DbApiException catch (e) {
        print('Exception: ${e.toString()}');
        if (context != null) {
          String msg;
          if (e.msg == 'no-connection' && model.dbTimestamps.isEmpty) {
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
                    content: Text(msg),
                  );
                });
          }
        }
      }
    });
    model.photoprismLoadingScreen.hideLoadingScreen();
  }
}

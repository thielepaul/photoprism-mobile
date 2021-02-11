import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:moor/ffi.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/common/db.dart';
import 'package:http_parser/http_parser.dart';

class Api {
  static const int resultCount = 1000;

  static Future<dynamic> httpAuth(PhotoprismModel model, Function call) async {
    dynamic response = await call();
    if ((response as http.BaseResponse).statusCode == 401) {
      if (await getNewSession(model)) {
        response = await call();
      }
    }
    return response;
  }

  static Future<dynamic> httpWithDownloadToken(
      PhotoprismModel model, Function call) async {
    if (model.config == null) {
      await loadConfig(model);
    }
    dynamic response = await httpAuth(model, call);
    if ((response as http.BaseResponse).statusCode == 403) {
      if (await loadConfig(model)) {
        response = await httpAuth(model, call);
      }
    }
    return response;
  }

  static Future<String> createAlbum(
      String albumName, PhotoprismModel model) async {
    final String body = '{"Title":"' + albumName + '"}';

    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(model.photoprismUrl + '/api/v1/albums',
              body: body,
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;

      if (response.statusCode == 200) {
        final dynamic bodyjson = json.decode(response.body);
        return bodyjson['UID'].toString();
      } else {
        return '-1';
      }
    } catch (_) {
      return '-1';
    }
  }

  static Future<int> renameAlbum(
      String albumId, String newAlbumName, PhotoprismModel model) async {
    final String body = '{"Title":"' + newAlbumName + '"}';

    try {
      final http.Response response = await httpAuth(
          model,
          () => http.put(model.photoprismUrl + '/api/v1/albums/' + albumId,
              body: body,
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> deleteAlbum(String albumId, PhotoprismModel model) async {
    final String body = '{"albums":["' + albumId + '"]}';

    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(model.photoprismUrl + '/api/v1/batch/albums/delete',
              body: body,
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> addPhotosToAlbum(
      String albumId, List<String> photoUUIDs, PhotoprismModel model) async {
    // wrap uuids in double quotes

    final List<String> photoUUIDsWrapped =
        photoUUIDs.map<String>((String uuid) => '"' + uuid + '"').toList();

    final String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(
              model.photoprismUrl + '/api/v1/albums/' + albumId + '/photos',
              body: body,
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> removePhotosFromAlbum(
      String albumId, List<String> photoUUIDs, PhotoprismModel model) async {
    // wrap uuids in double quotes
    final List<String> photoUUIDsWrapped =
        photoUUIDs.map<String>((String uuid) => '"' + uuid + '"').toList();

    final String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request(
          'DELETE',
          Uri.parse(
              model.photoprismUrl + '/api/v1/albums/' + albumId + '/photos'));
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
      model.photoprismAuth.getAuthHeaders().forEach((String k, String v) {
        request.headers[k] = v;
      });
      final http.StreamedResponse response =
          await httpAuth(model, () => client.send(request))
              as http.StreamedResponse;
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> archivePhotos(
      List<String> photoUUIDs, PhotoprismModel model) async {
    // wrap uuids in double quotes
    final List<String> photoUUIDsWrapped =
        photoUUIDs.map<String>((String uuid) => '"' + uuid + '"').toList();

    final String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(model.photoprismUrl + '/api/v1/batch/photos/archive',
              body: body,
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<bool> importPhotos(
      String photoprismUrl, PhotoprismModel model, String fileHash) async {
    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(photoprismUrl + '/api/v1/import/upload/$fileHash',
              body: '{}',
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;
      return response.statusCode == 200;
    } catch (ex) {
      print(ex);
      return false;
    }
  }

  static Future<int> importPhotoEvent(
      PhotoprismModel model, String event) async {
    try {
      final http.Response response = await httpAuth(
          model,
          () => http.post(
              model.photoprismUrl + '/api/v1/import/upload/' + event,
              body: '{}',
              headers: model.photoprismAuth.getAuthHeaders())) as http.Response;
      if (response.statusCode == 200) {
        // TODO: Check if import is really successful
        if (response.body == '{"message":"import completed in 0 s"}') {
          return 3;
        } else {
          return 0;
        }
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<bool> upload(PhotoprismModel model, String fileId,
      String fileName, io.File file) async {
    try {
      final http.MultipartRequest request = http.MultipartRequest(
          'POST', Uri.parse('${model.photoprismUrl}/api/v1/upload/$fileId'));
      request.files.add(http.MultipartFile(
          'files', file.openRead(), await file.length(),
          filename: fileName, contentType: MediaType('image', 'jpeg')));
      request.headers.addAll(model.photoprismAuth.getAuthHeaders());
      final http.StreamedResponse response =
          await httpAuth(model, () => request.send()) as http.StreamedResponse;

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Upload failed: statusCode=${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Upload failed: $e');
      return false;
    }
  }

  static Future<bool> getNewSession(PhotoprismModel model) async {
    if (model.photoprismAuth.enabled == false) {
      return false;
    }

    final http.Response response = await http.post(
        model.photoprismUrl + '/api/v1/session',
        headers: model.photoprismAuth.getAuthHeaders(),
        body:
            '{"username":"${model.photoprismAuth.user}", "password":"${model.photoprismAuth.password}"}');
    if (response.statusCode == 200 &&
        response.headers.containsKey('x-session-id')) {
      await model.photoprismAuth.setSessionId(response.headers['x-session-id']);
      return true;
    }
    return false;
  }

  static Future<List<int>> downloadVideo(
      PhotoprismModel model, Photo photo) async {
    final String videoUrl = await getVideoUrl(model, photo.uid);
    if (videoUrl == null) {
      print('found no video file for photo: ' + photo.uid);
      return null;
    }
    final http.Response response = await http.get(videoUrl);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      model.photoprismMessage
          .showMessage('Error while sharing: No connection to server!');
    }
    return null;
  }

  static Future<List<int>> downloadPhoto(
      PhotoprismModel model, String fileHash) async {
    final http.Response response = await Api.httpWithDownloadToken(
        model,
        () => http.get(
            Uri.parse(
                '${model.photoprismUrl}/api/v1/dl/$fileHash?t=${model.config.downloadToken}'),
            headers: model.photoprismAuth.getAuthHeaders())) as http.Response;

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      model.photoprismMessage
          .showMessage('Error while sharing: No connection to server!');
    }
    return null;
  }

  static Future<bool> loadConfig(PhotoprismModel model) async {
    final http.Response response = await httpAuth(
        model,
        () => http.get(model.photoprismUrl + '/api/v1/config',
            headers: model.photoprismAuth.getAuthHeaders())) as http.Response;
    if (response.statusCode != 200) {
      model.config = null;
      return false;
    }
    model.setConfig(
        Config.fromJson(json.decode(response.body) as Map<String, dynamic>));
    return true;
  }

  static Future<String> getVideoUrl(
      PhotoprismModel model, String photoUid) async {
    if (model.config == null) {
      return null;
    }
    final File file = await model.database.getVideoFileForPhoto(photoUid);
    if (file == null) {
      return null;
    }
    return model.photoprismUrl +
        '/api/v1/videos/' +
        file.hash +
        '/' +
        model.config.previewToken +
        '/mp4';
  }

  static Future<List<dynamic>> loadDbBatch(
      PhotoprismModel model, String table, bool deleted, String since) async {
    final String url = model.photoprismUrl +
        '/api/v1/db' +
        '?count=' +
        resultCount.toString() +
        '&table=' +
        table +
        '&deleted=' +
        deleted.toString() +
        (since != null ? '&since=' + since : '');
    final http.Response response = await httpAuth(model,
            () => http.get(url, headers: model.photoprismAuth.getAuthHeaders()))
        as http.Response;
    if (response.statusCode != 200) {
      print('ERROR: api DB call failed ($url)');
      return <dynamic>[];
    }
    try {
      return json.decode(response.body) as List<dynamic>;
    } catch (error) {
      print('decoding answer from db api failed: ' + error.toString());
      return <dynamic>[];
    }
  }

  static Future<List<dynamic>> loadDbBatchUpdated(
      PhotoprismModel model, String table) async {
    final String since = model.dbTimestamps.getUpdatedAt(table);

    final List<dynamic> parsed = await loadDbBatch(model, table, false, since);

    if (parsed.isNotEmpty && parsed.last['UpdatedAt'] != null) {
      model.dbTimestamps
          .setUpdatedAt(table, parsed.last['UpdatedAt'] as String);
    }
    return parsed;
  }

  static Future<List<dynamic>> loadDbBatchDeleted(
      PhotoprismModel model, String table) async {
    final String since = model.dbTimestamps.getDeletedAt(table);

    final List<dynamic> parsed = await loadDbBatch(model, table, true, since);

    if (parsed.isNotEmpty && parsed.last['DeletedAt'] != null) {
      model.dbTimestamps
          .setDeletedAt(table, parsed.last['DeletedAt'] as String);
    }
    return parsed;
  }

  static Future<List<dynamic>> loadDbAll(PhotoprismModel model, String table,
      {bool deleted = true}) async {
    final List<dynamic> rowsFromApiCollected = <dynamic>[];
    List<dynamic> rowsFromApi;
    while (rowsFromApi == null || rowsFromApi.length == resultCount) {
      rowsFromApi = (await loadDbBatchUpdated(model, table)).toList();
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
        rowsFromApi = (await loadDbBatchDeleted(model, table)).toList();
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

  static Future<Iterable<Photo>> loadPhotosDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await loadDbAll(model, 'photos');

    return parsed.map((dynamic json) => Photo.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<File>> loadFilesDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await loadDbAll(model, 'files');

    return parsed.map((dynamic json) => File.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<Album>> loadAlbumsDb(PhotoprismModel model) async {
    final List<dynamic> parsed = await loadDbAll(model, 'albums');

    return parsed.map((dynamic json) => Album.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<Iterable<PhotosAlbum>> loadPhotosAlbumsDb(
      PhotoprismModel model) async {
    final List<dynamic> parsed =
        await loadDbAll(model, 'photos_albums', deleted: false);

    return parsed.map((dynamic json) => PhotosAlbum.fromJson(
        json as Map<String, dynamic>,
        serializer: const CustomSerializer()));
  }

  static Future<void> updateDb(PhotoprismModel model) async {
    await model.dbLoadingLock.synchronized(() async {
      if (model.dbTimestamps == null) {
        return;
      }

      try {
        final Iterable<Photo> photos = await loadPhotosDb(model);
        if (photos.isNotEmpty) {
          print('update Photo table');
          await model.database.createOrUpdateMultiplePhotos(
              photos.map((Photo p) => p.toCompanion(false)).toList());
        }
        final Iterable<File> files = await loadFilesDb(model);
        if (files.isNotEmpty) {
          print('update File table');
          await model.database.createOrUpdateMultipleFiles(
              files.map((File p) => p.toCompanion(false)).toList());
        }
        final Iterable<Album> albums = await loadAlbumsDb(model);
        if (albums.isNotEmpty) {
          print('update Album table');
          await model.database.createOrUpdateMultipleAlbums(
              albums.map((Album p) => p.toCompanion(false)).toList());
        }
        final Iterable<PhotosAlbum> photosAlbums =
            await loadPhotosAlbumsDb(model);
        if (photosAlbums.isNotEmpty) {
          print('update PhotosAlbum table');
          await model.database.createOrUpdateMultiplePhotosAlbums(photosAlbums
              .map((PhotosAlbum p) => p.toCompanion(false))
              .toList());
        }
      } on SqliteException catch (e) {
        print('cannot update db, will reset db: ' + e.toString());
        model.resetDatabase();
      }
    });
  }
}

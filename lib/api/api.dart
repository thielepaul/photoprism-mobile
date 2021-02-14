import 'dart:convert';
import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:photoprism/api/db_api.dart';
import 'package:photoprism/model/config.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:photoprism/common/db.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class Api {
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

  static Future<io.File> downloadVideo(
      PhotoprismModel model, Future<PhotoWithFile> photoFuture) async {
    final String videoUrl = await getVideoUrl(model, photoFuture);
    final PhotoWithFile photo = await photoFuture;
    if (videoUrl == null) {
      print('found no video file for photo: ' + photo.photo.uid);
      return null;
    }
    final File videoFile =
        await model.database.getVideoFileForPhoto(photo.photo.uid);
    String fileName;
    if (photo.file.originalName != null && photo.file.originalName.isNotEmpty) {
      fileName = videoFile.originalName;
    } else {
      fileName = p.basename(videoFile.name);
    }
    return downloadAsFile(model, Uri.parse(videoUrl), fileName);
  }

  static Future<io.File> downloadPhoto(
      PhotoprismModel model, String fileHash) async {
    return downloadAsFile(
        model,
        Uri.parse(
            '${model.photoprismUrl}/api/v1/dl/$fileHash?t=${model.config.downloadToken}'),
        '$fileHash.jpg');
  }

  static Future<io.File> downloadAsFile(
      PhotoprismModel model, Uri uri, String fileName) async {
    final http.Client client = http.Client();
    final http.Request request = http.Request('GET', uri);
    model.photoprismAuth.getAuthHeaders().forEach((String k, String v) {
      request.headers[k] = v;
    });
    final http.StreamedResponse response =
        await httpAuth(model, () => client.send(request))
            as http.StreamedResponse;

    if (response.statusCode == 200) {
      final io.Directory tempDir = await getTemporaryDirectory();
      final io.File file = await io.File('${tempDir.path}/$fileName').create();
      final io.IOSink sink = file.openWrite();
      await sink.addStream(response.stream);
      sink.close();
      return file;
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
      PhotoprismModel model, Future<PhotoWithFile> photoWithFile) async {
    if (model.config == null) {
      return null;
    }
    final File file = await model.database
        .getVideoFileForPhoto((await photoWithFile).photo.uid);
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

  static Future<void> preloadThumbnails(PhotoprismModel model) async {
    if (model.photos == null || model.photos.isEmpty) {
      await DbApi.updateDb(model);
    }

    if (model.config == null) {
      await Api.loadConfig(model);
    }

    model.photoprismLoadingScreen.showLoadingScreen('Preloading thumbnails..');

    int photosLoaded = 0;
    int photosFailed = 0;
    for (int i = 0; i < model.photos.length; i++) {
      final PhotoWithFile photo = await model.photos[i];
      final CachedNetworkImageProvider provider = CachedNetworkImageProvider(
        model.photoprismUrl +
            '/api/v1/t/' +
            photo.file.hash +
            '/' +
            model.config.previewToken +
            '/tile_224',
        cacheKey: photo.file.hash + 'tile_224',
        headers: model.photoprismAuth.getAuthHeaders(),
      );

      final ImageErrorListener errorListener = (dynamic a, StackTrace b) {
        photosFailed++;
        model.photoprismLoadingScreen.updateLoadingScreen(
            'Preloading thumbnails.. ($photosLoaded succcessful, $photosFailed failed)');
        if (photosLoaded + photosFailed == model.photos.length) {
          model.photoprismLoadingScreen.hideLoadingScreen();
        }
      };

      final ImageStreamListener listener =
          ImageStreamListener((ImageInfo info, _) {
        photosLoaded++;
        model.photoprismLoadingScreen.updateLoadingScreen(
            'Preloading thumbnails.. ($photosLoaded succcessful, $photosFailed failed)');
        if (photosLoaded + photosFailed == model.photos.length) {
          model.photoprismLoadingScreen.hideLoadingScreen();
        }
      }, onError: errorListener);
      provider
          .resolve(const ImageConfiguration(size: Size.infinite))
          .addListener(listener);
    }
  }
}

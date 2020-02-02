import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:photoprism/model/album.dart';
import 'package:photoprism/model/moments_time.dart';
import 'package:photoprism/model/photo.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:provider/provider.dart';

class Api {
  static Future<String> createAlbum(
      String albumName, PhotoprismModel model) async {
    final String body = '{"AlbumName":"' + albumName + '"}';

    try {
      final http.Response response = await http.post(
          model.photoprismUrl + '/api/v1/albums',
          body: body,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());

      if (response.statusCode == 200) {
        final dynamic bodyjson = json.decode(response.body);
        return bodyjson['AlbumUUID'].toString();
      } else {
        return '-1';
      }
    } catch (_) {
      return '-1';
    }
  }

  static Future<int> renameAlbum(
      String albumId, String newAlbumName, PhotoprismModel model) async {
    final String body = '{"AlbumName":"' + newAlbumName + '"}';

    try {
      final http.Response response = await http.put(
          model.photoprismUrl + '/api/v1/albums/' + albumId,
          body: body,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());

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
      final http.Response response = await http.post(
          model.photoprismUrl + '/api/v1/batch/albums/delete',
          body: body,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());

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
      final http.Response response = await http.post(
          model.photoprismUrl + '/api/v1/albums/' + albumId + '/photos',
          body: body,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());
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
    print(albumId);
    try {
      final http.Request request = http.Request(
          'DELETE',
          Uri.parse(
              model.photoprismUrl + '/api/v1/albums/' + albumId + '/photos'));
      request.headers['Content-Type'] = 'application/json';
      request.body = body;
      model.photoprismHttpBasicAuth
          .getAuthHeader()
          .forEach((String k, String v) {
        request.headers[k] = v;
      });
      final http.StreamedResponse response = await client.send(request);
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
      final http.Response response = await http.post(
          model.photoprismUrl + '/api/v1/batch/photos/archive',
          body: body,
          headers: model.photoprismHttpBasicAuth.getAuthHeader());
      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> importPhotos(
      String photoprismUrl, PhotoprismModel model, String fileHash) async {
    try {
      final http.Response response = await http.post(
          photoprismUrl + '/api/v1/import/upload/mobile',
          body: '{}',
          headers: model.photoprismHttpBasicAuth.getAuthHeader());
      print(response.body);
      if (response.statusCode == 200) {
        print('loading photos');
        // TODO: context is not available (does this make sense at all if the app might not be in foreground?)
        // instead it might make  more sense to check the success of the import by a dedicated http GET call
        // and refresh the photos the next time the UI is displayed
        // await PhotoManager.loadMomentsTime(context, forceReload: true);
        print('Finished');
        bool found = false;
        model.photos.forEach((_, Photo photo) {
          if (photo.fileHash == fileHash) {
            found = true;
          }
        });
        if (found == true) {
          print('Photo found in PhotoPrism');
          return 0;
        } else {
          print('Photo could not be added to PhotoPrism');
          return 3;
        }
      } else {
        return 2;
      }
    } catch (ex) {
      print(ex);
      return 1;
    }
  }

  static Future<int> importPhotoEvent(
      PhotoprismModel model, String event) async {
    try {
      final http.Response response = await http.post(
          model.photoprismUrl + '/api/v1/import/upload/' + event,
          body: '{}',
          headers: model.photoprismHttpBasicAuth.getAuthHeader());
      print(response.body);
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

  static Future<List<MomentsTime>> loadMomentsTime(BuildContext context) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);
    final http.Response response = await http.get(
        model.photoprismUrl + '/api/v1/moments/time',
        headers: model.photoprismHttpBasicAuth.getAuthHeader());
    return json
        .decode(response.body)
        .map<MomentsTime>((dynamic value) =>
            MomentsTime.fromJson(value as Map<String, dynamic>))
        .toList() as List<MomentsTime>;
  }

  static Future<Map<int, Photo>> loadPhotos(
      BuildContext context, int albumId, int offset) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    String albumIdUrlParam = '';
    if (albumId != null &&
        model.albums != null &&
        model.albums[albumId] != null) {
      albumIdUrlParam = model.albums[albumId].id;
    }

    final http.Response response = await http.get(
        model.photoprismUrl +
            '/api/v1/photos' +
            '?count=100' +
            '&offset=' +
            offset.toString() +
            '&album=' +
            albumIdUrlParam,
        headers: model.photoprismHttpBasicAuth.getAuthHeader());
    final List<dynamic> parsed = json.decode(response.body) as List<dynamic>;
    return Map<int, Photo>.fromIterables(
        List<int>.generate(parsed.length, (int i) => i + offset),
        parsed
            .map<Photo>(
                (dynamic json) => Photo.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  static Future<Map<int, Album>> loadAlbums(
      BuildContext context, int offset) async {
    final PhotoprismModel model = Provider.of<PhotoprismModel>(context);

    final http.Response response = await http.get(
        model.photoprismUrl +
            '/api/v1/albums' +
            '?count=1000' +
            '&offset=' +
            offset.toString(),
        headers: model.photoprismHttpBasicAuth.getAuthHeader());
    final List<dynamic> parsed = json.decode(response.body) as List<dynamic>;

    return Map<int, Album>.fromIterables(
        List<int>.generate(parsed.length, (int i) => i + offset),
        parsed
            .map<Album>(
                (dynamic json) => Album.fromJson(json as Map<String, dynamic>))
            .toList());
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:photoprism/api/photos.dart';
import 'package:photoprism/model/photoprism_model.dart';

class Api {
  static Future<String> createAlbum(
      String albumName, String photoprismUrl) async {
    String body = '{"AlbumName":"' + albumName + '"}';

    try {
      http.Response response =
          await http.post(photoprismUrl + '/api/v1/albums', body: body);

      if (response.statusCode == 200) {
        var bodyjson = json.decode(response.body);
        return bodyjson["AlbumUUID"];
      } else {
        return "-1";
      }
    } catch (_) {
      return "-1";
    }
  }

  static Future<int> renameAlbum(
      String albumId, String newAlbumName, String photoprismUrl) async {
    String body = '{"AlbumName":"' + newAlbumName + '"}';

    try {
      http.Response response = await http
          .put(photoprismUrl + '/api/v1/albums/' + albumId, body: body);

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }

  static Future<int> deleteAlbum(String albumId, String photoprismUrl) async {
    String body = '{"albums":["' + albumId + '"]}';

    try {
      http.Response response = await http
          .post(photoprismUrl + '/api/v1/batch/albums/delete', body: body);

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
      String albumId, List<String> photoUUIDs, String photoprismUrl) async {
    // wrap uuids in double quotes
    List<String> photoUUIDsWrapped = [];

    photoUUIDs.forEach((photoUUID) {
      photoUUIDsWrapped.add('"' + photoUUID + '"');
    });

    String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    try {
      http.Response response = await http.post(
          photoprismUrl + '/api/v1/albums/' + albumId + '/photos',
          body: body);
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
      String albumId, List<String> photoUUIDs, String photoprismUrl) async {
    // wrap uuids in double quotes
    List<String> photoUUIDsWrapped = [];

    photoUUIDs.forEach((photoUUID) {
      photoUUIDsWrapped.add('"' + photoUUID + '"');
    });

    String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    final client = http.Client();
    print(albumId);
    try {
      final response = await client.send(http.Request("DELETE",
          Uri.parse(photoprismUrl + '/api/v1/albums/' + albumId + '/photos'))
        ..headers["Content-Type"] = "application/json"
        ..body = body);
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
      List<String> photoUUIDs, String photoprismUrl) async {
    // wrap uuids in double quotes
    List<String> photoUUIDsWrapped = [];

    photoUUIDs.forEach((photoUUID) {
      photoUUIDsWrapped.add('"' + photoUUID + '"');
    });

    String body = '{"photos":' + photoUUIDsWrapped.toString() + '}';

    try {
      http.Response response = await http
          .post(photoprismUrl + '/api/v1/batch/photos/delete', body: body);
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
      http.Response response = await http
          .post(photoprismUrl + "/api/v1/import/upload/mobile", body: "{}");
      print(response.body);
      if (response.statusCode == 200) {
        print("loading photos");
        await PhotosPage.loadPhotos(model, photoprismUrl, "");
        print("Finished");
        bool found = false;
        for (var i = 0; i < model.photoList.length; i++) {
          if (model.photoList[i].fileHash == fileHash) {
            found = true;
          }
        }
        if (found == true) {
          print("Photo found in PhotoPrism");
          return 0;
        } else {
          print("Photo could not be added to PhotoPrism");
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
      String photoprismUrl, String event) async {
    try {
      http.Response response = await http
          .post(photoprismUrl + "/api/v1/import/upload/" + event, body: "{}");
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
}

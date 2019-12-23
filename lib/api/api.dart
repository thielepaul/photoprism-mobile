import 'package:http/http.dart' as http;

class Api {
  static Future<int> createAlbum(
      String albumName, String photoprismUrl) async {
    String body = '{"AlbumName":"' + albumName + '"}';

    try {
      http.Response response =
          await http.post(photoprismUrl + '/api/v1/albums', body: body);

      if (response.statusCode == 200) {
        return 0;
      } else {
        return 2;
      }
    } catch (_) {
      return 1;
    }
  }
}

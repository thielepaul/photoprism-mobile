import 'package:photoprism/model/photo.dart';

class Album {
  String id;
  String name;
  int imageCount;
  Map<int, Photo> photos = {};

  Album({this.id, this.name, this.imageCount});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['AlbumUUID'] as String,
      name: json['AlbumName'] as String,
      imageCount: json['AlbumCount'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'AlbumUUID': id,
        'AlbumName': name,
        'AlbumCount': imageCount,
      };
}

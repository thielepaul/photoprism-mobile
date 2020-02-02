import 'package:photoprism/model/photo.dart';

class Album {
  Album({this.id, this.name, this.imageCount});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['AlbumUUID'] as String,
      name: json['AlbumName'] as String,
      imageCount: json['AlbumCount'] as int,
    );
  }

  String id;
  String name;
  int imageCount;
  Map<int, Photo> photos = <int, Photo>{};

  Map<String, dynamic> toJson() => <String, dynamic>{
        'AlbumUUID': id,
        'AlbumName': name,
        'AlbumCount': imageCount,
      };
}

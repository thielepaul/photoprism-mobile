import 'package:photoprism/model/photo.dart';

class Album {
  final String id;
  final String name;
  final int imageCount;
  List<Photo> photoList;

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
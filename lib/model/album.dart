import 'package:photoprism/model/photo.dart';

class Album {
  final String id;
  final String name;
  List<Photo> photoList;

  Album({this.id, this.name});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['AlbumUUID'] as String,
      name: json['AlbumName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'AlbumUUID': id,
        'AlbumName': name,
      };
}
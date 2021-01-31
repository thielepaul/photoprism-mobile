import 'package:photoprism/model/photo_old.dart' as photo_old;

class Album {
  Album({this.id, this.name, this.imageCount});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['UID'] as String,
      name: json['Title'] as String,
      imageCount: json['PhotoCount'] as int,
    );
  }

  String id;
  String name;
  int imageCount;
  Map<int, photo_old.Photo> photos = <int, photo_old.Photo>{};

  Map<String, dynamic> toJson() => <String, dynamic>{
        'UID': id,
        'Title': name,
        'PhotoCount': imageCount,
      };
}

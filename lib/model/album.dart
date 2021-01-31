class AlbumOld {
  AlbumOld({this.id, this.name, this.imageCount});

  factory AlbumOld.fromJson(Map<String, dynamic> json) {
    return AlbumOld(
      id: json['UID'] as String,
      name: json['Title'] as String,
      imageCount: json['PhotoCount'] as int,
    );
  }

  String id;
  String name;
  int imageCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'UID': id,
        'Title': name,
        'PhotoCount': imageCount,
      };
}

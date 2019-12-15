class Album {
  final String id;
  final String name;

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
class Photo {
  Photo({this.fileHash, this.photoUUID, this.aspectRatio});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      fileHash: json['FileHash'] as String,
      photoUUID: json['PhotoUUID'] as String,
      aspectRatio: json['FileAspectRatio'].toDouble() as double,
    );
  }

  final String fileHash;
  final String photoUUID;
  final double aspectRatio;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'FileHash': fileHash,
        'PhotoUUID': photoUUID,
        'FileAspectRatio': aspectRatio,
      };
}

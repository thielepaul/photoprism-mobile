class Photo {
  final String fileHash;
  final String photoUUID;
  final double aspectRatio;

  Photo({this.fileHash, this.photoUUID, this.aspectRatio});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      fileHash: json['FileHash'] as String,
      photoUUID: json['PhotoUUID'] as String,
      aspectRatio: json['FileAspectRatio'].toDouble() as double,
    );
  }

  Map<String, dynamic> toJson() => {
        'FileHash': fileHash,
        'PhotoUUID': photoUUID,
        'FileAspectRatio': aspectRatio,
      };
}

class Photo {
  final String fileHash;
  final String photoUUID;

  Photo({this.fileHash, this.photoUUID});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      fileHash: json['FileHash'] as String,
      photoUUID: json['PhotoUUID'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'FileHash': fileHash,
    'PhotoUUID': photoUUID,
      };
}

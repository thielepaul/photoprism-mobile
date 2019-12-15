class Photo {
  final String fileHash;

  Photo({this.fileHash});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      fileHash: json['FileHash'] as String,
    );
  }
}
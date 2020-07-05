class File {
  File({this.hash, this.type, this.width, this.height, this.isVideo});

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      hash: json['Hash'] as String,
      type: json['Type'] as String,
      width: json['Width'].toDouble() as double,
      height: json['Height'].toDouble() as double,
      isVideo: json['Video'] as bool,
    );
  }

  final String hash;
  final String type;
  final double width;
  final double height;
  final bool isVideo;

  double get aspectRatio => width / height;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'Hash': hash,
        'Type': type,
        'Width': width,
        'Height': height,
        'Video': isVideo,
      };
}

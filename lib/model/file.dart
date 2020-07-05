class File {
  File({this.hash, this.type, this.width, this.height});

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      hash: json['Hash'] as String,
      type: json['Type'] as String,
      width: json['Width'].toDouble() as double,
      height: json['Height'].toDouble() as double,
    );
  }

  final String hash;
  final String type;
  final double width;
  final double height;

  double get aspectRatio => width / height;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'Hash': hash,
        'Type': type,
        'Width': width,
        'Height': height
      };
}

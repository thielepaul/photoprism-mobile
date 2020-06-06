class Photo {
  Photo({this.hash, this.uid, this.width, this.height});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      hash: json['Hash'] as String,
      uid: json['UID'] as String,
      width: json['Width'].toDouble() as double,
      height: json['Height'].toDouble() as double,
    );
  }

  final String hash;
  final String uid;
  final double width;
  final double height;

  double get aspectRatio => width / height;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'Hash': hash,
        'UID': uid,
        'Width': width,
        'Height': height
      };
}

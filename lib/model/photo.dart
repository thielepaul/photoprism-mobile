import 'package:photoprism/model/file.dart';

class Photo {
  Photo({this.uid, this.files});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
        uid: json['UID'] as String,
        files: json['Files']
            .map<File>(
                (dynamic json) => File.fromJson(json as Map<String, dynamic>))
            .toList() as List<File>);
  }

  final String uid;
  final List<File> files;
  String get hash => files.where((File file) => file.type == 'jpg').first.hash;
  double get aspectRatio =>
      files.where((File file) => file.type == 'jpg').first.aspectRatio;
  bool get isVideo => files.any((File file) => file.isVideo);
  String get videoHash => files.where((File file) => file.isVideo).first.hash;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'UID': uid,
        'Files': files,
      };
}

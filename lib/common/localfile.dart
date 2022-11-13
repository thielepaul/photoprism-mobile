import 'package:isar/isar.dart';

part 'localfile.g.dart';

@collection
class LocalFile {
  late String id;
  Id get isarId => fastHash(id);

  late String filename;
  late String albumName;
  late String localAlbumId;
  @enumerated
  UploadStatus uploadStatus = UploadStatus.planned;
  String? hash;
}

enum UploadStatus {
  none,
  planned,
  uploaded,
  failed,
}

int fastHash(String string) {
  int hash = 0xcbf29ce484222325;

  int i = 0;
  while (i < string.length) {
    final int codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

import 'dart:io' as io;
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:moor/moor.dart';

import 'package:photoprism/model/photos.dart';
import 'package:photoprism/model/files.dart';
import 'package:photoprism/model/albums.dart';
import 'package:photoprism/model/photos_albums.dart';

part 'db.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final io.Directory dbFolder = await getApplicationDocumentsDirectory();
    final io.File file = io.File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file, logStatements: false);
  });
}

@UseMoor(tables: <Type>[Photos, Files, Albums, PhotosAlbums])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(_openConnection());

  Future<void> deleteDatabase() async {
    final io.Directory dbFolder = await getApplicationDocumentsDirectory();
    final io.File file = io.File(p.join(dbFolder.path, 'db.sqlite'));
    await file.delete();
  }

  Future<void> createOrUpdateMultiplePhotos(List<Photo> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(photos, rows));
  }

  Future<void> createOrUpdateMultipleFiles(List<File> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(files, rows));
  }

  Future<void> createOrUpdateMultipleAlbums(List<Album> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(albums, rows));
  }

  Future<void> createOrUpdateMultiplePhotosAlbums(
      List<PhotosAlbum> rows) async {
    await batch(
        (Batch batch) => batch.insertAllOnConflictUpdate(photosAlbums, rows));
  }

  Stream<List<Album>> get allAlbums => (select(albums)
        ..where(($AlbumsTable tbl) =>
            isNull(tbl.deletedAt) & tbl.type.equals('album')))
      .watch();

  Stream<Map<String, int>> allAlbumCounts() {
    final Expression<int> photoCount = photosAlbums.photoUID.count();

    final JoinedSelectStatement<Table, DataClass> query = (select(albums)
          ..where(($AlbumsTable tbl) =>
              isNull(tbl.deletedAt) & tbl.type.equals('album')))
        .join(<Join<Table, DataClass>>[
      innerJoin(photosAlbums, photosAlbums.albumUID.equalsExp(albums.uid),
          useColumns: false)
    ])
          ..where(photosAlbums.hidden.not())
          ..addColumns(<Expression<dynamic>>[photoCount])
          ..groupBy(<Expression<dynamic>>[albums.uid]);

    return query.watch().map((List<TypedResult> rows) => <String, int>{
          for (TypedResult row in rows)
            row.read(albums.uid): row.read(photoCount),
        });
  }

  Stream<List<PhotoWithFile>> photosWithFile(bool ascending,
      {String albumUid}) {
    JoinedSelectStatement<Table, DataClass> query;
    if (albumUid != null) {
      query = (select(photosAlbums)
            ..where(($PhotosAlbumsTable tbl) =>
                tbl.albumUID.equals(albumUid) & tbl.hidden.not()))
          .join(<Join<Table, DataClass>>[
        innerJoin(photos, photos.uid.equalsExp(photosAlbums.photoUID)),
      ]).join(<Join<Table, DataClass>>[
        innerJoin(files, files.photoUID.equalsExp(photos.uid)),
      ]);
    } else {
      query = select(photos).join(<Join<Table, DataClass>>[
        innerJoin(files, files.photoUID.equalsExp(photos.uid)),
      ]);
    }

    query = query
      ..where(isNotNull(files.hash) &
          files.primary &
          isNull(files.deletedAt) &
          isNull(photos.deletedAt) &
          isNotNull(photos.takenAt))
      ..orderBy(<OrderingTerm>[
        OrderingTerm(
            expression: photos.takenAt,
            mode: ascending ? OrderingMode.asc : OrderingMode.desc)
      ]);

    return query.watch().map((List<TypedResult> rows) {
      return rows.map((TypedResult row) {
        return PhotoWithFile(
          row.readTable(photos),
          row.readTable(files),
        );
      }).toList();
    });
  }

  @override
  int get schemaVersion => 1;
}

class CustomSerializer extends ValueSerializer {
  const CustomSerializer();
  @override
  T fromJson<T>(dynamic json) {
    if (T == DateTime) {
      if (json == null) {
        return null;
      } else {
        return DateTime.parse(json.toString()) as T;
      }
    } else if (T == double) {
      return double.parse(json.toString()) as T;
    } else {
      return json as T;
    }
  }

  @override
  dynamic toJson<T>(T value) {
    if (T == DateTime) {
      return (value as DateTime).toIso8601String();
    } else {
      return value;
    }
  }
}

class PhotoWithFile {
  PhotoWithFile(this.photo, this.file);

  final Photo photo;
  final File file;
}

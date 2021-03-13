import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:moor/moor.dart';
import 'package:photoprism/model/filter_photos.dart';

import 'package:photoprism/model/photos.dart';
import 'package:photoprism/model/files.dart';
import 'package:photoprism/model/albums.dart';
import 'package:photoprism/model/photos_albums.dart';

part 'db.g.dart';

@UseMoor(tables: <Type>[Photos, Files, Albums, PhotosAlbums])
class MyDatabase extends _$MyDatabase {
  MyDatabase(QueryExecutor e) : super(e);

  MyDatabase.connect(DatabaseConnection connection) : super.connect(connection);

  Future<void> deleteDatabase() async {
    final io.Directory dbFolder = await getApplicationDocumentsDirectory();
    final io.File file = io.File(p.join(dbFolder.path, 'db.sqlite'));
    await file.delete();
  }

  Future<void> createOrUpdateMultiplePhotos(List<PhotosCompanion> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(
          photos,
          rows,
        ));
  }

  Future<void> createOrUpdateMultipleFiles(List<FilesCompanion> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(files, rows));
  }

  Future<void> createOrUpdateMultipleAlbums(List<AlbumsCompanion> rows) async {
    await batch((Batch batch) => batch.insertAllOnConflictUpdate(albums, rows));
  }

  Future<void> createOrUpdateMultiplePhotosAlbums(
      List<PhotosAlbumsCompanion> rows) async {
    await batch(
        (Batch batch) => batch.insertAllOnConflictUpdate(photosAlbums, rows));
  }

  Stream<List<Album>> get allAlbums => (select(albums)
        ..where(($AlbumsTable tbl) =>
            tbl.deletedAt.isNull() & tbl.type.equals('album')))
      .watch();

  Future<List<File>> getFileFromHash(String hash) => ((select(files)
        ..where(
            ($FilesTable tbl) => tbl.hash.isNotNull() & tbl.hash.equals(hash)))
        ..limit(1))
      .get();

  Future<File> getVideoFileForPhoto(String photoUid) => ((select(files)
        ..where(($FilesTable tbl) =>
            tbl.photoUID.isNotNull() &
            tbl.photoUID.equals(photoUid) &
            tbl.video.isNotNull() &
            tbl.video &
            tbl.hash.isNotNull()))
        ..limit(1))
      .getSingle();

  Future<bool> isPhotoAlbum(String photoUid, String albumUid) async {
    final Future<List<PhotosAlbum>> result = (select(photosAlbums)
          ..where(($PhotosAlbumsTable tbl) =>
              tbl.photoUID.equals(photoUid) & tbl.albumUID.equals(albumUid)))
        .get();
    return (await result).isNotEmpty;
  }

  Stream<Map<String, int>> allAlbumCounts() {
    final Expression<int> photoCount = photosAlbums.photoUID.count();

    final JoinedSelectStatement<Table, DataClass> query = (select(albums)
          ..where(($AlbumsTable tbl) =>
              tbl.deletedAt.isNull() & tbl.type.equals('album')))
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

  JoinedSelectStatement<Table, DataClass> _photosWithFileQuery(
      FilterPhotos filterPhotos,
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

    GeneratedDateTimeColumn sortColumn;
    switch (filterPhotos.sort) {
      case PhotoSort.CreatedAt:
        sortColumn = photos.createdAt;
        break;
      case PhotoSort.TakenAt:
        sortColumn = photos.takenAt;
        break;
      case PhotoSort.UpdatedAt:
        sortColumn = photos.updatedAt;
        break;
      default:
        sortColumn = photos.takenAt;
    }

    if (filterPhotos.private == false) {
      query = query..where(photos.private.not());
    }

    return query
      ..where(files.hash.isNotNull() &
          files.primary.isNotNull() &
          files.primary &
          files.error.equals('') &
          files.deletedAt.isNull() &
          (filterPhotos.archived
              ? photos.deletedAt.isNotNull()
              : photos.deletedAt.isNull()) &
          photos.takenAt.isNotNull() &
          photos.type.isNotNull() &
          photos.type.isIn(filterPhotos.typesAsString))
      ..orderBy(<OrderingTerm>[
        OrderingTerm(expression: sortColumn, mode: filterPhotos.order)
      ]);
  }

  Future<Iterable<PhotoWithFile>> photosWithFile(
      int limit, int offset, FilterPhotos filterPhotos,
      {String albumUid}) {
    final JoinedSelectStatement<Table, DataClass> query =
        _photosWithFileQuery(filterPhotos, albumUid: albumUid);
    final Selectable<PhotoWithFile> result = (query
          ..limit(limit, offset: offset))
        .map((TypedResult row) => PhotoWithFile(
              row.readTable(photos),
              row.readTable(files),
            ));
    return result.get();
  }

  Stream<int> photosWithFileCount(FilterPhotos filterPhotos,
      {String albumUid}) {
    final JoinedSelectStatement<Table, DataClass> query =
        _photosWithFileQuery(filterPhotos, albumUid: albumUid);
    final Expression<int> filesCount = files.hash.count();

    return (query..addColumns(<Expression<int>>[filesCount]))
        .watchSingle()
        .map((TypedResult row) => row.read(filesCount));
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

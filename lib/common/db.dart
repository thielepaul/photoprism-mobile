import 'dart:io' as io;
import 'package:moor/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:moor/moor.dart';

import 'package:photoprism/model/photos.dart';
import 'package:photoprism/model/files.dart';

part 'db.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final io.Directory dbFolder = await getApplicationDocumentsDirectory();
    final io.File file = io.File(p.join(dbFolder.path, 'db.sqlite'));
    return VmDatabase(file, logStatements: false);
  });
}

@UseMoor(tables: <Type>[Photos, Files])
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

  Stream<List<PhotoWithFile>> photosWithFile(bool ascending) {
    final JoinedSelectStatement<Table, DataClass> query = select(photos)
        .join(<Join<Table, DataClass>>[
      innerJoin(files, files.photoUID.equalsExp(photos.uid)),
    ])
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

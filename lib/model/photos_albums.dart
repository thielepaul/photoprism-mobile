import 'package:drift/drift.dart';

class PhotosAlbums extends Table {
  @JsonKey('PhotoUID')
  TextColumn get photoUID => text()();
  @JsonKey('AlbumUID')
  TextColumn get albumUID => text()();
  @JsonKey('Order')
  IntColumn get order => integer().nullable()();
  @JsonKey('Hidden')
  BoolColumn get hidden => boolean().nullable()();
  @JsonKey('Missing')
  BoolColumn get missing => boolean().nullable()();
  @JsonKey('CreatedAt')
  DateTimeColumn get createdAt => dateTime().nullable()();
  @JsonKey('UpdatedAt')
  DateTimeColumn get updatedAt => dateTime().nullable()();
  @JsonKey('DeletedAt')
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<dynamic>> get primaryKey => <Column<dynamic>>{photoUID, albumUID};
}

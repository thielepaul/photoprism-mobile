import 'package:drift/drift.dart';

class Files extends Table {
  @JsonKey('PhotoUID')
  TextColumn get photoUID => text()();
  @JsonKey('UID')
  TextColumn get uid => text()();
  @JsonKey('Name')
  TextColumn? get name => text().nullable()();
  @JsonKey('Root')
  TextColumn? get root => text().nullable()();
  @JsonKey('OriginalName')
  TextColumn? get originalName => text().nullable()();
  @JsonKey('Hash')
  TextColumn get hash => text()();
  @JsonKey('Size')
  IntColumn? get size => integer().nullable()();
  @JsonKey('Codec')
  TextColumn? get codec => text().nullable()();
  @JsonKey('Type')
  TextColumn? get type => text().nullable()();
  @JsonKey('Mime')
  TextColumn? get mime => text().nullable()();
  @JsonKey('Primary')
  BoolColumn? get primary => boolean().nullable()();
  @JsonKey('Sidecar')
  BoolColumn? get sidecar => boolean().nullable()();
  @JsonKey('Missing')
  BoolColumn? get missing => boolean().nullable()();
  @JsonKey('Portrait')
  BoolColumn? get portrait => boolean().nullable()();
  @JsonKey('Video')
  BoolColumn? get video => boolean().nullable()();
  @JsonKey('Duration')
  IntColumn? get duration => integer().nullable()();
  @JsonKey('Width')
  IntColumn? get width => integer().nullable()();
  @JsonKey('Height')
  IntColumn? get height => integer().nullable()();
  @JsonKey('Orientation')
  IntColumn? get orientation => integer().nullable()();
  @JsonKey('AspectRatio')
  RealColumn? get aspectRatio => real().nullable()();
  @JsonKey('MainColor')
  TextColumn? get mainColor => text().nullable()();
  @JsonKey('Colors')
  TextColumn? get colors => text().nullable()();
  @JsonKey('Luminance')
  TextColumn? get luminance => text().nullable()();
  @JsonKey('Diff')
  IntColumn? get diff => integer().nullable()();
  @JsonKey('Chroma')
  IntColumn? get chroma => integer().nullable()();
  @JsonKey('Error')
  TextColumn? get error => text().nullable()();
  @JsonKey('ModTime')
  IntColumn? get modTime => integer().nullable()();
  @JsonKey('CreatedAt')
  DateTimeColumn? get createdAt => dateTime().nullable()();
  @JsonKey('CreatedIn')
  IntColumn? get createdIn => integer().nullable()();
  @JsonKey('UpdatedAt')
  DateTimeColumn? get updatedAt => dateTime().nullable()();
  @JsonKey('UpdatedIn')
  IntColumn? get updatedIn => integer().nullable()();
  @JsonKey('DeletedAt')
  DateTimeColumn? get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{uid};
}

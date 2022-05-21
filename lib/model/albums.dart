import 'package:drift/drift.dart';

class Albums extends Table {
  @JsonKey('ID')
  IntColumn get id => integer()();
  @JsonKey('UID')
  TextColumn get uid => text()();
  @JsonKey('CoverUID')
  TextColumn? get coverUID => text().nullable()();
  @JsonKey('FolderUID')
  TextColumn? get folderUID => text().nullable()();
  @JsonKey('Slug')
  TextColumn? get slug => text().nullable()();
  @JsonKey('Path')
  TextColumn? get path => text().nullable()();
  @JsonKey('Type')
  TextColumn? get type => text().nullable()();
  @JsonKey('Title')
  TextColumn? get title => text().nullable()();
  @JsonKey('Location')
  TextColumn? get location => text().nullable()();
  @JsonKey('Category')
  TextColumn? get category => text().nullable()();
  @JsonKey('Caption')
  TextColumn? get caption => text().nullable()();
  @JsonKey('Description')
  TextColumn? get description => text().nullable()();
  @JsonKey('Notes')
  TextColumn? get notes => text().nullable()();
  @JsonKey('Filter')
  TextColumn? get filter => text().nullable()();
  @JsonKey('Order')
  TextColumn? get order => text().nullable()();
  @JsonKey('Template')
  TextColumn? get template => text().nullable()();
  @JsonKey('Country')
  TextColumn? get country => text().nullable()();
  @JsonKey('Year')
  IntColumn? get year => integer().nullable()();
  @JsonKey('Month')
  IntColumn? get month => integer().nullable()();
  @JsonKey('Day')
  IntColumn? get day => integer().nullable()();
  @JsonKey('Favorite')
  BoolColumn? get favorite => boolean().nullable()();
  @JsonKey('Private')
  BoolColumn? get private => boolean().nullable()();
  @JsonKey('CreatedAt')
  DateTimeColumn? get createdAt => dateTime().nullable()();
  @JsonKey('UpdatedAt')
  DateTimeColumn? get updatedAt => dateTime().nullable()();
  @JsonKey('DeletedAt')
  DateTimeColumn? get deletedAt => dateTime().nullable()();

  @override
  Set<Column<dynamic>> get primaryKey => <Column<dynamic>>{id};
}

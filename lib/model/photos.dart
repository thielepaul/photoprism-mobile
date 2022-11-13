import 'package:drift/drift.dart';

class Photos extends Table {
  @JsonKey('ID')
  IntColumn get id => integer()();
  @JsonKey('TakenAt')
  DateTimeColumn? get takenAt => dateTime().nullable()();
  @JsonKey('TakenAtLocal')
  DateTimeColumn? get takenAtLocal => dateTime().nullable()();
  @JsonKey('TakenSrc')
  TextColumn? get takenSrc => text().nullable()();
  @JsonKey('UID')
  TextColumn get uid => text()();
  @JsonKey('Type')
  TextColumn? get type => text().nullable()();
  @JsonKey('TypeSrc')
  TextColumn? get typeSrc => text().nullable()();
  @JsonKey('Title')
  TextColumn? get title => text().nullable()();
  @JsonKey('TitleSrc')
  TextColumn? get titleSrc => text().nullable()();
  @JsonKey('Description')
  TextColumn? get description => text().nullable()();
  @JsonKey('DescriptionSrc')
  TextColumn? get descriptionSrc => text().nullable()();
  @JsonKey('Path')
  TextColumn? get path => text().nullable()();
  @JsonKey('Name')
  TextColumn? get name => text().nullable()();
  @JsonKey('OriginalName')
  TextColumn? get originalName => text().nullable()();
  @JsonKey('Stack')
  IntColumn? get stack => integer().nullable()();
  @JsonKey('Favorite')
  BoolColumn? get favorite => boolean().nullable()();
  @JsonKey('Private')
  BoolColumn? get private => boolean().nullable()();
  @JsonKey('Scan')
  BoolColumn? get scan => boolean().nullable()();
  @JsonKey('Panorama')
  BoolColumn? get panorama => boolean().nullable()();
  @JsonKey('TimeZone')
  TextColumn? get timeZone => text().nullable()();
  @JsonKey('PlaceID')
  TextColumn? get placeID => text().nullable()();
  @JsonKey('PlaceSrc')
  TextColumn? get placeSrc => text().nullable()();
  @JsonKey('CellID')
  TextColumn? get cellID => text().nullable()();
  @JsonKey('CellAccuracy')
  IntColumn? get cellAccuracy => integer().nullable()();
  @JsonKey('Altitude')
  IntColumn? get altitude => integer().nullable()();
  @JsonKey('Lat')
  RealColumn? get lat => real().nullable()();
  @JsonKey('Lng')
  RealColumn? get lng => real().nullable()();
  @JsonKey('Country')
  TextColumn? get country => text().nullable()();
  @JsonKey('Year')
  IntColumn? get year => integer().nullable()();
  @JsonKey('Month')
  IntColumn? get month => integer().nullable()();
  @JsonKey('Day')
  IntColumn? get day => integer().nullable()();
  @JsonKey('Iso')
  IntColumn? get iso => integer().nullable()();
  @JsonKey('Exposure')
  TextColumn? get exposure => text().nullable()();
  @JsonKey('FNumber')
  RealColumn? get fNumber => real().nullable()();
  @JsonKey('FocalLength')
  IntColumn? get focalLength => integer().nullable()();
  @JsonKey('Quality')
  IntColumn? get quality => integer().nullable()();
  @JsonKey('Resolution')
  IntColumn? get resolution => integer().nullable()();
  @JsonKey('Color')
  IntColumn? get color => integer().nullable()();
  @JsonKey('CameraID')
  IntColumn? get cameraID => integer().nullable()();
  @JsonKey('CameraSerial')
  TextColumn? get cameraSerial => text().nullable()();
  @JsonKey('CameraSrc')
  TextColumn? get cameraSrc => text().nullable()();
  @JsonKey('LensID')
  IntColumn? get lensID => integer().nullable()();
  @JsonKey('CreatedAt')
  DateTimeColumn? get createdAt => dateTime().nullable()();
  @JsonKey('UpdatedAt')
  DateTimeColumn? get updatedAt => dateTime().nullable()();
  @JsonKey('EditedAt')
  DateTimeColumn? get editedAt => dateTime().nullable()();
  @JsonKey('CheckedAt')
  DateTimeColumn? get checkedAt => dateTime().nullable()();
  @JsonKey('DeletedAt')
  DateTimeColumn? get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

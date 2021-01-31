import 'package:moor/moor.dart';

class Photos extends Table {
  @JsonKey('ID')
  IntColumn get id => integer()();
  @JsonKey('TakenAt')
  DateTimeColumn get takenAt => dateTime().nullable()();
  // @JsonKey('TakenAtLocal')
  // DateTimeColumn get takenAtLocal => dateTime().nullable()();
  // @JsonKey('TakenSrc')
  // TextColumn get takenSrc => text()();
  @JsonKey('UID')
  TextColumn get uid => text()();
  @JsonKey('Type')
  TextColumn get type => text()();
  // @JsonKey('TypeSrc')
  // TextColumn get typeSrc => text()();
  // @JsonKey('Title')
  // TextColumn get title => text()();
  // @JsonKey('TitleSrc')
  // TextColumn get titleSrc => text()();
  // @JsonKey('Description')
  // TextColumn get description => text()();
  // @JsonKey('DescriptionSrc')
  // TextColumn get descriptionSrc => text()();
  // @JsonKey('Path')
  // TextColumn get path => text()();
  // @JsonKey('Name')
  // TextColumn get name => text()();
  // @JsonKey('OriginalName')
  // TextColumn get originalName => text()();
  // @JsonKey('Stack')
  // IntColumn get stack => integer()();
  // @JsonKey('Favorite')
  // BoolColumn get favorite => boolean()();
  // @JsonKey('Private')
  // BoolColumn get private => boolean()();
  // @JsonKey('Scan')
  // BoolColumn get scan => boolean()();
  // @JsonKey('Panorama')
  // BoolColumn get panorama => boolean()();
  // @JsonKey('TimeZone')
  // TextColumn get timeZone => text()();
  // @JsonKey('PlaceID')
  // TextColumn get placeID => text()();
  // @JsonKey('PlaceSrc')
  // TextColumn get placeSrc => text()();
  // @JsonKey('CellID')
  // TextColumn get cellID => text()();
  // @JsonKey('CellAccuracy')
  // IntColumn get cellAccuracy => integer()();
  // @JsonKey('Altitude')
  // IntColumn get altitude => integer()();
  // @JsonKey('Lat')
  // RealColumn get lat => real()();
  // @JsonKey('Lng')
  // RealColumn get lng => real()();
  // @JsonKey('Country')
  // TextColumn get country => text()();
  // @JsonKey('Year')
  // IntColumn get year => integer()();
  // @JsonKey('Month')
  // IntColumn get month => integer()();
  // @JsonKey('Day')
  // IntColumn get day => integer()();
  // @JsonKey('Iso')
  // IntColumn get iso => integer()();
  // @JsonKey('Exposure')
  // TextColumn get exposure => text()();
  // @JsonKey('FNumber')
  // RealColumn get fNumber => real()();
  // @JsonKey('FocalLength')
  // IntColumn get focalLength => integer()();
  // @JsonKey('Quality')
  // IntColumn get quality => integer()();
  // @JsonKey('Resolution')
  // IntColumn get resolution => integer()();
  // @JsonKey('Color')
  // IntColumn get color => integer()();
  // @JsonKey('CameraID')
  // IntColumn get cameraID => integer()();
  // @JsonKey('CameraSerial')
  // TextColumn get cameraSerial => text()();
  // @JsonKey('CameraSrc')
  // TextColumn get cameraSrc => text()();
  // @JsonKey('LensID')
  // IntColumn get lensID => integer()();
  // @JsonKey('CreatedAt')
  // DateTimeColumn get createdAt => dateTime().nullable()();
  @JsonKey('UpdatedAt')
  DateTimeColumn get updatedAt => dateTime().nullable()();
  // @JsonKey('EditedAt')
  // DateTimeColumn get editedAt => dateTime().nullable()();
  // @JsonKey('CheckedAt')
  // DateTimeColumn get checkedAt => dateTime().nullable()();
  @JsonKey('DeletedAt')
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<dynamic>> get primaryKey => <Column<dynamic>>{id};
}

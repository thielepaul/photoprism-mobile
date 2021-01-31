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
  // @JsonKey('Type')
  // TextColumn get type => text()();
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

// class Photo {
//   Photo({
//     this.id,
//     this.takenAt,
//     this.takenAtLocal,
//     this.takenSrc,
//     this.uid,
//     this.type,
//     this.typeSrc,
//     this.title,
//     this.titleSrc,
//     this.description,
//     this.descriptionSrc,
//     this.path,
//     this.name,
//     this.originalName,
//     this.stack,
//     this.favorite,
//     this.private,
//     this.scan,
//     this.panorama,
//     this.timeZone,
//     this.placeID,
//     this.placeSrc,
//     this.cellID,
//     this.cellAccuracy,
//     this.altitude,
//     this.lat,
//     this.lng,
//     this.country,
//     this.year,
//     this.month,
//     this.day,
//     this.iso,
//     this.exposure,
//     this.fNumber,
//     this.focalLength,
//     this.quality,
//     this.resolution,
//     this.color,
//     this.cameraID,
//     this.cameraSerial,
//     this.cameraSrc,
//     this.lensID,
//     this.createdAt,
//     this.updatedAt,
//     this.editedAt,
//     this.checkedAt,
//     this.deletedAt,
//   });
//   factory Photo.fromJson(Map<String, dynamic> json) {
//     return Photo(
//       id: json['ID'] as int,
//       takenAt: json['TakenAt'] as DateTime,
//       takenAtLocal: json['TakenAtLocal'] as DateTime,
//       takenSrc: json['TakenSrc'] as String,
//       uid: json['UID'] as String,
//       type: json['Type'] as String,
//       typeSrc: json['TypeSrc'] as String,
//       title: json['Title'] as String,
//       titleSrc: json['TitleSrc'] as String,
//       description: json['Description'] as String,
//       descriptionSrc: json['DescriptionSrc'] as String,
//       path: json['Path'] as String,
//       name: json['Name'] as String,
//       originalName: json['OriginalName'] as String,
//       stack: json['Stack'] as int,
//       favorite: json['Favorite'] as bool,
//       private: json['Private'] as bool,
//       scan: json['Scan'] as bool,
//       panorama: json['Panorama'] as bool,
//       timeZone: json['TimeZone'] as String,
//       placeID: json['PlaceID'] as String,
//       placeSrc: json['PlaceSrc'] as String,
//       cellID: json['CellID'] as String,
//       cellAccuracy: json['CellAccuracy'] as int,
//       altitude: json['Altitude'] as int,
//       lat: json['Lat'] as double,
//       lng: json['Lng'] as double,
//       country: json['Country'] as String,
//       year: json['Year'] as int,
//       month: json['Month'] as int,
//       day: json['Day'] as int,
//       iso: json['Iso'] as int,
//       exposure: json['Exposure'] as String,
//       fNumber: json['FNumber'] as double,
//       focalLength: json['FocalLength'] as int,
//       quality: json['Quality'] as int,
//       resolution: json['Resolution'] as int,
//       color: json['Color'] as int,
//       cameraID: json['CameraID'] as int,
//       cameraSerial: json['CameraSerial'] as String,
//       cameraSrc: json['CameraSrc'] as String,
//       lensID: json['LensID'] as int,
//       createdAt: json['CreatedAt'] as DateTime,
//       updatedAt: json['UpdatedAt'] as DateTime,
//       editedAt: json['EditedAt'] as DateTime,
//       checkedAt: json['CheckedAt'] as DateTime,
//       deletedAt: json['DeletedAt'] as DateTime,
//     );
//   }

//   bool get isVideo => false;
//   double get aspectRatio => 1;
//   String get hash => '';
//   String get videoHash => '';

//   final int id;
//   final DateTime takenAt;
//   final DateTime takenAtLocal;
//   final String takenSrc;
//   final String uid;
//   final String type;
//   final String typeSrc;
//   final String title;
//   final String titleSrc;
//   final String description;
//   final String descriptionSrc;
//   final String path;
//   final String name;
//   final String originalName;
//   final int stack;
//   final bool favorite;
//   final bool private;
//   final bool scan;
//   final bool panorama;
//   final String timeZone;
//   final String placeID;
//   final String placeSrc;
//   final String cellID;
//   final int cellAccuracy;
//   final int altitude;
//   final double lat;
//   final double lng;
//   final String country;
//   final int year;
//   final int month;
//   final int day;
//   final int iso;
//   final String exposure;
//   final double fNumber;
//   final int focalLength;
//   final int quality;
//   final int resolution;
//   final int color;
//   final int cameraID;
//   final String cameraSerial;
//   final String cameraSrc;
//   final int lensID;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final DateTime editedAt;
//   final DateTime checkedAt;
//   final DateTime deletedAt;
// }

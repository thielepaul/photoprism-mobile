import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:moor/moor.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PhotoSort { TakenAt, CreatedAt, UpdatedAt }
enum PhotoType { Image, Live, Video }

class FilterPhotos {
  FilterPhotos(
      {this.order = OrderingMode.desc,
      this.sort = PhotoSort.TakenAt,
      Set<PhotoType> types = const <PhotoType>{
        PhotoType.Image,
        PhotoType.Live,
        PhotoType.Video
      },
      this.archived = false,
      this.private = true}) {
    this.types = types.toSet();
  }

  factory FilterPhotos.fromJson(Map<String, dynamic> json) {
    return FilterPhotos(
      order:
          EnumToString.fromString(OrderingMode.values, json['order'] as String),
      sort: EnumToString.fromString(PhotoSort.values, json['sort'] as String),
      types: (json['types'] as List<dynamic>)
          .map((dynamic v) =>
              EnumToString.fromString(PhotoType.values, v as String))
          .toSet(),
      archived: json['archived'] as bool,
      private: json['private'] as bool,
    );
  }

  static Future<FilterPhotos> fromSharedPrefs() async {
    print('load FilterPhotos from sharedprefs');
    final SharedPreferences sp = await SharedPreferences.getInstance();

    if (sp.containsKey(_spKey)) {
      print('found FilterPhotos in sharedprefs: ' + sp.getString(_spKey));
      try {
        return FilterPhotos.fromJson(
            json.decode(sp.getString(_spKey)) as Map<String, dynamic>);
      } catch (e) {
        print(e);
        sp.remove(_spKey);
      }
    }
    return FilterPhotos();
  }

  static const String _spKey = 'defaultFilterPhotos';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'order': EnumToString.convertToString(order),
        'sort': EnumToString.convertToString(sort),
        'types': types
            .map((PhotoType e) => EnumToString.convertToString(e))
            .toList(),
        'archived': archived,
        'private': private,
      };

  OrderingMode order = OrderingMode.desc;
  PhotoSort sort = PhotoSort.TakenAt;
  Set<PhotoType> types = <PhotoType>{PhotoType.Image, PhotoType.Live};
  bool archived = false;
  bool private = true;

  Iterable<String> get typesAsString =>
      EnumToString.toList(types.toList()).map((String s) => s.toLowerCase());

  Future<void> saveTosharedPrefs() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(_spKey, json.encode(toJson()));
  }
}

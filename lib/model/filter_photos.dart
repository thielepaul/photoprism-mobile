import 'package:enum_to_string/enum_to_string.dart';
import 'package:moor/moor.dart';

enum PhotoSort { TakenAt, CreatedAt, UpdatedAt }
enum PhotoType { Image, Live, Video }

class FilterPhotos {
  OrderingMode order = OrderingMode.desc;
  PhotoSort sort = PhotoSort.TakenAt;
  Set<PhotoType> types = <PhotoType>{PhotoType.Image, PhotoType.Live};
  Iterable<String> get typesAsString =>
      EnumToString.toList(types.toList()).map((String s) => s.toLowerCase());
  bool archived = false;
}

import 'dart:math';

import 'package:photoprism/common/db.dart';
import 'package:photoprism/model/photoprism_model.dart';
import 'package:synchronized/synchronized.dart';

class PhotosFromDb {
  PhotosFromDb(PhotoprismModel model) : _model = model;
  final PhotoprismModel _model;
  int _count = 0;
  int get length => _count;
  bool get isEmpty => _count == 0;
  set count(int value) {
    _count = value;
    _cache = <int, PhotoWithFile>{};
  }

  Map<int, PhotoWithFile> _cache = <int, PhotoWithFile>{};
  final Lock _dbLock = Lock();

  PhotoWithFile getNow(int index) {
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    return null;
  }

  Future<PhotoWithFile> operator [](int index) async {
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    return await _dbLock.synchronized(() async {
      if (_cache.containsKey(index)) {
        return _cache[index];
      }
      final Stopwatch stopwatch = Stopwatch()..start();
      _cache = <int, PhotoWithFile>{};
      const int limit = 500;
      final int offset = max(0, index - (limit / 2).round());
      final Iterable<PhotoWithFile> results = await _model.database
          .photosWithFile(limit, offset, _model.filterPhotos,
              albumUid: _model.albumUid);
      int i = offset;
      for (final PhotoWithFile result in results) {
        _cache[i] = result;
        i++;
      }
      print('filling photo metadata cache took '
          '${stopwatch.elapsed.inMilliseconds} ms');
      return _cache[index];
    });
  }
}

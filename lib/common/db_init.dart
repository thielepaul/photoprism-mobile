import 'dart:async';
import 'dart:io' as io;
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photoprism/common/db.dart';

Future<MyDatabase> connectDbAsync() async {
  final DriftIsolate isolate = await _createMoorIsolate();
  return MyDatabase.connect(await isolate.connect());
}

Future<DriftIsolate> _createMoorIsolate() async {
  final io.Directory dir = await getApplicationDocumentsDirectory();
  final String path = p.join(dir.path, 'db.sqlite');
  final ReceivePort receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  return await receivePort.first as DriftIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  final NativeDatabase executor = NativeDatabase(io.File(request.targetPath));
  final DriftIsolate moorIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection(executor),
  );
  request.sendMoorIsolate.send(moorIsolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);

  final SendPort sendMoorIsolate;
  final String targetPath;
}

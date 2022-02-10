import 'dart:io' as io;
import 'dart:isolate';

import 'package:moor/ffi.dart';
import 'package:moor/isolate.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photoprism/common/db.dart';

Future<MyDatabase> connectDbAsync() async {
  final MoorIsolate isolate = await _createMoorIsolate();
  return MyDatabase.connect(await isolate.connect());
}

Future<MoorIsolate> _createMoorIsolate() async {
  final io.Directory dir = await getApplicationDocumentsDirectory();
  final String path = p.join(dir.path, 'db.sqlite');
  final ReceivePort receivePort = ReceivePort();

  await Isolate.spawn(
    _startBackground,
    _IsolateStartRequest(receivePort.sendPort, path),
  );

  return await receivePort.first as MoorIsolate;
}

void _startBackground(_IsolateStartRequest request) {
  final VmDatabase executor = VmDatabase(io.File(request.targetPath));
  final MoorIsolate moorIsolate = MoorIsolate.inCurrent(
    () => DatabaseConnection.fromExecutor(executor),
  );
  request.sendMoorIsolate.send(moorIsolate);
}

class _IsolateStartRequest {
  _IsolateStartRequest(this.sendMoorIsolate, this.targetPath);

  final SendPort sendMoorIsolate;
  final String targetPath;
}

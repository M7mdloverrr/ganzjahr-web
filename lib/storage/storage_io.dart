import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _file(String name) async => File('${(await getApplicationDocumentsDirectory()).path}/$name');

Future<String?> readData(String name) async {
  final f = await _file(name);
  return await f.exists() ? f.readAsString() : null;
}

Future<void> writeData(String name, String data) async {
  final f = await _file(name);
  final tmp = File('${f.path}.tmp');
  await tmp.writeAsString(data, flush: true);
  await tmp.rename(f.path);
}

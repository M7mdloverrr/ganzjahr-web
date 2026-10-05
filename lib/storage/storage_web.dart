import 'package:web/web.dart' as web;

Future<String?> readData(String name) async => web.window.localStorage.getItem('ganzjahr/$name');

Future<void> writeData(String name, String data) async => web.window.localStorage.setItem('ganzjahr/$name', data);

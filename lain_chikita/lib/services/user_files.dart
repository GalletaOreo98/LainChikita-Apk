import 'dart:io' show Directory, File, Platform;

import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;

import 'translations.dart';

/// Escribe un THANKS.txt con el nombre del usuario en
/// `<almacenamiento de la app>/lain_chikita/README/THANKS.txt`
/// (en Android es el almacenamiento externo de la app, ej: Android/data/com.oreodev.lain_chikita/files).
Future<void> writeThankYouFile(String userName) async {
  final readmeDir = Directory('${(await _appStorageDirectory()).path}/README');
  await readmeDir.create(recursive: true);
  await File('${readmeDir.path}/THANKS.txt').writeAsString('${tr('thank-you-for-installing')} $userName');
}

Future<Directory> _appStorageDirectory() async {
  final baseDir = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
  return Directory('${baseDir!.path}/lain_chikita');
}

import 'dart:io';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;
import '../global_vars.dart';
import '../functions/directory_path_provider.dart' show AppFolders;

Future<void> writeAThankUTxt() async {
  Directory? directory;
  if (platformName == "android") {
    directory = await getExternalStorageDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  directory!.path;
  Directory outputDir = await Directory("${directory.path}/${AppFolders.readme}").create();
  final File file = File('${outputDir.path}/THANKS.txt');
  await file.writeAsString("Gracias por instalar lain_chikita, amable senior $username");
}

Future<void> createAppFolders() async {
  await Directory("${appDirectoryStorage.path}/${AppFolders.imagesToEncrypt}").create();
  await Directory("${appDirectoryStorage.path}/${AppFolders.encryptedImages}").create();
  await Directory("${appDirectoryStorage.path}/${AppFolders.decryptedImages}").create();
}

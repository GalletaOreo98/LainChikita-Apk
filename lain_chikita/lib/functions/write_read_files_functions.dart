import 'dart:io';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;

//My imports
import '../global_vars.dart' as global_vars show appDirectoryStorage, languageDataManager, platformName, userName;
import '../functions/directory_path_provider.dart' show AppFolders;

Future<void> writeAThankUTxt() async {
  Directory? directory;
  if (global_vars.platformName == "android") {
    directory = await getExternalStorageDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  await Directory("${directory!.path}/lain_chikita").create();
  directory = Directory("${directory.path}/lain_chikita");
  Directory outputDir = await Directory("${directory.path}/${AppFolders.readme}").create();
  final File file = File('${outputDir.path}/THANKS.txt');
  await file.writeAsString("${global_vars.languageDataManager.getLabel('thank-you-for-installing')} ${global_vars.userName}");
}

Future<void> createEncryptionFolders() async {
  await Directory("${global_vars.appDirectoryStorage.path}/${AppFolders.imagesToEncrypt}").create();
  await Directory("${global_vars.appDirectoryStorage.path}/${AppFolders.encryptedImages}").create();
  await Directory("${global_vars.appDirectoryStorage.path}/${AppFolders.decryptedImages}").create();
}
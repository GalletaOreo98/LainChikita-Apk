import 'dart:io';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;
import 'dart:convert' show json;
import 'package:flutter/services.dart' show rootBundle;

//My imports
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
  await file.writeAsString("${languageDataManager.getLabel('thank-you-for-installing')} $userName");
}

Future<void> createEncryptionFolders() async {
  await Directory("${appDirectoryStorage.path}/${AppFolders.imagesToEncrypt}").create();
  await Directory("${appDirectoryStorage.path}/${AppFolders.encryptedImages}").create();
  await Directory("${appDirectoryStorage.path}/${AppFolders.decryptedImages}").create();
}
Future<void> createModsFolder() async {
  Directory outputDir = await Directory("${appDirectoryStorage.path}/${AppFolders.mods}").create();
  final imagePath = '${outputDir.path}/skin.png';
  final configPath = '${outputDir.path}/config.txt';
  final File imageFile = File(imagePath);
  final File configFile = File(configPath);
  final bool imageExists = await imageFile.exists();
  final bool configExists = await configFile.exists();

  final accessoryNamesString = await rootBundle.load('assets/images/skin.png');
  final imgBytes = accessoryNamesString.buffer.asUint8List();

  if (!imageExists || !configExists) {
    final jsonImagePath = json.encode({
      'image': imagePath,
      'showskin': true,
    });
  
    await configFile.writeAsString(jsonImagePath);
    await imageFile.writeAsBytes(imgBytes);
  }
}
import 'dart:io' show Directory;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;

//My imports
import '../global_vars.dart' show platformName;

class AppFolders {
  static String imagesToEncrypt = 'FILES_TO_ENCRYPT';
  static String encryptedImages = 'ENCRYPTED_FILES';
  static String decryptedImages = 'DECRYPTED_FILES';
  static String readme = 'README';
}

/// Consigue el path donde se almacenan los archivos de la app en el sistema
/// 
/// Example: user/0/com.oreodev.lain_chikita/files
Future<Directory> getAppDirectoryStorage() async{
  Directory? directory;
  if (platformName == "android") {
    directory = await getExternalStorageDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  directory!.path;
  return directory;
}

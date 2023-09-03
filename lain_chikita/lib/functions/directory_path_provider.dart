import 'dart:io' show Directory;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getExternalStorageDirectory;
import '../global_vars.dart' show platformName;

class AppFolders {
  static String imagesToEncrypt = 'IMAGES_TO_ENCRYPT';
  static String encryptedImages= 'ENCRYPTED_IMAGES';
  static String decryptedImages= 'DECRYPTED_IMAGES';
  static String readme= 'README';
}

/// Consigue el path donde se almacenan los archivos de la app en el sistema
/// 
/// Example: user/0/com.example.lain_chikita/files
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

import 'dart:io' show File, Directory;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart' show Uuid;
import 'package:uuid/uuid_util.dart';
import 'package:path/path.dart' as p;
import 'dart:isolate';

//My imports
import '../functions/directory_path_provider.dart' show AppFolders;
import '../global_vars.dart';

String encryptData(String jsonData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final encrypted = encrypter.encrypt(jsonData, iv: iv);
  return iv.base16 + encrypted.base16;
}

String decryptData(String encryptedData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final iv16 = encryptedData.substring(0, 32);
  final iv = encrypt.IV.fromBase16(iv16);
  encryptedData = encryptedData.substring(32);
  final encrypted = encrypt.Encrypted.fromBase16(encryptedData);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);
  return decrypted;
}

String generateCryptoRngUuid() {
  Uuid uuid = const Uuid();
  final v4Crypto = uuid.v4(options: {'rng': UuidUtil.cryptoRNG});
  return v4Crypto;
}

void encryptFileSync(File imageFile, String outputPath, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromLength(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final imageBytes = imageFile.readAsBytesSync();
  final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);
  final encryptedImageFile = File(outputPath);
  encryptedImageFile.writeAsBytesSync(encrypted.bytes);
}

void decryptFileSync(File encryptedImageFile, String outputPath, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromLength(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final encryptedImageBytes = encryptedImageFile.readAsBytesSync();
  final encrypted = encrypt.Encrypted(encryptedImageBytes);
  final decryptedImageBytes = encrypter.decryptBytes(encrypted, iv: iv);
  // Cambia la ruta según donde quieras guardar la imagen desencriptada
  final decryptedImageFile = File(outputPath);
  decryptedImageFile.writeAsBytesSync(decryptedImageBytes);
}

/*
Se usa Isolate para hacer algo así como una simulación de hilos y que no detenga el hilo principal mientras se encriptan
archivos. Aún así se obliga a que se encripte archivo por archivo, y no varios a la vez, esto para que no consuma
demasiados recursos y así pueda dejarse la app en segundo plano, por lo que solo estará el hilo principal y el hilo
de encriptación del archivo que se este encriptando en ese momento. Esto aplica también para la desencriptación.
*/

Future<int> useIsolateEncryption(String filePath, String outDir, String secretKey) async {
  final ReceivePort receivePort = ReceivePort();
  try {
    await Isolate.spawn(encryptFilesWithIsolate, [receivePort.sendPort, filePath, outDir, secretKey]);
  } on Object {
    receivePort.close();
    return 1;
  }
  await receivePort.first;
  return 0;
}

int encryptFilesWithIsolate(List<dynamic> args) {
  SendPort resultPort = args[0];
  encryptFileSync(File(args[1]), args[2], args[3]);
  Isolate.exit(resultPort, 0);
}

Future<int> useIsolateDecryption(String filePath, String outDir, String secretKey) async {
  final ReceivePort receivePort = ReceivePort();
  try {
    await Isolate.spawn(decryptFilesWithIsolate, [receivePort.sendPort, filePath, outDir, secretKey]);
  } on Object {
    receivePort.close();
    return 1;
  }
  await receivePort.first;
  return 0;
}

int decryptFilesWithIsolate(List<dynamic> args) {
  SendPort resultPort = args[0];
  decryptFileSync(File(args[1]), args[2], args[3]);
  Isolate.exit(resultPort, 0);
}

Future<void> encryptFiles(String secretKey, void Function(int, int) callback) async {
  final userFilesList = await Directory('${appDirectoryStorage.path}/${AppFolders.imagesToEncrypt}').list().toList();
  int totalIterations = userFilesList.length;
  for (var i = 0; i < totalIterations; i++) {
    callback(i + 1, totalIterations);
    String filePath = userFilesList[i].path;
    String fileBasename = p.basename(filePath); //nombre + la extension, ejemplo: my_archivo.png
    String outPath = "${appDirectoryStorage.path}/${AppFolders.encryptedImages}/$fileBasename";
    await useIsolateEncryption(filePath, outPath, secretKey);
  }
}

Future<void> decryptFiles(String secretKey, void Function(int, int) callback) async {
  final userFilesList = await Directory('${appDirectoryStorage.path}/${AppFolders.encryptedImages}').list().toList();
  int totalIterations = userFilesList.length;
  for (var i = 0; i < totalIterations; i++) {
    callback(i + 1, totalIterations);
    String filePath = userFilesList[i].path;
    String fileBasename = p.basename(filePath);
    String outPath = "${appDirectoryStorage.path}/${AppFolders.decryptedImages}/$fileBasename";
    await useIsolateDecryption(filePath, outPath, secretKey);
  }
}

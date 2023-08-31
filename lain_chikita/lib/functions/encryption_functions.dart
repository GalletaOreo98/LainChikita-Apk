import 'dart:io' show File;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart' show Uuid;
import 'package:uuid/uuid_util.dart';

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

String generateCryptoRngUuid(){
  Uuid uuid = const Uuid();
  final v4Crypto = uuid.v4(options: {'rng': UuidUtil.cryptoRNG});
  return v4Crypto;
}

String encryptImage(File imageFile, String secretKey){
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromLength(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final imageBytes = imageFile.readAsBytesSync();
  final encrypted = encrypter.encryptBytes(imageBytes, iv: iv);
  final encryptedImageFile = File('$appPathStorage/path_to_encrypted_image'); // Cambia la ruta según donde quieras guardar la imagen encriptada
  encryptedImageFile.writeAsBytesSync(encrypted.bytes);
  return encryptedImageFile.path;
}

File decryptImage(String encryptedImagePath, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromLength(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final encryptedImageBytes = File('$appPathStorage/path_to_encrypted_image').readAsBytesSync();
  final encrypted = encrypt.Encrypted(encryptedImageBytes);
  final decryptedImageBytes = encrypter.decryptBytes(encrypted, iv: iv);
  final decryptedImageFile = File('$appPathStorage/path_to_decrypted_image.png'); // Cambia la ruta según donde quieras guardar la imagen desencriptada
  decryptedImageFile.writeAsBytesSync(decryptedImageBytes);
  return decryptedImageFile;
}
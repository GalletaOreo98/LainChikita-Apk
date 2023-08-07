import 'package:encrypt/encrypt.dart' as encrypt;

String encryptData(String jsonData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final encrypted = encrypter.encrypt(jsonData, iv: iv);
  return encrypted.base16 + iv.base16;
}

String decryptData(String encryptedData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  final iv16 = encryptedData.substring(32, 64);
  final iv = encrypt.IV.fromBase16(iv16);
  encryptedData = encryptedData.substring(0, 32);
  final encrypted = encrypt.Encrypted.fromBase16(encryptedData);
  final decrypted = encrypter.decrypt(encrypted, iv: iv);
  return decrypted;
}
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:convert';

String encryptData(String jsonData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final encrypted = encrypter.encrypt(jsonData, iv: iv);
  final iv2 = encrypt.IV.fromLength(16);
  final jsonDataAndIV =
      json.encode({"data": encrypted.base64, "iv": iv.base64});
  final encrypted2 = encrypter.encrypt(jsonDataAndIV, iv: iv2);
  return encrypted2.base64;
}

String decryptData(String encryptedData, String secretKey) {
  final key = encrypt.Key.fromUtf8(secretKey);
  final encrypter = encrypt.Encrypter(encrypt.AES(key));
  final iv2 = encrypt.IV.fromLength(16);
  final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
  final decrypted = encrypter.decrypt(encrypted, iv: iv2);
  Map<String, dynamic> json = jsonDecode(decrypted);
  final ivD = encrypt.IV.fromBase64(json.values.last);
  final encrypted2 = encrypt.Encrypted.fromBase64(json.values.first);
  final decrypted2 = encrypter.decrypt(encrypted2, iv: ivD);
  return decrypted2;
}

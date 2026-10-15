import 'dart:math' show Random;

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/data.dart' show V4Options;
import 'package:uuid/rng.dart' show CryptoRNG;
import 'package:uuid/uuid.dart' show Uuid;

/// Encripta [data] con AES-CBC. Devuelve `IV (hex) + datos encriptados (hex)`.
///
/// La app no la usa directamente, pero es la forma de generar los códigos canjeables:
/// `encryptData('{"id":"<id del código>"}', SECRET_KEY)`.
String encryptData(String data, String secretKey) {
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypted = _aes(secretKey).encrypt(data, iv: iv);
  return iv.base16 + encrypted.base16;
}

/// Inverso de [encryptData]. Lanza excepción si los datos no son válidos
String decryptData(String encryptedData, String secretKey) {
  // Los primeros 32 caracteres hex son los 16 bytes del IV
  final iv = encrypt.IV.fromBase16(encryptedData.substring(0, 32));
  final encrypted = encrypt.Encrypted.fromBase16(encryptedData.substring(32));
  return _aes(secretKey).decrypt(encrypted, iv: iv);
}

String generateCryptoRngUuid() {
  return const Uuid().v4(config: V4Options(const CryptoRNG().generate(), const CryptoRNG()));
}

/// Genera un IV aleatorio seguro de [length] bytes y lo devuelve en hex
String generateUserIv(int length) => encrypt.IV.fromSecureRandom(length).base16;

/// Genera una llave alfanumérica aleatoria segura de [length] caracteres
String generateUserSecretKey(int length) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

encrypt.Encrypter _aes(String secretKey) {
  return encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(secretKey), mode: encrypt.AESMode.cbc));
}

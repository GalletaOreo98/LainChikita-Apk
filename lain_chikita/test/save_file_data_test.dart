import 'dart:convert' show json;

import 'package:flutter_test/flutter_test.dart';
import 'package:lain_chikita/models/game_save_data.dart';
import 'package:lain_chikita/models/save_file_data.dart';
import 'package:lain_chikita/services/crypto.dart';

void main() {
  // Llave de prueba (AES-256 necesita 32 bytes); la real es SECRET_KEY
  const key = 'abcdefghijklmnopqrstuvwxyz012345';

  const game = GameSaveData(
    userName: 'Lain',
    userUuid: 'uuid',
    level: 3000,
    progress: 5,
    userIv: 'iv',
    userSecretKey: 'secret',
    accessoryId: 'frog',
    inventoryVersion: 20,
    inventory: ['null', 'frog'],
    lockedAccessories: ['hornet'],
  );

  final saveFile = SaveFileData(
    game: game,
    localAchievements: const {
      'unlocked': ['beginner'],
    },
    savedAt: DateTime.utc(2026, 10, 15),
  );

  test('encrypt/decrypt conserva todo el contenido', () {
    final restored = SaveFileData.decrypt(saveFile.encrypt(key), key);
    expect(restored.game.toJson(), game.toJson());
    expect(restored.localAchievements, {
      'unlocked': ['beginner'],
    });
    expect(restored.savedAt, DateTime.utc(2026, 10, 15));
  });

  test('el contenido en disco no es legible', () {
    final encrypted = saveFile.encrypt(key);
    expect(encrypted, isNot(contains('Lain')));
    expect(encrypted, isNot(contains('3000')));
  });

  test('tolera saltos de línea al final del archivo', () {
    expect(() => SaveFileData.decrypt('${saveFile.encrypt(key)}\n', key), returnsNormally);
  });

  test('rechaza archivos editados, de otra llave o basura', () {
    final encrypted = saveFile.encrypt(key);
    final tampered = encrypted.replaceRange(40, 42, encrypted.substring(40, 42) == 'ff' ? '00' : 'ff');
    expect(() => SaveFileData.decrypt(tampered, key), throwsFormatException);
    expect(() => SaveFileData.decrypt(encrypted, 'zyxwvutsrqponmlkjihgfedcba543210'), throwsFormatException);
    expect(() => SaveFileData.decrypt('no soy un save', key), throwsFormatException);
  });

  test('rechaza JSON válido que no es un save de Lain Chikita o es de una versión más nueva', () {
    final otherApp = encryptData(json.encode({'format': 'other', 'formatVersion': 1}), key);
    expect(() => SaveFileData.decrypt(otherApp, key), throwsFormatException);

    final newer = encryptData(
      json.encode({'format': SaveFileData.formatId, 'formatVersion': SaveFileData.formatVersion + 1}),
      key,
    );
    expect(() => SaveFileData.decrypt(newer, key), throwsFormatException);
  });
}

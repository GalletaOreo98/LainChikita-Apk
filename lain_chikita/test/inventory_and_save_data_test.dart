import 'dart:convert' show json;

import 'package:flutter_test/flutter_test.dart';
import 'package:lain_chikita/logic/inventory_rules.dart';
import 'package:lain_chikita/models/game_save_data.dart';

void main() {
  group('mergeNewCatalogAccessories', () {
    test('agrega al final solo los accesorios que el usuario no conoce', () {
      final result = mergeNewCatalogAccessories(
        catalog: ['a', 'b', 'c', 'd'],
        owned: ['null', 'a'],
        locked: ['c'],
      );
      expect(result, ['c', 'b', 'd']);
    });

    test('no cambia nada si el usuario ya conoce todo el catálogo', () {
      final result = mergeNewCatalogAccessories(catalog: ['a', 'b'], owned: ['a'], locked: ['b']);
      expect(result, ['b']);
    });
  });

  group('lista de accesorios en JSON', () {
    test('mantiene el formato histórico [{"name": id}]', () {
      expect(encodeAccessoryList(['null', 'sunglasses']), '[{"name":"null"},{"name":"sunglasses"}]');
    });

    test('decode ignora entradas sin name', () {
      expect(decodeAccessoryList('[{"name":"frog"},{}]'), ['frog']);
    });
  });

  group('GameSaveData', () {
    // Así es como lo guardaba la versión anterior de la app en el slot1 de Play Games
    final legacyCloudJson = json.encode({
      'userName': 'Lain',
      'userUuid': 'uuid-123',
      'level': 42,
      'progress': 7,
      'userIv': 'iv',
      'userSecretKey': 'key',
      'accessoryName': 'frog',
      'inventoryVersion': 19,
      'inventory': '[{"name":"null"},{"name":"frog"}]',
      'unlockedInventory': '[{"name":"hornet"}]',
    });

    test('lee el formato que ya tienen guardado los usuarios', () {
      final data = GameSaveData.decode(legacyCloudJson);
      expect(data.userName, 'Lain');
      expect(data.level, 42);
      expect(data.progress, 7);
      expect(data.accessoryId, 'frog');
      expect(data.inventoryVersion, 19);
      expect(data.inventory, ['null', 'frog']);
      expect(data.lockedAccessories, ['hornet']);
    });

    test('encode/decode es reversible y conserva las llaves', () {
      final data = GameSaveData.decode(legacyCloudJson);
      expect(json.decode(data.encode()), json.decode(legacyCloudJson));
    });
  });
}

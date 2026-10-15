import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

import '../logic/inventory_rules.dart';

/// Llaves de las preferencias locales. **No renombrar**: son las que ya tienen guardadas los usuarios.
abstract final class PrefsKeys {
  static const userUuid = 'userUuid';
  static const userSecretKey = 'userSecretKey';
  static const userIv = 'userIv';
  static const inventoryVersion = 'inventoryVersion';
  static const inventory = 'inventory';

  /// Nombre histórico: en realidad guarda los accesorios BLOQUEADOS
  static const lockedAccessories = 'unlockedInventory';
  static const level = 'level';
  static const progress = 'progress';
  static const userName = 'userName';
  static const accessoryId = 'accessoryName';
  static const coins = 'coins';
  static const localAchievements = 'achievement_progress_engine_data';

  /// Marca que los datos del SharedPreferences legacy ya fueron migrados.
  /// Si se cambia o se borra, la migración se vuelve a ejecutar y sobrescribe datos nuevos.
  static const legacyMigrationCompleted = 'legacyPrefsMigrationCompleted';
}

/// Lo que se lee de las preferencias al iniciar. Los campos son null cuando no hay nada guardado.
class StoredGame {
  const StoredGame({
    required this.userUuid,
    required this.userSecretKey,
    required this.userIv,
    required this.inventoryVersion,
    required this.inventory,
    required this.lockedAccessories,
    required this.level,
    required this.progress,
    required this.userName,
    required this.accessoryId,
    required this.coins,
  });

  final String? userUuid;
  final String? userSecretKey;
  final String? userIv;
  final int? inventoryVersion;
  final List<String>? inventory;
  final List<String>? lockedAccessories;
  final int? level;
  final int? progress;
  final String? userName;
  final String? accessoryId;
  final int? coins;
}

/// Acceso a las preferencias locales del juego (SharedPreferencesAsync, DataStore en Android).
/// No tiene cache: cada llamada va directo a la plataforma.
class GameStorage {
  GameStorage._();
  static final instance = GameStorage._();

  static const SharedPreferencesOptions _options = SharedPreferencesOptions();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync(options: _options);

  /// Copia a SharedPreferencesAsync los datos guardados con el SharedPreferences legacy
  /// (versiones anteriores de la app). Solo hace algo la primera vez y debe llamarse
  /// antes de leer cualquier preferencia.
  Future<void> migrateLegacyIfNecessary() async {
    try {
      if (await _prefs.containsKey(PrefsKeys.legacyMigrationCompleted)) return;
      await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
        legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
        sharedPreferencesAsyncOptions: _options,
        migrationCompletedKey: PrefsKeys.legacyMigrationCompleted,
      );
      if (kDebugMode) debugPrint('Legacy SharedPreferences migrated to SharedPreferencesAsync');
    } catch (e) {
      // Si falla, la llave de migración no se guarda y se reintenta en el siguiente inicio
      if (kDebugMode) debugPrint('Error migrating legacy SharedPreferences: $e');
    }
  }

  Future<StoredGame> load() async {
    return StoredGame(
      userUuid: await _prefs.getString(PrefsKeys.userUuid),
      userSecretKey: await _prefs.getString(PrefsKeys.userSecretKey),
      userIv: await _prefs.getString(PrefsKeys.userIv),
      inventoryVersion: await _prefs.getInt(PrefsKeys.inventoryVersion),
      inventory: await _getAccessoryList(PrefsKeys.inventory),
      lockedAccessories: await _getAccessoryList(PrefsKeys.lockedAccessories),
      level: await _prefs.getInt(PrefsKeys.level),
      progress: await _prefs.getInt(PrefsKeys.progress),
      userName: await _prefs.getString(PrefsKeys.userName),
      accessoryId: await _prefs.getString(PrefsKeys.accessoryId),
      coins: await _prefs.getInt(PrefsKeys.coins),
    );
  }

  Future<void> saveCredentials({
    required String userUuid,
    required String userSecretKey,
    required String userIv,
  }) async {
    await _prefs.setString(PrefsKeys.userUuid, userUuid);
    await _prefs.setString(PrefsKeys.userSecretKey, userSecretKey);
    await _prefs.setString(PrefsKeys.userIv, userIv);
  }

  Future<void> saveProgress({
    required int level,
    required int progress,
    required String userName,
    required int coins,
  }) async {
    await _prefs.setInt(PrefsKeys.level, level);
    await _prefs.setInt(PrefsKeys.progress, progress);
    await _prefs.setString(PrefsKeys.userName, userName);
    await _prefs.setInt(PrefsKeys.coins, coins);
  }

  Future<void> saveCoins(int coins) => _prefs.setInt(PrefsKeys.coins, coins);

  Future<void> saveAccessory(String accessoryId) => _prefs.setString(PrefsKeys.accessoryId, accessoryId);

  Future<void> saveInventoryVersion(int version) => _prefs.setInt(PrefsKeys.inventoryVersion, version);

  Future<void> saveInventories({required List<String> inventory, required List<String> lockedAccessories}) async {
    await _prefs.setString(PrefsKeys.inventory, encodeAccessoryList(inventory));
    await _prefs.setString(PrefsKeys.lockedAccessories, encodeAccessoryList(lockedAccessories));
  }

  /// Progreso del motor de logros local (fifty_achievement_engine)
  Future<Map<String, dynamic>?> loadLocalAchievements() async {
    final encoded = await _prefs.getString(PrefsKeys.localAchievements);
    if (encoded == null || encoded.isEmpty) return null;
    final decoded = json.decode(encoded) as Map<String, dynamic>;
    return decoded.isEmpty ? null : decoded;
  }

  Future<void> saveLocalAchievements(Map<String, dynamic> progress) =>
      _prefs.setString(PrefsKeys.localAchievements, json.encode(progress));

  Future<List<String>?> _getAccessoryList(String key) async {
    final encoded = await _prefs.getString(key);
    if (encoded == null || encoded.isEmpty) return null;
    return decodeAccessoryList(encoded);
  }
}

import 'dart:convert' show json;

import '../logic/inventory_rules.dart';

/// Datos del juego que se guardan en la nube (Google Play Games, slot "slot1").
///
/// **El formato JSON ([toJson]/[fromJson]) debe mantenerse compatible** con lo que ya tienen
/// guardado los usuarios: mismas llaves y los inventarios como string JSON dentro del JSON.
class GameSaveData {
  const GameSaveData({
    required this.userName,
    required this.userUuid,
    required this.level,
    required this.progress,
    required this.userIv,
    required this.userSecretKey,
    required this.accessoryId,
    required this.inventoryVersion,
    required this.inventory,
    required this.lockedAccessories,
  });

  final String userName;
  final String userUuid;
  final int level;
  final int progress;
  final String userIv;
  final String userSecretKey;
  final String accessoryId;
  final int inventoryVersion;
  final List<String> inventory;
  final List<String> lockedAccessories;

  factory GameSaveData.fromJson(Map<String, dynamic> data) {
    return GameSaveData(
      userName: data['userName'] as String? ?? '',
      userUuid: data['userUuid'] as String? ?? '',
      level: data['level'] as int? ?? 0,
      progress: data['progress'] as int? ?? 0,
      userIv: data['userIv'] as String? ?? '',
      userSecretKey: data['userSecretKey'] as String? ?? '',
      accessoryId: data['accessoryName'] as String? ?? '',
      inventoryVersion: data['inventoryVersion'] as int? ?? 0,
      inventory: decodeAccessoryList(data['inventory'] as String? ?? '[]'),
      // "unlockedInventory" es el nombre histórico, pero en realidad son los accesorios BLOQUEADOS
      lockedAccessories: decodeAccessoryList(data['unlockedInventory'] as String? ?? '[]'),
    );
  }

  factory GameSaveData.decode(String encoded) =>
      GameSaveData.fromJson(Map<String, dynamic>.from(json.decode(encoded) as Map));

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'userUuid': userUuid,
        'level': level,
        'progress': progress,
        'userIv': userIv,
        'userSecretKey': userSecretKey,
        'accessoryName': accessoryId,
        'inventoryVersion': inventoryVersion,
        'inventory': encodeAccessoryList(inventory),
        'unlockedInventory': encodeAccessoryList(lockedAccessories),
      };

  String encode() => json.encode(toJson());
}

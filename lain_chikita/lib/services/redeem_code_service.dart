import 'dart:convert' show json;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../data/redeemable_codes.dart';
import '../models/redeem_result.dart';
import '../private_keys.dart';
import '../state/game_state.dart';
import 'crypto.dart';
import 'play_games_service.dart';

/// Canje de códigos. Requiere sesión en Google Play Games, porque la lista de códigos
/// ya canjeados se guarda en la nube (slot "redeemed_codes").
class RedeemCodeService {
  RedeemCodeService(this._game, {PlayGamesService? playGames}) : _playGames = playGames ?? PlayGamesService.instance;

  final GameState _game;
  final PlayGamesService _playGames;

  /// Ids de códigos ya canjeados (se sincroniza con la nube en cada canje)
  List<String> _redeemedCodeIds = [];

  Future<RedeemResult> redeem(String encryptedCode) async {
    try {
      final codeId = _decodeCodeId(encryptedCode);
      if (!await _playGames.isSignedIn()) return const InvalidCode();

      await _loadRedeemedCodeIds();
      if (_redeemedCodeIds.contains(codeId)) return const CodeAlreadyRedeemed();

      final code = redeemableCodes.where((c) => c.id == codeId).firstOrNull;
      if (code == null) return const InvalidCode();

      final result = await _applyReward(code);
      await _markAsRedeemed(code.id);
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Error redeeming code: $e');
      return const InvalidCode();
    }
  }

  /// El código es un JSON `{"id": "..."}` encriptado con SECRET_KEY
  String _decodeCodeId(String encryptedCode) {
    final decoded = json.decode(decryptData(encryptedCode, SECRET_KEY)) as Map<String, dynamic>;
    return decoded['id'] as String;
  }

  Future<RedeemResult> _applyReward(RedeemableCode code) async {
    switch (code.type) {
      case RedeemRewardType.accessory:
        final accessoryId = code.accessoryId!;
        final unlocked = await _game.unlockAccessory(accessoryId);
        return unlocked ? AccessoryUnlocked(accessoryId) : AccessoryAlreadyOwned(accessoryId);
      case RedeemRewardType.randomAccessory:
        final accessoryId = await _game.unlockRandomAccessory();
        return accessoryId != null ? AccessoryUnlocked(accessoryId) : const NoAccessoriesLeft();
    }
  }

  Future<void> _loadRedeemedCodeIds() async {
    try {
      final cloudData = await _playGames.loadFromSlot(SaveSlots.redeemedCodes);
      if (cloudData != null) _redeemedCodeIds = List<String>.from(json.decode(cloudData) as List);
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading redeemed codes: $e');
    }
  }

  Future<void> _markAsRedeemed(String codeId) async {
    _redeemedCodeIds.add(codeId);
    // De paso se limpian los códigos que ya no existen en redeemableCodes
    _redeemedCodeIds.removeWhere((id) => !redeemableCodes.any((code) => code.id == id));
    try {
      await _playGames.saveToSlot(SaveSlots.redeemedCodes, json.encode(_redeemedCodeIds));
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving redeemed codes: $e');
    }
  }
}

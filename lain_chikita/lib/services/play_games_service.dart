import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:games_services/games_services.dart';

import '../data/achievements_catalog.dart' show cookiesLeaderboardId;

/// Slots de guardado en la nube
abstract final class SaveSlots {
  static const gameData = 'slot1';
  static const cookiesScore = 'cookies_score';
  static const redeemedCodes = 'redeemed_codes';
}

/// Envoltorio de Google Play Games Services (solo existe en Android).
///
/// En las demás plataformas los métodos no hacen nada (o devuelven false/null),
/// así el resto de la app no tiene que preguntar por la plataforma a cada rato.
class PlayGamesService {
  PlayGamesService._();
  static final instance = PlayGamesService._();

  /// Pasos que se suman a cada logro incremental cuando se llama a [incrementStepAchievements]
  static const int _stepsPerIncrement = 50;

  bool get isAvailable => Platform.isAndroid;

  /// Logros de Play Games del usuario (cache para no desbloquear dos veces y para los incrementales)
  List<AchievementItemData> _achievements = [];

  Future<bool> isSignedIn() async {
    if (!isAvailable) return false;
    try {
      return await GameAuth.isSignedIn;
    } catch (_) {
      return false;
    }
  }

  /// Lanza excepción si falla, para que la UI pueda mostrar el error
  Future<void> signIn() async {
    if (!isAvailable) return;
    await GameAuth.signIn();
  }

  // ---------------------------------------------------------------------------
  // Guardado en la nube
  // ---------------------------------------------------------------------------

  /// Lanza excepción si falla
  Future<void> saveToSlot(String slot, String data) async {
    if (!isAvailable) return;
    await GameAuth.signIn();
    await SaveGame.saveGame(data: data, name: slot);
  }

  /// Lanza excepción si falla. Devuelve null si el slot está vacío
  Future<String?> loadFromSlot(String slot) async {
    if (!isAvailable) return null;
    await GameAuth.signIn();
    return SaveGame.loadGame(name: slot);
  }

  // ---------------------------------------------------------------------------
  // Logros
  // ---------------------------------------------------------------------------

  /// Recarga la cache de logros del usuario. Devuelve false si no se pudieron cargar
  Future<bool> refreshAchievements() async {
    _achievements = [];
    if (!isAvailable) return false;
    try {
      await GameAuth.signIn();
      final result = await Achievements.loadAchievements(forceRefresh: true);
      _achievements = result ?? [];
      if (kDebugMode) debugPrint('Play Games achievements loaded: ${_achievements.length}');
      return _achievements.isNotEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading Play Games achievements: $e');
      return false;
    }
  }

  /// Desbloquea un logro (de tipo porcentaje) si no estaba desbloqueado ya
  Future<void> unlockAchievement(String achievementId) async {
    if (!isAvailable || _achievements.isEmpty) return;
    try {
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      if (achievement.unlocked) return;

      await GameAuth.signIn();
      await Achievements.unlock(
        achievement: Achievement(androidID: achievementId, percentComplete: 100, showsCompletionBanner: true),
      );
      await refreshAchievements();
      if (kDebugMode) debugPrint('Play Games achievement unlocked: $achievementId');
    } catch (e) {
      if (kDebugMode) debugPrint('Error unlocking Play Games achievement $achievementId: $e');
    }
  }

  /// Suma pasos a todos los logros incrementales (totalSteps > 0) que no estén desbloqueados
  Future<void> incrementStepAchievements() async {
    if (!isAvailable || _achievements.isEmpty) return;

    final pending = _achievements.where((a) => a.totalSteps > 0 && !a.unlocked).toList();
    for (final achievement in pending) {
      try {
        await GameAuth.signIn();
        await Achievements.increment(
          achievement: Achievement(
            androidID: achievement.id,
            steps: _stepsPerIncrement,
            percentComplete: ((achievement.completedSteps + _stepsPerIncrement) / achievement.totalSteps) * 100,
          ),
        );
        await refreshAchievements();
        if (kDebugMode) {
          debugPrint('Achievement progress updated: ${achievement.name} '
              '- Steps: ${achievement.completedSteps}/${achievement.totalSteps}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error updating achievement ${achievement.name}: $e');
      }
    }
  }

  /// Abre la UI nativa de logros. Lanza excepción si falla
  Future<void> showAchievements() => Achievements.showAchievements();

  // ---------------------------------------------------------------------------
  // Leaderboard de "cookies"
  // ---------------------------------------------------------------------------

  /// Abre la UI nativa del leaderboard de cookies. Lanza excepción si falla
  Future<void> showCookiesLeaderboard() => Leaderboards.showLeaderboards(androidLeaderboardID: cookiesLeaderboardId);

  /// Suma 1 al score de cookies guardado en la nube y lo manda al leaderboard
  Future<void> incrementCookiesScore() async {
    if (!isAvailable) return;
    try {
      await GameAuth.signIn();

      var currentScore = 0;
      try {
        final cloudData = await SaveGame.loadGame(name: SaveSlots.cookiesScore);
        if (cloudData != null && cloudData.isNotEmpty) currentScore = int.tryParse(cloudData) ?? 0;
      } catch (e) {
        if (kDebugMode) debugPrint('Error loading saved cookies score, starting from 0: $e');
      }

      final newScore = currentScore + 1;
      await SaveGame.saveGame(data: newScore.toString(), name: SaveSlots.cookiesScore);
      await Leaderboards.submitScore(score: Score(androidLeaderboardID: cookiesLeaderboardId, value: newScore));
      if (kDebugMode) debugPrint('Cookies score updated: $currentScore -> $newScore');
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating cookies score: $e');
    }
  }
}

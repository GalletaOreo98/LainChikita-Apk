import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/widgets.dart';

import '../core/navigation.dart';
import '../data/achievements_catalog.dart';
import 'game_storage.dart';
import 'play_games_service.dart';

/// Punto único para los logros. Decide por plataforma:
/// - Android: Google Play Games ([PlayGamesService])
/// - Resto: motor local (fifty_achievement_engine), con progreso guardado en las preferencias
class AchievementsService {
  AchievementsService._();
  static final instance = AchievementsService._();

  final PlayGamesService _playGames = PlayGamesService.instance;
  final GameStorage _storage = GameStorage.instance;

  /// Cada cuántos niveles se suman pasos a los logros incrementales de Play Games
  static const int _playGamesStepEveryLevels = 50;

  late final fifty.AchievementController<void> _localEngine = fifty.AchievementController<void>(
    achievements: localAchievements,
    onUnlock: _onLocalAchievementUnlocked,
  );

  bool get _usePlayGames => _playGames.isAvailable;

  /// Carga el progreso guardado del motor local
  Future<void> restoreLocalProgress() async {
    final progress = await _storage.loadLocalAchievements();
    if (progress != null) _localEngine.importProgress(progress);
  }

  Future<void> saveLocalProgress() => _storage.saveLocalAchievements(_localEngine.exportProgress());

  /// Recarga los logros de Play Games (no hace nada fuera de Android)
  Future<void> refreshPlayGamesAchievements() => _playGames.refreshAchievements();

  Future<void> unlock(GameAchievement achievement) async {
    if (_usePlayGames) {
      await _playGames.unlockAchievement(achievement.playGamesId);
    } else {
      _localEngine.forceUnlock(achievement.localId);
    }
  }

  /// Avisa que el usuario subió a [newLevel]
  Future<void> onLevelUp(int newLevel) async {
    if (_usePlayGames) {
      if (newLevel % _playGamesStepEveryLevels == 0) await _playGames.incrementStepAchievements();
    } else {
      _localEngine.incrementStat(levelUpStat, 1);
      await saveLocalProgress();
    }
  }

  void _onLocalAchievementUnlocked(fifty.Achievement<void> achievement) {
    if (kDebugMode) debugPrint('¡Desbloqueado!: ${achievement.name}');
    saveLocalProgress();
    _showLocalAchievementPopup(achievement);
  }

  void _showLocalAchievementPopup(fifty.Achievement<void> achievement) {
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => fifty.AchievementPopup(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

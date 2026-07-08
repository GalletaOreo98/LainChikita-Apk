import 'dart:convert' show jsonEncode;
import 'dart:io' show Platform;
import 'package:games_services/games_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';

import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/game_achievements.dart';

// Variable global para almacenar el contexto de la app (se asignará en main)
// Para el popup de logros de Fifty Achievement Engine
BuildContext? appContext;

saveEngineAchievementsProgressToSharedPreferences() async {
  final progressJson = achievementController.exportProgress();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('achievement_progress_engine_data', jsonEncode(progressJson));
}

// Controlador de logros de Fifty Achievement Engine (Local/OFFLINE)
final achievementController = fifty.AchievementController<void>(
  achievements: achievementList,
  onUnlock: (achievement) {
    if (kDebugMode) debugPrint('¡Desbloqueado!: ${achievement.name}');
    // Guardar progreso de logros en SharedPreferences
    saveEngineAchievementsProgressToSharedPreferences();
    final overlay = Overlay.of(appContext!);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => fifty.AchievementPopup(
        achievement: achievement,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  },
);

/// Global variable to store personal user achievements
List<AchievementItemData> globalAchievements = [];

/// Loads achievements from Game Services and stores them in the global variable
Future<bool> loadAchievementsToGlobalVars() async {
  // Si la plataforma no es Android, no intentamos cargar los logros
  if (!Platform.isAndroid) {
    globalAchievements = [];
    return false;
  }
  try {
    await GameAuth.signIn();
    final result = await Achievements.loadAchievements(forceRefresh: true);
    if (result != null) {
      globalAchievements = result;
      if (kDebugMode) debugPrint('Achievements loaded successfully: ${globalAchievements.length} achievements');
      return true;
    } else {
      if (kDebugMode) debugPrint('No achievements found');
      globalAchievements = [];
      return false;
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Error loading achievements: $e');
    globalAchievements = [];
    return false;
  }
}

/// Step achievement increment progress updater
Future<void> incrementAchievementsStepType() async {
  // Si la plataforma no es Android, no intentamos actualizar los logros
  if (!Platform.isAndroid) return;

  if (globalAchievements.isEmpty) return;

  for (final achievement in globalAchievements) {
    // Solo procesar logros con pasos (totalSteps > 0) y que no estén desbloqueados
    // total steps > 0 indica que es un logro de tipo "pasos" (step achievement type)
    if (achievement.totalSteps > 0 && !achievement.unlocked) {
      try {
        await GameAuth.signIn();
        await Achievements.increment(
            achievement: Achievement(
          androidID: achievement.id,
          steps: 50,
          percentComplete: ((achievement.completedSteps + 50) / achievement.totalSteps) * 100,
        ));
        await loadAchievementsToGlobalVars(); // Actualizar la lista de logros después de la actualización
        if (kDebugMode) {
          debugPrint(
              'Achievement progress updated: ${achievement.name} - Steps: ${achievement.completedSteps}/${achievement.totalSteps}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error updating achievement ${achievement.name}: $e');
      }
    }
  }
}

/// Unlocks a specific achievement by its ID (percentage type achievement)
Future<void> unlockAchievementById(String achievementId) async {
  // Si la plataforma no es Android, no intentamos desbloquear logros
  if (!Platform.isAndroid) return;

  if (globalAchievements.isEmpty) return;
  try {
    //Checar si el usuario ya lo desbloqueó
    final achievement = globalAchievements.firstWhere((ach) => ach.id == achievementId);

    if (achievement.unlocked) {
      return;
    }
    await GameAuth.signIn();
    await Achievements.unlock(
      achievement: Achievement(androidID: achievementId, percentComplete: 100, showsCompletionBanner: true),
    );
    await loadAchievementsToGlobalVars(); // Actualizar la lista de logros después de desbloquear
    if (kDebugMode) debugPrint('Achievement unlocked: $achievementId');
  } catch (e) {
    if (kDebugMode) debugPrint('Error unlocking achievement $achievementId: $e');
  }
}

/// Save cookies score to saved game slot - increments current score by 1
Future<void> saveCookiesScore() async {
  // Si la plataforma no es Android, no intentamos guardar el score
  if (!Platform.isAndroid) return;
  try {
    await GameAuth.signIn();

    // Cargar el score actual de la nube
    dynamic cloudData;
    try {
      cloudData = await SaveGame.loadGame(name: "cookies_score");
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading saved score: $e');
      cloudData = null;
    }

    int currentScore = 0;

    // Si existe datos en la nube, parsear el score
    if (cloudData != null && cloudData.isNotEmpty) {
      try {
        currentScore = int.parse(cloudData);
      } catch (e) {
        if (kDebugMode) debugPrint('Error parsing saved score, starting from 0: $e');
        currentScore = 0;
      }
    }

    int newScore = currentScore + 1;

    // Guardar el nuevo score en la nube
    await SaveGame.saveGame(data: newScore.toString(), name: "cookies_score");
    if (kDebugMode) debugPrint('Cookies score updated: $currentScore -> $newScore');

    // Submit score to leaderboard
    await Leaderboards.submitScore(score: Score(androidLeaderboardID: 'CgkI8NLzkooQEAIQDA', value: newScore));
  } catch (e) {
    if (kDebugMode) debugPrint('Error updating cookies score: $e');
  }
}

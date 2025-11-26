import 'package:games_services/games_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;


/// Global variable to store personal user achievements
List<AchievementItemData> globalAchievements = [];

/// Loads achievements from Game Services and stores them in the global variable
Future<bool> loadAchievementsToGlobalVars() async {
  try {
    await GameAuth.signIn();
    final result = await Achievements.loadAchievements();
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
  if(globalAchievements.isEmpty) return;
  
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
          )
        );
        await loadAchievementsToGlobalVars(); // Actualizar la lista de logros después de la actualización
        if (kDebugMode) debugPrint('Achievement progress updated: ${achievement.name} - Steps: ${achievement.completedSteps}/${achievement.totalSteps}');
      } catch (e) {
        if (kDebugMode) debugPrint('Error updating achievement ${achievement.name}: $e');
      }
    }
  }
}

/// Unlocks a specific achievement by its ID (percentage type achievement)
Future<void> unlockAchievementById(String achievementId) async {
  try {
    if(globalAchievements.isEmpty) return;
    //Checar si el usuario ya lo desbloqueó
    final achievement = globalAchievements.firstWhere((ach) => ach.id == achievementId);
    
    if(achievement.unlocked) {
      return;
    }
    await GameAuth.signIn();
    await Achievements.unlock(
      achievement: Achievement(
        androidID: achievementId,
        percentComplete: 100,
        showsCompletionBanner: true
      ),
    );
    await loadAchievementsToGlobalVars(); // Actualizar la lista de logros después de desbloquear
    if (kDebugMode) debugPrint('Achievement unlocked: $achievementId');
  } catch (e) {
    if (kDebugMode) debugPrint('Error unlocking achievement $achievementId: $e');
  }
}

/// Save cookies score to saved game slot - increments current score by 1
Future<void> saveCookiesScore() async {
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
    await Leaderboards.submitScore(
      score: Score(
        androidLeaderboardID: 'CgkI8NLzkooQEAIQDA',
        value: newScore
      )
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Error updating cookies score: $e');
  }
}
import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/achievements_service.dart';
import '../services/translations.dart';
import '../widgets/achievement_icon.dart';

/// Lista de logros del motor local (plataformas sin Google Play Games)
class LocalAchievementsScreen extends StatelessWidget {
  const LocalAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = AchievementsService.instance.localEngine;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        title: Text(tr('achievements'), style: const TextStyle(fontSize: 34.0)),
      ),
      body: ListenableBuilder(
        listenable: engine,
        builder: (context, _) {
          final achievements = engine.achievements;
          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: achievements.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return _Summary(engine);
              final achievement = achievements[index - 1];
              return _AchievementTile(
                achievement: achievement,
                isUnlocked: engine.getState(achievement.id).isComplete,
                // Solo los logros de nivel muestran avance (los de evento también tienen target = 1)
                current: achievement.condition is fifty.ThresholdCondition
                    ? achievement.condition.getCurrent(engine.context)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

/// Cuántos logros lleva el usuario
class _Summary extends StatelessWidget {
  const _Summary(this.engine);

  final fifty.AchievementController<void> engine;

  @override
  Widget build(BuildContext context) {
    final unlocked = engine.unlockedAchievements.length;
    final total = engine.achievements.length;
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.inventoryItem,
      child: Text(
        '${tr('unlocked')}: $unlocked / $total',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30, color: AppColors.primaryText),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.isUnlocked, required this.current});

  final fifty.Achievement<void> achievement;
  final bool isUnlocked;

  /// Valor actual de la stat del logro (solo los de nivel tienen); null si es de evento
  final int? current;

  @override
  Widget build(BuildContext context) {
    final isSecret = achievement.hidden && !isUnlocked;
    final color = rarityColor(achievement.rarity);
    final target = achievement.condition.target;
    final showProgress = !isUnlocked && current != null && target != null && target > 0;
    final progress = showProgress ? (current! / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.inventoryItem : AppColors.inventoryItemSelected,
        border: Border.all(color: isUnlocked ? color : color.withValues(alpha: 0.25), width: 2),
      ),
      child: Row(
        children: [
          AchievementIcon(achievement: achievement, isUnlocked: isUnlocked),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isSecret ? tr('hidden-achievement') : achievement.name,
                        style: TextStyle(
                          fontSize: 28,
                          height: 1,
                          color: isUnlocked ? AppColors.primaryText : AppColors.disabledText,
                        ),
                      ),
                    ),
                    _RarityBadge(achievement.rarity, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                // Los ocultos esconden nombre e ícono, pero la descripción queda como pista
                Text(
                  achievement.description ?? '',
                  style: const TextStyle(fontSize: 20, color: AppColors.informativeText),
                ),
                if (showProgress) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: AppColors.background,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        // Hacia abajo, para que no diga 100% sin estar desbloqueado
                        '${(progress * 100).floor()}%',
                        style: const TextStyle(fontSize: 18, color: AppColors.informativeText),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge(this.rarity, {required this.color});

  final fifty.AchievementRarity rarity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(rarityLabel(rarity), style: TextStyle(fontSize: 18, color: color)),
    );
  }
}

import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/translations.dart';
import 'achievement_icon.dart';

/// Contenido del popup de "logro desbloqueado" (la animación la pone fifty.AchievementPopup)
class AchievementPopupContent extends StatelessWidget {
  const AchievementPopupContent({super.key, required this.achievement});

  final fifty.Achievement<void> achievement;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(achievement.rarity);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AchievementIcon(achievement: achievement, isUnlocked: true, size: 64),
          const SizedBox(width: 16),
          Flexible(
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'monogram', color: AppColors.primaryText),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('achievement-unlocked').toUpperCase(), style: TextStyle(fontSize: 20, color: color)),
                  Text(achievement.name, style: const TextStyle(fontSize: 30, height: 1)),
                  if (achievement.description != null)
                    Text(
                      achievement.description!,
                      style: const TextStyle(fontSize: 20, color: AppColors.informativeText),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

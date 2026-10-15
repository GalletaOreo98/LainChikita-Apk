import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/achievements_service.dart';
import '../services/translations.dart';

/// Lista de logros del motor local (plataformas sin Google Play Games)
class LocalAchievementsScreen extends StatelessWidget {
  const LocalAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = AchievementsService.instance.localEngine;
    return Theme(
      // Las tarjetas del motor toman los colores del tema; en oscuro combinan con el fondo de la app
      data: ThemeData(brightness: Brightness.dark, fontFamily: 'monogram'),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryText,
          title: Text(tr('achievements'), style: const TextStyle(fontSize: 34.0)),
        ),
        body: ListenableBuilder(
          listenable: engine,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                fifty.AchievementSummary(controller: engine),
                const SizedBox(height: 12),
                Expanded(
                  child: fifty.AchievementList(
                    controller: engine,
                    itemBuilder: (achievement, progress, state, _) => fifty.AchievementCard(
                      achievement: achievement,
                      progress: progress,
                      // El motor solo esconde los logros ocultos si tienen prerrequisitos (estado "locked").
                      // Los nuestros no tienen, así que se fuerza para que no se vean hasta desbloquearlos.
                      state: achievement.hidden && !state.isComplete ? fifty.AchievementState.locked : state,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

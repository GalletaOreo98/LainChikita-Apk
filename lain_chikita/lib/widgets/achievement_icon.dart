import 'package:fifty_achievement_engine/fifty_achievement_engine.dart' as fifty;
import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../services/translations.dart';

Color rarityColor(fifty.AchievementRarity rarity) => switch (rarity) {
      fifty.AchievementRarity.common => AppColors.rarityCommon,
      fifty.AchievementRarity.uncommon => AppColors.rarityUncommon,
      fifty.AchievementRarity.rare => AppColors.rarityRare,
      fifty.AchievementRarity.epic => AppColors.rarityEpic,
      fifty.AchievementRarity.legendary => AppColors.rarityLegendary,
    };

String rarityLabel(fifty.AchievementRarity rarity) => tr('rarity-${rarity.name}');

/// Ícono pixel art de un logro (`assets/images/achievements/<id>.png`, 32x32) con borde del color de su rareza.
///
/// - Bloqueado: en escala de grises y más oscuro
/// - Oculto y bloqueado: un "?" en vez del ícono (la pista es solo la descripción)
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    this.size = 64,
  });

  final fifty.Achievement<void> achievement;
  final bool isUnlocked;
  final double size;

  /// Matriz de color que pasa a escala de grises y oscurece un poco
  static const _lockedFilter = ColorFilter.matrix([
    0.16, 0.5, 0.06, 0, 0, //
    0.16, 0.5, 0.06, 0, 0, //
    0.16, 0.5, 0.06, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(achievement.rarity);
    final isSecret = achievement.hidden && !isUnlocked;

    Widget image = Image.asset(
      AppImages.achievement(achievement.id),
      width: size,
      height: size,
      // Sin suavizado para que el pixel art se vea nítido al escalarlo
      filterQuality: FilterQuality.none,
      fit: BoxFit.cover,
    );
    if (!isUnlocked) image = ColorFiltered(colorFilter: _lockedFilter, child: image);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isUnlocked ? color : color.withValues(alpha: 0.4), width: 3),
        boxShadow: isUnlocked ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)] : null,
      ),
      child: isSecret
          ? Container(
              width: size,
              height: size,
              color: AppColors.inventoryItemSelected,
              alignment: Alignment.center,
              child: Text('?', style: TextStyle(fontSize: size * 0.7, color: AppColors.disabledText, height: 1)),
            )
          : image,
    );
  }
}

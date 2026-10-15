import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/accessories_catalog.dart';
import '../data/achievements_catalog.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/translations.dart';
import '../state/game_state.dart';

/// Lista de accesorios del usuario para elegir cuál lleva puesto Lain
class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key, required this.game, required this.onAccessorySelected});

  final GameState game;

  /// Se llama después de elegir un accesorio (para volver a la pantalla principal)
  final VoidCallback onAccessorySelected;

  void _selectAccessory(String accessoryId) {
    AchievementsService.instance.unlock(GameAchievement.prettyGirl);
    game.selectAccessory(accessoryId);
    onAccessorySelected();
    AudioService.instance.playSelectAccessory(isNyanCat: accessoryId == nyanCatAccessoryId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12.0),
      child: ListenableBuilder(
        listenable: game,
        builder: (context, _) {
          final inventory = game.inventory;
          return ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final accessoryId = inventory[index];
              return _InventoryItem(
                name: Translations.instance.accessoryName(accessoryId),
                isSelected: accessoryId == game.accessoryId,
                onTap: () => _selectAccessory(accessoryId),
              );
            },
          );
        },
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  const _InventoryItem({required this.name, required this.isSelected, required this.onTap});

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(5.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.inventoryItemSelected : AppColors.inventoryItem,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                name,
                style: const TextStyle(fontSize: 34.0, color: AppColors.primaryText, letterSpacing: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

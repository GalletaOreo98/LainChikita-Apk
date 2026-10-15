import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_colors.dart';
import '../data/accessories_catalog.dart';
import '../data/achievements_catalog.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';
import '../services/translations.dart';
import '../state/game_state.dart';

/// Lista de accesorios del usuario para elegir cuál lleva puesto Lain.
/// Manteniendo presionado un accesorio se puede arrastrar para cambiar el orden de la lista.
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

          _InventoryItem buildItem(int index, {bool isLifted = false}) {
            final accessoryId = inventory[index];
            return _InventoryItem(
              name: Translations.instance.accessoryName(accessoryId),
              isSelected: accessoryId == game.accessoryId,
              isLifted: isLifted,
              onTap: () => _selectAccessory(accessoryId),
            );
          }

          return ReorderableListView.builder(
            // Sin las "agarraderas" que pone por defecto en escritorio: en todas las plataformas
            // se arrastra manteniendo presionado (ReorderableDelayedDragStartListener)
            buildDefaultDragHandles: false,
            header: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                tr('inventory-reorder-hint'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20.0, color: AppColors.informativeText),
              ),
            ),
            itemCount: inventory.length,
            onReorderStart: (_) => HapticFeedback.selectionClick(),
            onReorder: game.reorderInventory,
            itemBuilder: (context, index) => ReorderableDelayedDragStartListener(
              key: ValueKey(inventory[index]),
              index: index,
              child: buildItem(index),
            ),
            // El item que se arrastra se ve "levantado": un poco más grande y con borde
            proxyDecorator: (_, index, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Transform.scale(
                scale: 1 + 0.05 * Curves.easeOut.transform(animation.value),
                child: child,
              ),
              child: Material(type: MaterialType.transparency, child: buildItem(index, isLifted: true)),
            ),
          );
        },
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  const _InventoryItem({required this.name, required this.isSelected, required this.onTap, this.isLifted = false});

  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  /// Se está arrastrando
  final bool isLifted;

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
            border: Border.all(color: isLifted ? AppColors.focusItem : Colors.transparent, width: 2),
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

import 'dart:io' show Platform;

import 'package:flutter/material.dart';

//My imports
import '../classes/app_colors.dart';
import '../functions/achievements_manager.dart';
import '../global_vars.dart' as global_vars;

class InventoryScreen extends StatefulWidget {
  final Function callback;
  final PageController pageController;
  const InventoryScreen({super.key, required this.callback, required this.pageController});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<InventoryScreen> {
  void changeAccessory(String newAccessoryName) {
    // Llamada a la función de callback
    if (!Platform.isAndroid) {
      achievementController.forceUnlock('pretty_girl');  // Unlock local achievement
    }
    unlockAchievementById("CgkI8NLzkooQEAIQCQ"); // "Pretty girl" achievement
    widget.callback(newAccessoryName);
    // Navegar automáticamente a la pantalla principal (índice 0)
    widget.pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  Future<void> playSelectAccessorySound() async {
    await global_vars.appAudioPlayer.playSound3("audio/select_accessory_sound.mp3");
    if (global_vars.accessoryName == "nyan_cat") {
      await global_vars.appAudioPlayer.playSound3("audio/nyan_cat_music.mp3");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: global_vars.inventory.length,
          itemBuilder: (BuildContext context, int index) {
            bool isCurrentAccessory = global_vars.inventory[index]['name'] == global_vars.accessoryName;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  changeAccessory(global_vars.inventory[index]['name']);
                  playSelectAccessorySound();
                },
                borderRadius: BorderRadius.circular(5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentAccessory 
                      ? AppColors.inventoryItemSelected
                      : AppColors.inventoryItem,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text(
                          global_vars.languageDataManager.getAccessoryName(global_vars.inventory[index]['name']),
                          style: const TextStyle(
                            fontSize: 34.0,
                            color: AppColors.primaryText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

//My imports
import '../classes/app_colors.dart';
import '../functions/achievements_manager.dart';
import '../global_vars.dart';

class InventoryScreen extends StatefulWidget {
  final Function callback;
  const InventoryScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<InventoryScreen> {
  void changeAccessory(String newAccessoryName) {
    // Llamada a la función de callback
    unlockAchievementById("CgkI8NLzkooQEAIQCQ");
    widget.callback(newAccessoryName);
  }

  Future<void> playSelectAccessorySound() async {
    await appAudioPlayer.playSound3("audio/select_accessory_sound.mp3");
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: inventory.length,
          itemBuilder: (BuildContext context, int index) {
            bool isCurrentAccessory = inventory[index]['name'] == accessoryName;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  changeAccessory(inventory[index]['name']);
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
                          languageDataManager.getAccessoryName(inventory[index]['name']),
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

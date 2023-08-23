import 'package:flutter/material.dart';
// ignore: library_prefixes
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
    widget.callback(newAccessoryName);
  }

  Future<void> playSelectAccessorySound() async {
    await appAudioPlayer.playSound("audio/select_accessory_sound.mp3"); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appColors.background,
      child: ListView.builder(
        itemCount: inventory.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
              onTap: () {
                changeAccessory(inventory[index]['name']);
                playSelectAccessorySound();
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: appColors.inventoryListBorders,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  textColor: appColors.primaryText,
                  title:
                      Text(languageDataManager.getAccessoryName(inventory[index]['name'])),
                  subtitle: Text('by: ${inventory[index]['by']}',
                      style: TextStyle(
                          color: appColors.secondaryText,
                          fontStyle: FontStyle.italic)),
                ),
              ));
        },
      ),
    );
  }
}

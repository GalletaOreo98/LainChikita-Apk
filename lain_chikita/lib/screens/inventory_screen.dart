import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// ignore: library_prefixes
import '../app_colors.dart' as MY_APP_COLORS;
import '../global_vars.dart';

class InventoryScreen extends StatefulWidget {
  final Function callback;
  const InventoryScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<InventoryScreen> {

  final _player = AudioPlayer(playerId: 'selectAccessory');

  void changeAccessory(String newAccessoryName) {
    // Llamada a la función de callback
    widget.callback(newAccessoryName);
  }

  Future<void> playSelectAccessorySound() async {
    await _player.play(AssetSource("audio/select_accessory_sound.mp3"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MY_APP_COLORS.darkBackground,
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
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  textColor: Colors.white,
                  title: Text(inventory[index]['name']),
                  subtitle: Text('by: ${inventory[index]['by']}',
                      style: const TextStyle(
                          color: MY_APP_COLORS.secondaryLightText,
                          fontStyle: FontStyle.italic)),
                ),
              ));
        },
      ),
    );
  }
}

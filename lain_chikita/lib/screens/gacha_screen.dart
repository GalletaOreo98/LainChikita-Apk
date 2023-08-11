import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

// ignore: library_prefixes
import '../app_colors.dart' as MY_APP_COLORS;
import '../global_vars.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<GachaScreen> {

  final _player = AudioPlayer(playerId: 'selectAccessory');

  Future<void> playSelectAccessorySound() async {
    await _player.play(AssetSource("audio/select_accessory_sound.mp3"));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //alignment: Alignment.center,
      color: MY_APP_COLORS.darkBackground,
      child: 
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: TextField(decoration: InputDecoration(labelText: userUuid),),
            )
          ],
        ),
    );
  }
}

import 'package:flutter/material.dart';

//My imports
import '../functions/directory_path_provider.dart' show applyMod;
import '../global_vars.dart';

class ConfigurationScreen extends StatefulWidget {
  final Function callback;
  const ConfigurationScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<ConfigurationScreen> {
  void changeAccessory() async {
    // Llamada a la función de callback
    isActiveMod = !isActiveMod;
    await applyMod();
    widget.callback();
  }

  Future<void> playSelectAccessorySound() async {
    await appAudioPlayer.playSound("audio/select_accessory_sound.mp3"); //Recordar cambiar effect sound si quieres
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: appColors.background,
      child: Table(
        children: [
          const TableRow(children: [
            TableCell(
              child: SizedBox(height: 16),
            )
          ]),
          TableRow(children: [
            TableCell(
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(380, 80),
                        backgroundColor: appColors.secondaryBtn,
                        padding: const EdgeInsets.all(20.0)),
                    onPressed: changeAccessory,
                    onLongPress: () => setState(() {
                          /////////////
                        }),
                    child: Text(languageDataManager.getLabel('MOD'),
                        style: const TextStyle(
                          fontSize: 34.0,
                        ),
                        textAlign: TextAlign.center)))
          ])
        ],
      ),
    );
  }
}

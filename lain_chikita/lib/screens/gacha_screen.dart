import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
  String _copiedText = '';
  String uuidToUse = '';

  Future<void> playSelectAccessorySound() async {
    await _player.play(AssetSource("audio/select_accessory_sound.mp3"));
  }

  void _copyText() {
    Clipboard.setData(ClipboardData(text: userUuid));
    setState(() {
      _copiedText = '¡Copiado!';
    });
  }

  void setUuidToUse() {}

  @override
  Widget build(BuildContext context) {
    return Container(
        color: MY_APP_COLORS.darkBackground,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                      Color.fromARGB(255, 255, 87, 87), // Cambia el color de fondo aquí
                  ),
                  onPressed: _copyText,
                  child: const Text('Copiar mi UUID'),
                ),
                const SizedBox(height: 1),
                Text(
                  _copiedText,
                  style: const TextStyle(
                      fontSize: 10.0,
                      fontFamily: 'monospace',
                      color: Colors.white70,
                      fontStyle: FontStyle.italic),
                ),
                TextFormField(
                  initialValue: uuidToUse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, fontSize: 15.0),
                  decoration: const InputDecoration(
                    labelText: 'Pega un UUID',
                    labelStyle: TextStyle(color: Colors.white),
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                  ),
                  onFieldSubmitted: (value) =>
                      setState(() => {uuidToUse = value, setUuidToUse()}),
                ),
              ],
            )));
  }
}

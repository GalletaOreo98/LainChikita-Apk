import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ignore: library_prefixes
import '../app_colors.dart' as MY_APP_COLORS;
import '../functions/encryption_functions.dart';
import '../functions/gacha_functions.dart';
import '../global_vars.dart';
import '../private_keys.dart';

const secretKey = SECRET_KEY;

class GachaScreen extends StatefulWidget {
  final Function callback;

  const GachaScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<GachaScreen> {
  final _player = AudioPlayer(playerId: 'selectAccessory');
  String _copiedText = '';
  String _uuidToUse = '';

  Future<void> playSelectAccessorySound() async {
    await _player.play(AssetSource("audio/select_accessory_sound.mp3"));
  }

  void _copyMyData() async {
    final jsonData = json.encode({'username': username, 'useruuid': userUuid});
    final encryptedData = encryptData(jsonData, secretKey);
    Clipboard.setData(ClipboardData(text: encryptedData));
    setState(() {
      _copiedText = languageDataManager.getLabel('clipboard-is-copied');
    });
  }

  void _saveInventaries() {
    // Llamada a la función de callback
    widget.callback();
  }

  void _setUuidToUse() async {
    buyTicket();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    _saveInventaries();
  }

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
                Table(
                    //border: TableBorder.all(), // Borde para la tabla (opcional)
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Image.asset(
                              'assets/images/coin.png',
                              width: 32,
                              height: 32,
                              alignment: Alignment.centerRight,
                            ),
                          ),
                          TableCell(
                              verticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              child: Text(' x: $coins',
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    fontFamily: 'monospace',
                                    color: Colors.white,
                                  )))
                        ],
                      ),
                    ]),
                const SizedBox(height: 16),
                Text('${languageDataManager.getLabel('unlocked-skins')} x ${unlockedInventory.length}',
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontFamily: 'monospace',
                      color: Colors.white,
                    )),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 255, 87, 87), // Cambia el color de fondo aquí
                  ),
                  onPressed: _copyMyData,
                  child: Text(languageDataManager.getLabel('copy-my-public-data')),
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
                  initialValue: _uuidToUse,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.amber, fontSize: 15.0),
                  decoration: InputDecoration(
                    labelText: languageDataManager.getLabel('paste-public-data'),
                    labelStyle: const TextStyle(color: Colors.white),
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                  ),
                  onFieldSubmitted: (value) =>
                      setState(() => {_uuidToUse = value, _setUuidToUse()}),
                ),
              ],
            )));
  }
}

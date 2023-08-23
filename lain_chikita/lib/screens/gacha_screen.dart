import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ignore: library_prefixes
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
  String _copiedText = ''; // Avisa si ya se copio el texto en la clipboard
  String _userName = '';
  String _uuid = '';
  String _informativeText = '';
  Color _informativeTextColor = appColors.informativeText;
  void Function()? _buyTicket;

  Future<void> playSelectAccessorySound() async {
    await _player.play(AssetSource("audio/select_accessory_sound.mp3"));
  }

  // No hace falta optimizar pero se podria
  void hideInformativeText(String element, int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      setState(() {
        if (_copiedText == element) _copiedText = '';
        if (_informativeText == element) _informativeText = '';
      });
    });
  }

  void _copyMyData() async {
    final jsonData = json.encode({'username': username, 'useruuid': userUuid});
    final encryptedData = encryptData(jsonData, secretKey);
    Clipboard.setData(ClipboardData(text: encryptedData));
    setState(() {
      _copiedText = languageDataManager.getLabel('clipboard-is-copied');
      hideInformativeText(_copiedText, 2);
    });
  }

  void _saveInventaries() {
    // Llamada a la función de callback
    widget.callback();
  }

  void _readyToBuyTicket() {
    setState(() {
      _informativeTextColor = appColors.informativeText;
      _informativeText = 'Ticket para: $_userName';
    });
    _buyTicket = () {
      setState(() {
        _buyTicket = null;
        _informativeText = '¡Ticket comprado!';
      });
    };
  }

  void _setPublicDataToUse(String publicData) async {
    /* buyTicket();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins);
    _saveInventaries(); */
    String decryptedData;
    try {
      decryptedData = decryptData(publicData, secretKey);
    } catch (e) {
      setState(() {
        _buyTicket = null;
        _informativeTextColor = appColors.errorText;
        _informativeText = 'Error, datos publicos invalidos';
      });
      return;
    }
    Map<String, String> decryptedDataMap =
        Map<String, String>.from(json.decode(decryptedData));
    _userName = decryptedDataMap['username'] ?? '';
    _uuid = decryptedDataMap['useruuid'] ?? '';
    _readyToBuyTicket();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: appColors.background,
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
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontFamily: 'monospace',
                                    color: appColors.primaryText,
                                  )))
                        ],
                      ),
                    ]),
                const SizedBox(height: 16),
                Text(
                    '${languageDataManager.getLabel('unlocked-skins')} x ${unlockedInventory.length}',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontFamily: 'monospace',
                      color: appColors.primaryText,
                    )),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primaryBtn),
                  onPressed: _copyMyData,
                  child:
                      Text(languageDataManager.getLabel('copy-my-public-data')),
                ),
                const SizedBox(height: 1),
                Text(
                  _copiedText,
                  style: TextStyle(
                      fontSize: 10.0,
                      fontFamily: 'monospace',
                      color: appColors.informativeText,
                      fontStyle: FontStyle.italic),
                ),
                TextFormField(
                  initialValue: _uuid,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: appColors.userInputText, fontSize: 15.0),
                  decoration: InputDecoration(
                    labelText:
                        languageDataManager.getLabel('paste-public-data'),
                    labelStyle: TextStyle(color: appColors.primaryText),
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                  ),
                  onFieldSubmitted: (value) =>
                      setState(() => {_setPublicDataToUse(value)}),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: appColors.primaryBtn),
                  onPressed: _buyTicket,
                  child: const Text('BUY'),
                ),
                const SizedBox(height: 16),
                Text(
                  _informativeText,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontFamily: 'monospace',
                    color: _informativeTextColor,
                  ),
                ),
              ],
            )));
  }
}

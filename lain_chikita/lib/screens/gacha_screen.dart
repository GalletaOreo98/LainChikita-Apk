import 'package:flutter/material.dart';

//My imports
import '../functions/gacha_functions.dart';
import '../global_vars.dart';

class GachaScreen extends StatefulWidget {
  final Function callback;

  const GachaScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<GachaScreen> {
  /// Texto informativo sobre las acciones realizadas
  String _informativeText = '';
  Color _informativeTextColor = appColors.informativeText;

  void _buySkin() {
    setState(() {
      bool isDone = buyAccessory();
      if (isDone) {
        _informativeText = languageDataManager.getLabel('accessory-purchased');
        _informativeTextColor = appColors.informativeText;
        _saveInventories();
        _playAccessoryBoughtSound();
      } else {
        _informativeText = languageDataManager.getLabel('cannot-be-purchased');
        _informativeTextColor = appColors.errorText;
      }
    });
  }

  Future<void> _playAccessoryBoughtSound() async {
    await appAudioPlayer.playSound('audio/accessory_bought_sound.mp3');
  }

  void _saveInventories() {
    // Llamada a la función de callback
    widget.callback();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: appColors.background,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
                child: Column(
              children: [
                const SizedBox(height: 16),
                Table(
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
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Text(' x $coins',
                                  style: TextStyle(
                                    fontSize: 25.0,
                                    color: appColors.primaryText,
                                  )))
                        ],
                      ),
                    ]),
                const SizedBox(height: 16),
                Text(
                  (unlockedInventory.isNotEmpty) 
                  ? '${languageDataManager.getLabel('locked-accessories')} x ${unlockedInventory.length}'
                  : languageDataManager.getLabel('all-accessories-unlocked'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25.0,
                      color: appColors.primaryText,
                    )),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: _buySkin,
                  child: Text(languageDataManager.getLabel('buy-accessory'), 
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), 
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                Text(
                  _informativeText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25.0,
                    color: _informativeTextColor,
                  ),
                ),
              ],
            ))));
  }
}

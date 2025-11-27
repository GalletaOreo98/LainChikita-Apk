import 'package:flutter/material.dart';

//My imports
import '../functions/gacha_functions.dart';
import '../functions/redeem_codes_functions.dart';
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
  bool _showRedeemCode = false;
  final TextEditingController _redeemCodeTEC = TextEditingController(text: '');

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

  void _redeemCode(String code) async {
    setState(() {
      _informativeTextColor = appColors.informativeText;
      _informativeText = "${languageDataManager.getLabel('processing-code')}...";
    });
    
    String result = await redeemCode(code);
    
    setState(() {
      if (result.startsWith('accessory_unlocked')) {
        String unlockedAccessoryName = result.split(' ')[1];
        _informativeTextColor = appColors.informativeText;
        _informativeText = '${languageDataManager.getLabel('accessory-unlocked')}: \n${languageDataManager.getAccessoryName(unlockedAccessoryName)}';
        _playRedeemCodeSound();
        _saveInventories();
      } else if (result.startsWith('accessory_already_unlocked')) {
        String accessoryName = result.split(' ')[1];
        _informativeTextColor = appColors.errorText;
        _informativeText = '${languageDataManager.getLabel('already-have-this-item')}: \n${languageDataManager.getAccessoryName(accessoryName)}';
      } else if (result == 'cannot_unlock_more_accessories') {
        _informativeTextColor = appColors.errorText;
        _informativeText = languageDataManager.getLabel('all-accessories-unlocked');
      } else if (result == 'invalid_code') {
        _informativeTextColor = appColors.errorText;
        _informativeText = languageDataManager.getLabel('error-invalid-data');
      }
      else if (result == 'already_redeemed') {
        _informativeTextColor = appColors.errorText;
        _informativeText = languageDataManager.getLabel('code-already-redeemed');
      }
      _showRedeemCode = false;
    });
  }

  Future<void> _playAccessoryBoughtSound() async {
    await appAudioPlayer.playSound('audio/accessory_bought_sound.mp3');
  }

  Future<void> _playRedeemCodeSound() async {
    await appAudioPlayer.playSound2('audio/redeem_code_success_sound.mp3');
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.secondaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: () => setState(() {
                    _showRedeemCode = !_showRedeemCode;
                    if (!_showRedeemCode) {
                      _redeemCodeTEC.clear();
                      FocusManager.instance.primaryFocus?.unfocus();
                    }
                  }),
                  child: Text(languageDataManager.getLabel('redeem-code'), 
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), 
                      textAlign: TextAlign.center),
                ),
                if (_showRedeemCode)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _redeemCodeTEC,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: appColors.userInputText, fontSize: 35.0),
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => {
                                _redeemCode(_redeemCodeTEC.text),
                                _redeemCodeTEC.clear(),
                                FocusManager.instance.primaryFocus?.unfocus()
                              },
                              icon: const Icon(Icons.done),
                              color: appColors.userInputText
                            ),
                            labelText: languageDataManager.getLabel('enter-code'),
                            labelStyle: TextStyle(color: appColors.primaryText, fontSize: 20),
                            floatingLabelAlignment: FloatingLabelAlignment.center,
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.focusItem)),
                            enabledBorder:
                                UnderlineInputBorder(borderSide: BorderSide(color: appColors.userInputText))),
                        onSubmitted: (value) => _redeemCode(value),
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                    ],
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

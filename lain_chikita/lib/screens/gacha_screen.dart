import 'package:flutter/material.dart';
import 'dart:async';

//My imports
import '../classes/app_colors.dart';
import '../functions/achievements_manager.dart';
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
  Color _informativeTextColor = AppColors.informativeText;
  bool _showRedeemCode = false;
  final TextEditingController _redeemCodeTEC = TextEditingController(text: '');
  Timer? _hideTextTimer;

  void _buySkin() {
    if (mounted) {
      setState(() {
        bool isDone = buyAccessory();
        if (isDone) {
          _informativeText = languageDataManager.getLabel('accessory-purchased');
          _informativeTextColor = AppColors.informativeText;
          _saveInventories();
          _playAccessoryBoughtSound();
        } else {
          _informativeText = languageDataManager.getLabel('cannot-be-purchased');
          _informativeTextColor = AppColors.errorText;
        }
      });
    }
  }

  void _redeemCode(String code) async {
    if (mounted) {
      setState(() {
        _informativeTextColor = AppColors.informativeText;
        _informativeText = "${languageDataManager.getLabel('processing-code')}...";
      });
    }
    
    String result = await redeemCode(code);
    
    if (mounted) {
      setState(() {
        if (result.startsWith('accessory_unlocked')) {
          String unlockedAccessoryName = result.split(' ')[1];
          _informativeTextColor = AppColors.informativeText;
          _informativeText = '${languageDataManager.getLabel('accessory-unlocked')}: \n${languageDataManager.getAccessoryName(unlockedAccessoryName)}';
          _playRedeemCodeSound();
          _saveInventories();
        } else if (result.startsWith('accessory_already_unlocked')) {
          String accessoryName = result.split(' ')[1];
          _informativeTextColor = AppColors.errorText;
          _informativeText = '${languageDataManager.getLabel('already-have-this-item')}: \n${languageDataManager.getAccessoryName(accessoryName)}';
        } else if (result == 'cannot_unlock_more_accessories') {
          _informativeTextColor = AppColors.errorText;
          _informativeText = languageDataManager.getLabel('all-accessories-unlocked');
        } else if (result == 'invalid_code') {
          _informativeTextColor = AppColors.errorText;
          _informativeText = languageDataManager.getLabel('error-invalid-data');
        }
        else if (result == 'already_redeemed') {
          _informativeTextColor = AppColors.errorText;
          _informativeText = languageDataManager.getLabel('code-already-redeemed');
        }
        _showRedeemCode = false;
      });
    }
    
    if (result.startsWith('accessory_unlocked')) {
      await unlockAchievementById("CgkI8NLzkooQEAIQCA"); // "Let's All Love Lain" achievement
    }
  }

  Future<void> _playAccessoryBoughtSound() async {
    await appAudioPlayer.playSound1('audio/accessory_bought_sound.mp3');
  }

  Future<void> _playRedeemCodeSound() async {
    await appAudioPlayer.playSound2('audio/redeem_code_success_sound.mp3');
  }

  void _saveInventories() {
    // Llamada a la función de callback
    widget.callback();
  }

  @override
  void dispose() {
    // Cancel any pending timer to prevent setState() after dispose
    _hideTextTimer?.cancel();
    // Dispose text editing controller
    _redeemCodeTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: AppColors.background,
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
                                  style: const TextStyle(
                                    fontSize: 25.0,
                                    color: AppColors.primaryText,
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
                    style: const TextStyle(
                      fontSize: 25.0,
                      color: AppColors.primaryText,
                    )),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: AppColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: _buySkin,
                  child: Text(languageDataManager.getLabel('buy-accessory'), 
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 34.0), 
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: AppColors.secondaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _showRedeemCode = !_showRedeemCode;
                        if (!_showRedeemCode) {
                          _redeemCodeTEC.clear();
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      });
                    }
                  },
                  child: Text(languageDataManager.getLabel('redeem-code'), 
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 34.0), 
                      textAlign: TextAlign.center),
                ),
                if (_showRedeemCode)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _redeemCodeTEC,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.userInputText, fontSize: 35.0),
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => {
                                _redeemCode(_redeemCodeTEC.text),
                                _redeemCodeTEC.clear(),
                                FocusManager.instance.primaryFocus?.unfocus()
                              },
                              icon: const Icon(Icons.done),
                              color: AppColors.userInputText
                            ),
                            labelText: languageDataManager.getLabel('enter-code'),
                            labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 20),
                            floatingLabelAlignment: FloatingLabelAlignment.center,
                            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.focusItem)),
                            enabledBorder:
                                const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.userInputText))),
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

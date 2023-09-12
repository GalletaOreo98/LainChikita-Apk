import 'package:flutter/material.dart';

// My imports
import '../global_vars.dart';
import '../functions/encryption_functions.dart';
import '../private_keys.dart';

const secretKey = SECRET_KEY;

class EncryptionScreen extends StatefulWidget {
  const EncryptionScreen({super.key});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<EncryptionScreen> {
  String _informativeText = '';
  String _currentAction = '';

  void progressCallback(int i, int total) {
    setState(() {
      _informativeText =
          "$_currentAction...\n${languageDataManager.getLabel('do-not-leave-the-application')}\n${languageDataManager.getLabel('progress')}: $i / $total";
    });
  }

  void _encryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = languageDataManager.getLabel('encrypting');
      encryptFiles(secretKey, progressCallback).then(
          (value) => _updateInfoTxt("$_informativeText \n${languageDataManager.getLabel('completed').toUpperCase()}"));
    });
  }

  void _dencryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = languageDataManager.getLabel('decrypting');
      decryptFiles(secretKey, progressCallback).then(
          (value) => _updateInfoTxt("$_informativeText \n${languageDataManager.getLabel('completed').toUpperCase()}"));
    });
  }

  void _updateInfoTxt(String text) {
    setState(() {
      _informativeText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: appColors.background,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(320, 80),
                      backgroundColor: appColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: () => _encryptImages(),
                  child: Text(languageDataManager.getLabel('encrypt-images'),
                      style: const TextStyle(fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(320, 80),
                      backgroundColor: appColors.primaryBtn, padding: const EdgeInsets.all(20.0)),
                  onPressed: () => _dencryptImages(),
                  child: Text(languageDataManager.getLabel('decrypt-images'),
                      style: const TextStyle(fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                Text(_informativeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32.0,
                      color: appColors.informativeText,
                    ))
              ]),
            )));
  }
}

import 'package:flutter/material.dart';
// ignore: library_prefixes

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
          (value) => _updateInfoTxt("$_informativeText \n${languageDataManager.getLabel('completed').toUpperCase()}!"));
    });
  }

  void _dencryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = languageDataManager.getLabel('decrypting');
      decryptFiles(secretKey, progressCallback).then((value) =>
          _updateInfoTxt("$_informativeText \n¡${languageDataManager.getLabel('completed').toUpperCase()}!"));
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
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appColors.primaryBtn),
              onPressed: () => _encryptImages(),
              child: Text(languageDataManager.getLabel('encrypt-images')),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: appColors.primaryBtn),
              onPressed: () => _dencryptImages(),
              child: Text(languageDataManager.getLabel('decrypt-images')),
            ),
            const SizedBox(height: 16),
            Text(_informativeText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  fontFamily: 'monospace',
                  color: appColors.informativeText,
                ))
          ]),
        ));
  }
}

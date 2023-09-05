import 'package:flutter/material.dart';
// ignore: library_prefixes
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
      _informativeText = "$_currentAction...\nNo salgas de la aplicación\nProgreso: $i / $total";
    });
  }

  void _encryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = 'Encryptando';
      encryptFiles(secretKey, progressCallback).then((value) => _updateInfoTxt("$_informativeText \n¡Listo!"));
    });
  }

  void _dencryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = 'Desencryptando';
      decryptFiles(secretKey, progressCallback).then((value) => _updateInfoTxt("$_informativeText \n¡Listo!"));
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primaryBtn),
              onPressed: () => _encryptImages(),
              child: const Text("Encrypt images"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primaryBtn),
              onPressed: () => _dencryptImages(),
              child: const Text("Dencrypt images"),
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

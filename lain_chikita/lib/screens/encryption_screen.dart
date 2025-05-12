import 'package:flutter/material.dart';
import 'dart:convert' show json, jsonDecode;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';

// My imports
import '../global_vars.dart';
import '../functions/encryption_functions.dart' show decryptFiles, encryptFiles, encryptData, decryptData;
import '../private_keys.dart';

const secretKey = SECRET_KEY;

class EncryptionScreen extends StatefulWidget {
  final Function callback;
  const EncryptionScreen({super.key, required this.callback});

  @override
  MyWidgetState createState() => MyWidgetState();
}

class MyWidgetState extends State<EncryptionScreen> {
  String _informativeText = '';
  String _currentAction = '';
  bool _isWorking = false;
  bool _showBackupTextBox = false;
  final TextEditingController _backupDataTEC = TextEditingController(text: '');

  void _updateUI() {
    // Llamada a la función de callback
    widget.callback();
  }

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
      _isWorking = true;
      encryptFiles(progressCallback).then((value) => {
            _updateInfoTxt("$_informativeText \n${languageDataManager.getLabel('completed').toUpperCase()}"),
            _isWorking = false
          });
    });
  }

  void _dencryptImages() {
    setState(() {
      _informativeText = '';
      _currentAction = languageDataManager.getLabel('decrypting');
      _isWorking = true;
      decryptFiles(progressCallback).then((value) => {
            _updateInfoTxt("$_informativeText \n${languageDataManager.getLabel('completed').toUpperCase()}"),
            _isWorking = false
          });
    });
  }

  void _updateInfoTxt(String text) {
    setState(() {
      _informativeText = text;
    });
  }

  void _backupMyData() {
    //Formateo de los inventarios a json
    final jsonInventory = json.encode(inventory);
    final jsonUnlockedInventory = json.encode(unlockedInventory);
    //Formateo de la data necesaria a encriptar para hacer el backup
    final jsonData = json.encode({
      'userName': userName,
      'userUuid': userUuid,
      'level': level,
      'progress': progress,
      'userIv': userIv,
      'userSecretKey': userSecretKey,
      'accessoryName': accessoryName,
      'inventoryVersion': inventoryVersion,
      'inventory': jsonInventory,
      'unlockedInventory': jsonUnlockedInventory,
    });
    final encryptedData = encryptData(jsonData, secretKey);
    // Copiar la data ya encriptada al clipboard
    Clipboard.setData(ClipboardData(text: encryptedData));
    setState(() {
      _informativeText = "${languageDataManager.getLabel('clipboard-is-copied')}\n(${languageDataManager.getLabel('press-and-hold-button-to-see-more')})";
      hideInformativeText(2);
    });
  }

  void _applyBackup(String backupData) async {
    String decryptedData;
    try {
      decryptedData = decryptData(backupData, secretKey);
      Map<String, dynamic> decryptedDataMap = Map<String, dynamic>.from(json.decode(decryptedData));
      String userNameD = decryptedDataMap['userName'] ?? '';
      String userUuidD = decryptedDataMap['userUuid'] ?? '';
      int levelD = decryptedDataMap['level'] ?? 0;
      int progressD = decryptedDataMap['progress'] ?? 0;
      String userIvD = decryptedDataMap['userIv'] ?? '';
      String userSecretKeyD = decryptedDataMap['userSecretKey'] ?? '';
      String accessoryNameD = decryptedDataMap['accessoryName'] ?? '';
      int inventoryVersionD = decryptedDataMap['inventoryVersion'] ?? 0;
      List<Map<String, dynamic>> inventoryD =
          List<Map<String, dynamic>>.from(jsonDecode(decryptedDataMap['inventory'] ?? '[{}]'));
      List<Map<String, dynamic>> unlockedInventoryD =
          List<Map<String, dynamic>>.from(jsonDecode(decryptedDataMap['unlockedInventory'] ?? '[{}]'));
      //Save all progress
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', 0);
      await prefs.setString('userName', userNameD);
      await prefs.setString('userUuid', userUuidD);
      await prefs.setInt('level', levelD);
      await prefs.setInt('progress', progressD);
      await prefs.setString('userIv', userIvD);
      await prefs.setString('userSecretKey', userSecretKeyD);
      await prefs.setString('accessoryName', accessoryNameD);
      await prefs.setInt('inventoryVersion', inventoryVersionD);
      //Inventarios
      final jsonInventory = json.encode(inventoryD);
      await prefs.setString('inventory', jsonInventory);
      final jsonUnlockedInventory = json.encode(unlockedInventoryD);
      await prefs.setString('unlockedInventory', jsonUnlockedInventory);
      //Actualizar UI
      setState(() {
        coins = 0;
        userName = userNameD;
        userUuid = userUuidD;
        level = levelD;
        progress = progressD;
        userIv = userIvD;
        userSecretKey = userSecretKeyD;
        accessoryName = accessoryNameD;
        inventoryVersion = inventoryVersionD;
        inventory = inventoryD;
        unlockedInventory = unlockedInventoryD;
        _informativeText = "${languageDataManager.getLabel('backup-completed')}\n${languageDataManager.getLabel('restart-your-app')}";
        _updateUI();
      });
    } catch (e) {
      setState(() {
        _informativeText = languageDataManager.getLabel('error-invalid-data');
      });
    }
  }

  void hideInformativeText(int seconds) {
    Future.delayed(Duration(seconds: seconds), () {
      setState(() {
        _informativeText = '';
      });
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
                        minimumSize: const Size(380, 80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        backgroundColor: appColors.secondaryBtn,
                        padding: const EdgeInsets.all(20.0)),
                    onPressed: _backupMyData,
                    onLongPress: () => setState(() {
                          _showBackupTextBox = true;
                        }),
                    child: Text(languageDataManager.getLabel('backup'),
                        style: TextStyle(
                          color: appColors.primaryText,
                          fontSize: 34.0,
                        ),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 16),
                if (_showBackupTextBox)
                  Column(
                    children: [
                      //Textbox de "Pegar datos de ticket a reclamar"
                      TextField(
                        controller: _backupDataTEC,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: appColors.userInputText, fontSize: 35.0),
                        decoration: InputDecoration(
                            suffixIcon: IconButton(
                                onPressed: () => {
                                      _applyBackup(_backupDataTEC.text),
                                      _backupDataTEC.clear(),
                                      FocusManager.instance.primaryFocus?.unfocus()
                                    },
                                icon: const Icon(Icons.done),
                                color: appColors.userInputText),
                            labelText: languageDataManager.getLabel('paste-backup-data'),
                            labelStyle: TextStyle(color: appColors.primaryText, fontSize: 20),
                            floatingLabelAlignment: FloatingLabelAlignment.center,
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.focusItem)),
                            enabledBorder:
                                UnderlineInputBorder(borderSide: BorderSide(color: appColors.userInputText))),
                        onSubmitted: (value) => setState(() {_applyBackup(value);}),
                        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.primaryBtn,
                      padding: const EdgeInsets.all(20.0)),
                  onPressed: () => _encryptImages(),
                  child: Text(languageDataManager.getLabel('encrypt-files'),
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.primaryBtn,
                      padding: const EdgeInsets.all(20.0)),
                  onPressed: () => _dencryptImages(),
                  child: Text(languageDataManager.getLabel('decrypt-files'),
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
                if (_isWorking) Image.asset('assets/images/working.gif'),
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

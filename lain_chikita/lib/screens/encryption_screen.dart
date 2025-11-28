import 'package:flutter/material.dart';
import 'dart:convert' show json, jsonDecode;
//import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games_services/games_services.dart';

// My imports
import '../functions/achievements_manager.dart';
import '../functions/prefs_version_manager.dart';
import '../global_vars.dart';
//import '../functions/encryption_functions.dart' show decryptFiles, encryptFiles, encryptData, decryptData;
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
  //String _currentAction = '';
  bool _isWorking = false;
  //bool _showBackupTextBox = false;
  bool _isSignedIn = false;
  //final TextEditingController _backupDataTEC = TextEditingController(text: '');

  void _updateUI() {
    // Llamada a la función de callback
    widget.callback();
  }

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  void _checkSignInStatus() async {
    try {
      final isSignedIn = await GameAuth.isSignedIn;
      setState(() {
        _isSignedIn = isSignedIn;
      });
    } catch (e) {
      setState(() {
        _isSignedIn = false;
      });
    }
  }

/*   void progressCallback(int i, int total) {
    setState(() {
      _informativeText =
          "$_currentAction...\n${languageDataManager.getLabel('do-not-leave-the-application')}\n${languageDataManager.getLabel('progress')}: $i / $total";
    });
  } */

/*   void _encryptImages() {
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
  } */

/*   void _updateInfoTxt(String text) {
    setState(() {
      _informativeText = text;
    });
  } */

/*   void _backupMyData() {
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
  } */

/*   void _applyBackup(String backupData) async {
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
      //Apply Save all progress
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
  } */

  void _signInToGameServices() async {
    try {
      await GameAuth.signIn();
      _checkSignInStatus(); // Actualizar el estado de sign-in
      setState(() {
        _informativeText = "${languageDataManager.getLabel('completed').toUpperCase()}: Game Services Sign In";
        hideInformativeText(3);
      });
    } catch (e) {
      setState(() {
        _informativeText = "Error: $e";
        hideInformativeText(5);
      });
    }
  }

  void _showAchievements() async {
    try {
      setState(() {
        _isWorking = true;
        _informativeText = "${languageDataManager.getLabel('loading')}...";
      });
      await Achievements.showAchievements();
      setState(() {
        _isWorking = false;
        //_informativeText = languageDataManager.getLabel('completed');
        hideInformativeText(3);
      });
    } catch (e) {
      setState(() {
        _isWorking = false;
        _informativeText = "Error: $e";
        hideInformativeText(5);
      });
    }
  }

  void _showLeaderboards() async {
    try {
      setState(() {
        _isWorking = true;
        _informativeText = "${languageDataManager.getLabel('loading')}...";
      });
      await Leaderboards.showLeaderboards(androidLeaderboardID: 'CgkI8NLzkooQEAIQDA'); // Cookies Leaderboard
      setState(() {
        _isWorking = false;
        //_informativeText = languageDataManager.getLabel('completed');
        hideInformativeText(3);
      });
    } catch (e) {
      setState(() {
        _isWorking = false;
        _informativeText = "Error: $e";
        hideInformativeText(5);
      });
    }
  }



  void _saveGameData() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appColors.background,
          title: Text(
            languageDataManager.getLabel('confirm-save-progress'),
            style: TextStyle(color: appColors.primaryText, fontSize: 24.0),
          ),
          content: Text(
            languageDataManager.getLabel('save-progress-overwrite-alert'),
            style: TextStyle(color: appColors.primaryText, fontSize: 24.0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                languageDataManager.getLabel('cancel'),
                style: TextStyle(color: appColors.primaryText, fontSize: 30.0),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                languageDataManager.getLabel('save'),
                style: TextStyle(color: appColors.focusItem, fontSize: 30.0),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      _playcancelSound();
      return; // User cancelled
    }

    try {
      _playAcceptPopupSound();
      setState(() {
        _isWorking = true;
        _informativeText = "${languageDataManager.getLabel('packing-data')}...";
      });
      // Formateo de los inventarios a json
      final jsonInventory = json.encode(inventory);
      final jsonUnlockedInventory = json.encode(unlockedInventory);
      // Formateo de la data del juego (sin encriptar)
      final gameData = {
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
      };
      final data = json.encode(gameData);
      //print('Saving game data: $data');
      setState(() {_informativeText = "${languageDataManager.getLabel('sending-data')}...";});
      await GameAuth.signIn();
      
      await SaveGame.saveGame(data: data, name: "slot1");

      setState(() {_informativeText = languageDataManager.getLabel('data-sent');});

      await unlockAchievementById("CgkI8NLzkooQEAIQBw"); // KeepYourLoveSafe achievement

      setState(() {
        _isWorking = false;
        _informativeText = languageDataManager.getLabel('save-progress-successful');
        hideInformativeText(4);
      });
    } catch (e) {
      setState(() {
        _isWorking = false;
        _informativeText = "Error saving data: $e";
        hideInformativeText(5);
      });
    }
  }

  void _loadGameData() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: appColors.background,
          title: Text(
            languageDataManager.getLabel('confirm-load-progress'),
            style: TextStyle(color: appColors.primaryText, fontSize: 24.0),
          ),
          content: Text(
            languageDataManager.getLabel('load-progress-overwrite-alert'),
            style: TextStyle(color: appColors.primaryText, fontSize: 24.0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                languageDataManager.getLabel('cancel'),
                style: TextStyle(color: appColors.primaryText, fontSize: 30.0),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                languageDataManager.getLabel('load'),
                style: TextStyle(color: appColors.focusItem, fontSize: 30.0),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      _playcancelSound();
      return; // User cancelled
    }

    try {
      _playAcceptPopupSound();
      setState(() {
        _isWorking = true;
      });
      await GameAuth.signIn();

      
      setState(() {_informativeText = "${languageDataManager.getLabel('receiving-data')}...";});
        
      final saveData = await SaveGame.loadGame(name: "slot1");
      
      setState(() {_informativeText = languageDataManager.getLabel('data-received');});
        
      if (saveData != null) {
        setState(() {_informativeText = "${languageDataManager.getLabel('ordering-data')}...";});
        Map<String, dynamic> gameData = Map<String, dynamic>.from(json.decode(saveData));
        String userNameD = gameData['userName'] ?? '';
        String userUuidD = gameData['userUuid'] ?? '';
        int levelD = gameData['level'] ?? 0;
        int progressD = gameData['progress'] ?? 0;
        String userIvD = gameData['userIv'] ?? '';
        String userSecretKeyD = gameData['userSecretKey'] ?? '';
        String accessoryNameD = gameData['accessoryName'] ?? '';
        int inventoryVersionD = gameData['inventoryVersion'] ?? 0;
        List<Map<String, dynamic>> inventoryD =
            List<Map<String, dynamic>>.from(jsonDecode(gameData['inventory'] ?? '[{}]'));
        List<Map<String, dynamic>> unlockedInventoryD =
            List<Map<String, dynamic>>.from(jsonDecode(gameData['unlockedInventory'] ?? '[{}]'));
        
        // Check inventory version and apply update if necessary
        List<Map<String, dynamic>> appUnlockedInventory = unlockedInventory.toList();
        if (inventoryVersion != inventoryVersionD) {
          final thisUnlockedInventory = unlockedInventoryD.toList();
          unlockedInventoryD = applyInventoryVerionUpdate(thisUnlockedInventory, appUnlockedInventory, inventoryD);
          inventoryVersionD = inventoryVersion;
        }
        
        setState(() {_informativeText = "${languageDataManager.getLabel('applying-data')}...";});

        // Save all progress to SharedPreferences
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
          
        // Inventarios
        final jsonInventory = json.encode(inventoryD);
        await prefs.setString('inventory', jsonInventory);
        final jsonUnlockedInventory = json.encode(unlockedInventoryD);
        await prefs.setString('unlockedInventory', jsonUnlockedInventory);

        setState(() {_informativeText = "${languageDataManager.getLabel('loading-achievements')}...";});

        // Cargar achievements a la variable global
        await loadAchievementsToGlobalVars();
        
        await unlockAchievementById("CgkI8NLzkooQEAIQCg"); // WelcomeToTheWired achievement

        if (coins >= 1) await unlockAchievementById("CgkI8NLzkooQEAIQCw"); // "I have lost it all" achievement

        setState(() {_informativeText = "${languageDataManager.getLabel('updating-ui')}...";});
          
        // Actualizar UI
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
          _isWorking = false;
          _informativeText = "${languageDataManager.getLabel('load-progress-successful')}\n${languageDataManager.getLabel('restart-your-app')}";
          _updateUI();
        });
        } else {
          setState(() {
            _isWorking = false;
            _informativeText = "Error: No saved data found.";
            hideInformativeText(5);
          });
        }    
    } catch (e) {
      setState(() {
        _isWorking = false;
        _informativeText = "Error loading data: $e";
        hideInformativeText(5);
      });
    }
  }

  Future<void> _playInformativePopupSound() async {
    await appAudioPlayer.playSound('audio/informative_popup_sound.mp3');
  }

  Future<void> _playAcceptPopupSound() async {
    await appAudioPlayer.playSound2('audio/accept_popup_sound.mp3');
  }

    Future<void> _playcancelSound() async {
    await appAudioPlayer.playSound3('audio/cancel_sound.mp3');
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
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              child: Column(children: [
/*                 ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(380, 80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        backgroundColor: appColors.secondaryBtn,
                        padding: const EdgeInsets.all(10.0)),
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
                const SizedBox(height: 8), */
/*                 if (_showBackupTextBox)
                  Column(
                    children: [
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
                      const SizedBox(height: 8),
                    ],
                  ), */
/*                 ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.primaryBtn,
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: () => _encryptImages(),
                  child: Text(languageDataManager.getLabel('encrypt-files'),
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), textAlign: TextAlign.center),
                ), */
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: const Color.fromARGB(255, 24, 110, 3),
                      padding: const EdgeInsets.all(10.0),
                      disabledBackgroundColor: const Color.fromARGB(255, 133, 133, 133)),
                  onPressed: _isSignedIn ? null : () => _signInToGameServices(),
                  child: Text(
                      _isSignedIn 
                        ? languageDataManager.getLabel('connected') 
                        : languageDataManager.getLabel('connect-with-google'),
                      style: TextStyle(
                        color: appColors.primaryText, 
                        fontSize: 34.0
                      ), 
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: const Color.fromARGB(255, 207, 127, 23),
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: _isSignedIn ? () async {
                    _playInformativePopupSound();
                    _showAchievements();
                  } : null,
                  child: Text( languageDataManager.getLabel('achievements'),
                      style: TextStyle(color: _isSignedIn ? appColors.primaryText : const Color.fromARGB(255, 170, 170, 170), fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: const Color.fromARGB(255, 156, 39, 176),
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: _isSignedIn ? () async {
                    _playInformativePopupSound();
                    _showLeaderboards();
                  } : null,
                  child: Text(languageDataManager.getLabel('leaderboards'),
                      style: TextStyle(color: _isSignedIn ? appColors.primaryText : const Color.fromARGB(255, 170, 170, 170), fontSize: 34.0), textAlign: TextAlign.center),
                ),


                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: const Color.fromARGB(255, 32, 105, 189),
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: (_isSignedIn && userName != "NULLUSER")
                      ? () async {
                          _playInformativePopupSound();
                          _saveGameData();
                        }
                      : null,
                  child: Text(languageDataManager.getLabel('save-progress'),
                      style: TextStyle(color: (_isSignedIn && userName != "NULLUSER") ? appColors.primaryText : const Color.fromARGB(255, 170, 170, 170), fontSize: 34.0), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: const Color.fromARGB(255, 78, 24, 177),
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: _isSignedIn 
                    ? () async { 
                     _playInformativePopupSound();
                     _loadGameData(); 
                    }
                     : null,
                  child: Text(languageDataManager.getLabel('load-progress'),
                      style: TextStyle(color: _isSignedIn ? appColors.primaryText : const Color.fromARGB(255, 170, 170, 170), fontSize: 34.0), textAlign: TextAlign.center),
                ),
/*                 const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(380, 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      backgroundColor: appColors.primaryBtn,
                      padding: const EdgeInsets.all(10.0)),
                  onPressed: () => _encryptImages(),
                  child: Text(languageDataManager.getLabel('encrypt-files'),
                      style: TextStyle(color: appColors.primaryText, fontSize: 34.0), textAlign: TextAlign.center),
                ),
                 */

                const SizedBox(height: 16),
                if (_isWorking) Image.asset('assets/images/working.gif'),
                const SizedBox(height: 8),
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

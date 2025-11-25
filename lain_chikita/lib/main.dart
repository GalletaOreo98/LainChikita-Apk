import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemUiMode, SystemChrome, KeyEvent, KeyDownEvent, LogicalKeyboardKey;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show json, jsonDecode;
import 'dart:ui' show PlatformDispatcher;
import 'package:games_services/games_services.dart';


//My imports
import 'functions/achievements_manager.dart';
import 'functions/prefs_version_manager.dart';
import 'global_vars.dart';
import 'private_keys.dart';
import 'functions/encryption_functions.dart';
import 'functions/write_read_files_functions.dart';
import 'functions/directory_path_provider.dart';
import 'functions/gacha_functions.dart' show generateSecureRandom;

//screens
import 'screens/inventory_screen.dart';
import 'screens/gacha_screen.dart';
import 'screens/encryption_screen.dart';

//App vars
const int _maxProgress = 20;
const secretKey = SECRET_KEY;

void main() {
  //Lo pongo asi nada mas para asegurar, por si acaso... pero funciona con == 'es'
  if (PlatformDispatcher.instance.locale.languageCode.toLowerCase().contains('es')) language = 'es';
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PageController _pageController;
  final focusNode = FocusNode();
  String _appBackground = 'background-night';
  /// Para mostrar decoraciones cuando haya fechas especiales
  bool _specialEvent = false;
  final TextEditingController _userNameTEC = TextEditingController(text: 'NULLUSER');

  /// Cuando el usuario actualiza la aplicacion a una nueva versión de [inventoryVersion] se mostrará la animación
  bool wasUpdated = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Carga progreso y configuraciones necesarias en general
  Future<void> _loadProgress() async {
    if (_isMoorning()) _appBackground = 'background-day';
    if (generateSecureRandom(10) == 3) _specialEvent = true;
    //Carga directorios de la app y crea los folders si es necesario
    appDirectoryStorage = await getAppDirectoryStorage();
    await createEncryptionFolders();
    //Revisa si el usuario tiene userUuid
    final prefs = await SharedPreferences.getInstance();
    userUuid = prefs.getString("userUuid") ?? "";
    if (userUuid.isEmpty) {
      userUuid = generateCryptoRngUuid();
      await prefs.setString('userUuid', userUuid);
    }
    //Revisa si el usuario tiene su userSecretKey Y su userIV
    userSecretKey = prefs.getString("userSecretKey") ?? "";
    if (userSecretKey.isEmpty) {
      userSecretKey = generateUserSecretKey(32);
      await prefs.setString('userSecretKey', userSecretKey);
    }
    userIv = prefs.getString("userIv") ?? "";
    if (userIv.isEmpty) {
      userIv = generateUserIV(16);
      await prefs.setString('userIv', userIv);
    }
    int thisInventoryVersion = prefs.getInt('inventoryVersion') ?? 1;
    if (thisInventoryVersion == 1) {
      await prefs.setInt('inventoryVersion', inventoryVersion);
      //thisInventoryVersion = inventoryVersion;
    }
    //Inventarios
    final jsonInventory = prefs.getString('inventory') ?? '';
    if (jsonInventory.isNotEmpty) {
      inventory = List<Map<String, dynamic>>.from(jsonDecode(jsonInventory));
    }
    //Check unlockedInventory version
    //(Se podria optimizar...)
    List<Map<String, dynamic>> appUnlockedInventory = unlockedInventory.toList();
    final jsonUnlockedInventory = prefs.getString('unlockedInventory') ?? '';
    if (jsonUnlockedInventory.isNotEmpty) {
      unlockedInventory = List<Map<String, dynamic>>.from(jsonDecode(jsonUnlockedInventory));
    }
    if (inventoryVersion != thisInventoryVersion) {
      final thisUnlockedInventory = unlockedInventory.toList();
      unlockedInventory = applyInventoryVerionUpdate(thisUnlockedInventory, appUnlockedInventory, inventory);
      await prefs.setInt('inventoryVersion', inventoryVersion);
      final jsonUnlockedInventoryToSet = json.encode(unlockedInventory);
      await prefs.setString('unlockedInventory', jsonUnlockedInventoryToSet);
      runUpdateAnimation(5); //En esta funcion se hace el wasUpdated = true;
      _playUpdatedSound();
    }
    //Carga los nombres de los items del inventario segun el lenguaje del dispositivo
    await languageDataManager.loadAccessoryNames(language);
    await languageDataManager.loadLabels(language);
    //Carga los datos guardados en SharedPreferences
    setState(() {
      level = prefs.getInt('level') ?? 0;
      progress = prefs.getInt('progress') ?? 0;
      userName = prefs.getString('userName') ?? "NULLUSER";
      accessoryName = prefs.getString('accessoryName') ?? "null";
      coins = prefs.getInt('coins') ?? 0;
      //Carga logros a variables globales
      loadAchievementsToGlobalVars();

      if (userName != "NULLUSER") {
        writeAThankUTxt();
      }
    });
  }

  //Funcion posible para optimizar dividiendola en varios tipos de save
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setInt('progress', progress);
    await prefs.setString('userName', userName);
    await prefs.setInt('coins', coins);
  }

  Future<void> _saveInventaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonInventory = json.encode(inventory);
    await prefs.setString('inventory', jsonInventory);
    final jsonUnlockedInventory = json.encode(unlockedInventory);
    await prefs.setString('unlockedInventory', jsonUnlockedInventory);
  }

  Future<void> _saveAccesorrySelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessoryName', accessoryName);
  }

  Future<void> _saveProgressOnGooglePlayGames() async {
    try {
      final isSignedIn = await GameAuth.isSignedIn;
      if (!isSignedIn) return;
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
      
      await GameAuth.signIn();
      await SaveGame.saveGame(data: data, name: "slot1");
    } catch (e) {
      print('Error saving game data to Google Play Games: $e');
    }
  }

  Future<void> _playLoveBtnSound() async {
    await appAudioPlayer.playSound('audio/btn_sound.mp3');
  }

  Future<void> _playLevelUpSound() async {
    await appAudioPlayer.playSound2('audio/level_up_sound.mp3');
  }

  Future<void> _playUpdatedSound() async {
    if (wasUpdated) await appAudioPlayer.playSound('audio/updated_sound.mp3');
  }

  bool _isMoorning() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) return true;
    return false;
  }

  void runUpdateAnimation(int seconds) {
    setState(() {
      wasUpdated = true;
    });
    Future.delayed(Duration(seconds: seconds), () {
      setState(() {
        wasUpdated = false;
      });
    });
  }

  void _incrementProgress() {
    _playLoveBtnSound();
    setState(() {
      progress += 1;
      if (progress >= _maxProgress) {
        progress = 0;
        level += 1;
        if (level % 50 == 0) {
          incrementAchievementsStepType();
        }
        if (level % 100 == 0) {
          coins++;
          _playLevelUpSound();
          saveCookiesScore();
          _saveProgressOnGooglePlayGames();
        }
      }
      _saveProgress();
    });
  }

  void _updateAccessory(String newAccessoryName) {
    setState(() {
      accessoryName = newAccessoryName;
      _saveAccesorrySelection();
    });
  }

  void _updateUI() {
    setState(() {
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event.runtimeType == KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ) {
        // Cambiar a la siguiente pantalla
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        // Cambiar a la pantalla anterior
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Lain Chikita',
        theme: ThemeData(fontFamily: 'monogram'),
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
        children: [
          KeyboardListener(
            focusNode: focusNode,
            onKeyEvent: _handleKeyEvent,
            child: PageView(
              controller: _pageController,
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/$_appBackground.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (userName == "NULLUSER")
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          const SizedBox(height: 16),
                          TextField(
                            controller: _userNameTEC,
                            textAlign: TextAlign.center,
                            maxLength: 15,
                            style: TextStyle(color: appColors.nameLabel, fontSize: 34.0),
                            decoration: InputDecoration(
                                suffixIcon: IconButton(
                                    onPressed: () => setState(() {
                                          userName = _userNameTEC.text;
                                          _saveProgress();
                                          writeAThankUTxt();
                                          FocusManager.instance.primaryFocus?.unfocus();
                                        }),
                                    icon: const Icon(Icons.done),
                                    color: appColors.focusItem),
                                labelText: languageDataManager.getLabel('new-user-name'),
                                labelStyle: TextStyle(color: appColors.primaryText, fontSize: 34.0),
                                floatingLabelAlignment: FloatingLabelAlignment.center,
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: appColors.focusItem)),
                                enabledBorder:
                                    UnderlineInputBorder(borderSide: BorderSide(color: appColors.userInputText))),
                            onSubmitted: (value) =>
                                setState(() {userName = value; _saveProgress(); writeAThankUTxt();}),
                            onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
                          )
                        ])
                      else
                        Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  userName,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 48.0,
                                    color: appColors.nameLabel,
                                  ),
                                )
                              ],
                            )),
                      if (userName != "NULLUSER")
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 30), // Ajuste del margen superior
                            child: Transform.translate(
                              offset: const Offset(0, -30), // Ajuste de la posición vertical main character image
                              child: Image.asset(
                                'assets/images/lain_chikita.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        if (userName != "NULLUSER")
                        Positioned(
                          child: Center(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                            onTap: _incrementProgress,
                            child: Container(
                              margin: const EdgeInsets.only(top: 30),
                              child: Transform.translate(
                                offset: const Offset(0, -30),
                                child: Image.asset(
                                  'assets/images/accessories/$accessoryName.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            ),
                          ),
                          ),
                        ),
                      if (wasUpdated)
                        Positioned(
                          child: Center(
                            child: GestureDetector(
                              onTap: _incrementProgress,
                              child: Image.asset(
                                'assets/images/updated.gif',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.05),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${languageDataManager.getLabel('level')} $level',
                                style: TextStyle(
                                  fontSize: 40.0,
                                  color: appColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              SizedBox(
                                height: 16.0,
                                width: 250.0,
                                child: LinearProgressIndicator(
                                  value: progress / _maxProgress,
                                  backgroundColor: appColors.loveBarOpposite,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    appColors.loveBar,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              FloatingActionButton(
                                backgroundColor: appColors.loveBtn,
                                onPressed: _incrementProgress,
                                shape: const CircleBorder(),
                                child: Icon(
                                  Icons.favorite,
                                  color: appColors.loveBtnOpposite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InventoryScreen(callback: _updateAccessory),
                GachaScreen(callback: _saveInventaries),
                EncryptionScreen(callback: _updateUI),
              ],
            ),
          ), 
          if (_specialEvent)
          IgnorePointer(
            ignoring: true,
            child: Image.asset(
              'assets/images/snowing.gif',
              fit: BoxFit.cover, // O ajusta según tus necesidades
            ),
          ),
        ],)));
  }
}
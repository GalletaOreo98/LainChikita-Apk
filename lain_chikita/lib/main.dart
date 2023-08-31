import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
//My custom imports
import 'functions/encryption_functions.dart';
import 'global_vars.dart';
import 'private_keys.dart';
import 'functions/write_read_files_functions.dart';

//screens
import 'screens/inventory_screen.dart';
import 'screens/gacha_screen.dart';

//App vars
const int _maxProgress = 20;
const secretKey = SECRET_KEY;

void main() {
  //Lo pongo asi nada mas para asegurar, por si acaso... pero funciona con == 'es'
  if (window.locale.languageCode.toLowerCase().contains('es')) language = 'es';
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late PageController _pageController;
  final focusNode = FocusNode();

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
    final prefs = await SharedPreferences.getInstance();
    userUuid = prefs.getString("userUuid") ?? "";
    if (userUuid.isEmpty) {
      userUuid = generateCryptoRngUuid();
      await prefs.setString('userUuid', userUuid);
    }
    //Carga los nombres de los items del inventario segun el lenguaje del dispositivo
    await languageDataManager.loadAccessoryNames(language);
    await languageDataManager.loadLabels(language);
    setState(() {
      level = prefs.getInt('level') ?? 0;
      progress = prefs.getInt('progress') ?? 0;
      username = prefs.getString('username') ?? "NULLUSER";
      accessoryName = prefs.getString('accessoryName') ?? "null";
      coins = prefs.getInt('coins') ?? 2;
      //Inventarios
      final jsonInventory = prefs.getString('inventory') ?? '';
      if (jsonInventory.isNotEmpty) {
        inventory = List<Map<String, dynamic>>.from(jsonDecode(jsonInventory));
      }
      final jsonUnlockedInventory = prefs.getString('unlockedInventory') ?? '';
      if (jsonUnlockedInventory.isNotEmpty) {
        unlockedInventory =
            List<Map<String, dynamic>>.from(jsonDecode(jsonUnlockedInventory));
      }
    });
  }

  //Funcion posible para optimizar dividiendola en varios tipos de save
  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', level);
    await prefs.setInt('progress', progress);
    await prefs.setString('username', username);
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

  Future<void> _playLoveBtnSound() async {
    await appAudioPlayer.playSound('audio/btn_sound.mp3');
  }

  void _incrementProgress() {
    _playLoveBtnSound();
    setState(() {
      progress += 1;
      if (progress >= _maxProgress) {
        progress = 0;
        level += 1;
        if (level % 100 == 0) {
          coins++;
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

  void _handleKeyEvent(RawKeyEvent event) {
    if (event.runtimeType == RawKeyDownEvent) {
      if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
        // Cambiar a la siguiente pantalla
        _pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
      } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
        // Cambiar a la pantalla anterior
        _pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Lain Chikita',
        home: Scaffold(
          body: RawKeyboardListener(
            focusNode: focusNode,
            onKey: _handleKeyEvent,
            child: PageView(
              controller: _pageController,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (username == "NULLUSER")
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            Form(
                              child: TextFormField(
                                initialValue: username,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: appColors.nameLabel),
                                decoration: InputDecoration(
                                  labelText: languageDataManager.getLabel('new-user-name'),
                                  labelStyle: TextStyle(color: appColors.primaryText),
                                  floatingLabelAlignment:
                                      FloatingLabelAlignment.center,
                                ),
                                onFieldSubmitted: (value) => setState(
                                    () => {
                                      username = value, _saveProgress(),
                                      writeAThankUTxt()
                                    }),
                              ),
                            )
                          ],
                        )
                      else
                        Align(
                            alignment: Alignment.topCenter,
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Text(
                                  username,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: appColors.nameLabel,
                                  ),
                                )
                              ],
                            )),
                      Center(
                        child: Image.asset(
                          'assets/images/lain_chikita.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        child: Center(
                          child: Image.asset(
                              'assets/images/accessories/$accessoryName.png',
                              fit: BoxFit.cover),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${languageDataManager.getLabel('level')} $level',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
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
                                  valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                    appColors.loveBar,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              FloatingActionButton(
                                backgroundColor: appColors.loveBtn,
                                onPressed: _incrementProgress,
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
              ],
            ),
          ),
        ));
  }
}

/* class CustomScreen extends StatelessWidget {
  final Color color;

  const CustomScreen({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: const Center(
        child: Text('Custom Screen'),
      ),
    );
  }
} */

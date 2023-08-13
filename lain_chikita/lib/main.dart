import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:ui';


//My custom imports
import 'functions/encryption_functions.dart';
import 'global_vars.dart';
import 'private_keys.dart';

//screens
import 'screens/inventory_screen.dart';
import 'screens/gacha_screen.dart';

//App vars
const int _maxProgress = 20;
final _player = AudioPlayer(playerId: 'btnLove');
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
  
  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> playBtnSound() async {
    await _player.play(AssetSource("audio/btn_sound.mp3"));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    userUuid = prefs.getString("userUuid") ?? "";
    if (userUuid.isEmpty){
        userUuid = generateCryptoRngUuid();
        await prefs.setString('userUuid', userUuid);
    }
    //Carga los nombres de los items del inventario segun el lenguaje del dispositivo
    await dataManager.loadShowedNames(language);
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
        unlockedInventory = List<Map<String, dynamic>>.from(jsonDecode(jsonUnlockedInventory));
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
    //Pasar inventarios a string para almacenar
    //OJO PONER EN OTRO SAVE FUNCTION ESTA PARTE DE LOS INVENTARIOS PARA MEJORAR RENDIMIENTO
    /* final jsonInventory = json.encode(inventory);
    await prefs.setString('inventory', jsonInventory);
    final jsonUnlockedInventory = json.encode(unlockedInventory);
    await prefs.setString('unlockedInventory', jsonUnlockedInventory); */
  }

  Future<void> _saveInventaries() async{
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

  void _incrementProgress() {
    setState(() {
      playBtnSound();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lain Chikita',
      home: Scaffold(
        body: PageView(
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
                            style: const TextStyle(color: Colors.amber),
                            decoration: const InputDecoration(
                              labelText: 'Nuevo nombre de usuario',
                              labelStyle: TextStyle(color: Colors.white),
                              floatingLabelAlignment:
                                  FloatingLabelAlignment.center,
                            ),
                            onFieldSubmitted: (value) =>
                                setState(() => {
                                  username = value,
                                  _saveProgress()
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
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Colors.amber,
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
                            'Nivel ${level}',
                            style: const TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          SizedBox(
                            height: 16.0,
                            width: 250.0,
                            child: LinearProgressIndicator(
                              value: progress / _maxProgress,
                              backgroundColor: Colors.white,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 248, 187, 208),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          FloatingActionButton(
                            backgroundColor: Colors.pink[100],
                            onPressed: _incrementProgress,
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
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
    );
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'functions/encryption_functions.dart';
import 'global_vars.dart' as global;

Future<void> main() async {
  await dotenv.load();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //App vars
  final int _maxProgress = 20;
  final _player = AudioPlayer(playerId: 'btnLove');
  bool showImage = false;

  final secretKey = dotenv.env['SECRET_KEY'];

  void _handleUserChoice(bool value) {
    setState(() {
      final jsonData = json.encode({'level': global.level, 'progress': global.progress, 'username': global.username});
      final encryptedData = encryptData(jsonData, secretKey!);
      decryptData(encryptedData, secretKey!);
      if (global.level >= 100) showImage = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProgress().then((value) => _showEncryptedData());
  }

  Future<void> playBtnSound() async {
    await _player.play(AssetSource("audio/btn_sound.mp3"));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      global.level = prefs.getInt('level') ?? 0;
      global.progress = prefs.getInt('progress') ?? 0;
      global.username = prefs.getString('username') ?? "NULLUSER";
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', global.level);
    await prefs.setInt('progress', global.progress);
    await prefs.setString('username', global.username);
  }

  void _incrementProgress() {
    setState(() {
      playBtnSound();
      global.progress += 1;
      if (global.progress >= _maxProgress) {
        global.progress = 0;
        global.level += 1;
      }
      _saveProgress();
    });
  }

  void _showEncryptedData() {
    final jsonData = json.encode({'level': global.level, 'progress': global.progress, 'username': global.username});
    final encryptedData = encryptData(jsonData, secretKey!);

    Fluttertoast.showToast(
      msg: 'Encrypted data: $encryptedData',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 4,
      backgroundColor: Colors.grey[400],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lain Chikita',
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              if (global.username == "NULLUSER")
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Form(
                      child: TextFormField(
                        initialValue: global.username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amber),
                        decoration: const InputDecoration(
                          labelText: 'Nuevo nombre de usuario',
                          labelStyle: TextStyle(color: Colors.white),
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                        ),
                        onFieldSubmitted: (value) =>
                            setState(() => global.username = value),
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
                          global.username,
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
              GestureDetector(
                  child: Center(
                    child: Image.asset(
                      'assets/images/lain_chikita.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  onTap: () {
                    _handleUserChoice(true);
                  }),
              if (showImage)
                Positioned(
                  child: Center(
                    child: Image.asset(
                        'assets/images/accessories/sunglasses.png',
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
                        'Nivel ${global.level}',
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
                          value: global.progress / _maxProgress,
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
      ),
    );
  }
}

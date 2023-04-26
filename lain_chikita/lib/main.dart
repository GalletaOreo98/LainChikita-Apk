import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int _level = 0;
  late int _progress = 0;

  final int _maxProgress = 20;
  final player = AudioPlayer();

  bool showImage = false;

  void _handleUserChoice(bool value) {
    setState(() {
      if(_level >= 100) showImage = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProgress().then((value) => _showEncryptedData());
  }

  String encryptData(String jsonData, String secretKey) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedData, String secretKey) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }

  Future<void> playBtnSound() async {
    await player.play(AssetSource("audio/btn_sound.mp3"));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _level = prefs.getInt('level') ?? 0;
      _progress = prefs.getInt('progress') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', _level);
    await prefs.setInt('progress', _progress);
  }

  void _incrementProgress() {
    setState(() {
      playBtnSound();
      _progress += 1;
      if (_progress >= _maxProgress) {
        _progress = 0;
        _level += 1;
      }
      _saveProgress();
    });
  }

  void _showEncryptedData() {
    final jsonData = json.encode({'level': _level, 'progress': _progress});
    const secretKey =
        'ASDFGHJKLASDFGHJ'; // You should use another key and put it in an external server or something like that.
    final encryptedData = encryptData(jsonData, secretKey);

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
                        'Nivel $_level',
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
                          value: _progress / _maxProgress,
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

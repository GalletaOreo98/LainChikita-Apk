import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int _level = 0;
  late int _progress = 0;
  String _username = "NULLUSER";
  final int _maxProgress = 20;
  final player = AudioPlayer();

  bool showImage = false;

  void _handleUserChoice(bool value) {
    setState(() {
      final jsonData = json.encode({'level': _level, 'progress': _progress, 'username': _username});
      const secretKey =
          'ASDFGHJKLASDFGHJ'; // You should use another key and put it in an external server or something like that.
      final encryptedData = encryptData(jsonData, secretKey);
      decryptData(encryptedData, secretKey);

      if (_level >= 100) showImage = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProgress().then((value) => _showEncryptedData());
  }

  String encryptData(String jsonData, String secretKey) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    final iv2 = encrypt.IV.fromLength(16);
    final jsonDataAndIV =
        json.encode({"data": encrypted.base64, "iv": iv.base64});
    final encrypted2 = encrypter.encrypt(jsonDataAndIV, iv: iv2);
    return encrypted2.base64;
  }

  String decryptData(String encryptedData, String secretKey) {
    final key = encrypt.Key.fromUtf8(secretKey);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final iv2 = encrypt.IV.fromLength(16);
    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    final decrypted = encrypter.decrypt(encrypted, iv: iv2);
    Map<String, dynamic> json = jsonDecode(decrypted);
    final ivD = encrypt.IV.fromBase64(json.values.last);
    final encrypted2 = encrypt.Encrypted.fromBase64(json.values.first);
    final decrypted2 = encrypter.decrypt(encrypted2, iv: ivD);
    return decrypted2;
  }

  Future<void> playBtnSound() async {
    await player.play(AssetSource("audio/btn_sound.mp3"));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _level = prefs.getInt('level') ?? 0;
      _progress = prefs.getInt('progress') ?? 0;
      _username = prefs.getString('username') ?? "NULLUSER";
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('level', _level);
    await prefs.setInt('progress', _progress);
    await prefs.setString('username', _username);
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
    final jsonData = json.encode({'level': _level, 'progress': _progress, 'username': _username});
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
              if (_username == "NULLUSER")
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Form(
                      child: TextFormField(
                        initialValue: _username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amber),
                        decoration: const InputDecoration(
                          labelText: 'Nuevo nombre de usuario',
                          labelStyle: TextStyle(color: Colors.white),
                          floatingLabelAlignment: FloatingLabelAlignment.center,
                        ),
                        onFieldSubmitted: (value) =>
                            setState(() => _username = value),
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
                          _username,
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

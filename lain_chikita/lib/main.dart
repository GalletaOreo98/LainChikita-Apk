import 'package:audioplayers/audioplayers.dart' show AudioPlayer, PlayerMode, ReleaseMode;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemUiMode, SystemChrome, KeyEvent, KeyDownEvent, LogicalKeyboardKey;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show json, jsonDecode;
import 'dart:ui' show PlatformDispatcher;
import 'package:games_services/games_services.dart';


//My imports
import 'classes/app_colors.dart';
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
  static final AudioPlayer loveBtnLowLatencyPlayer = AudioPlayer(playerId: 'loveBtnLowLatencyPlayer');

  String _appBackground = 'background-night';
  /// Para mostrar decoraciones cuando haya fechas especiales
  bool _specialEvent = false;
  final TextEditingController _userNameTEC = TextEditingController(text: 'NULLUSER');

  /// Cuando el usuario actualiza la aplicacion a una nueva versión de [inventoryVersion] se mostrará la animación
  bool wasUpdated = false;

  // Anti-cheat variables
  final List<int> _clickTimes = [];
  int _lastClickTime = 0;
  int _suspiciousClickCount = 0;
  bool _isBlocked = false;
  static const int _maxClicksPerSecond = 12; // Máximo 12 clics por segundo
  static const int _minClickInterval = 80; // Mínimo 80ms entre clics (previene clic burst "picos especificos")
  static const int _maxSuspiciousClicks = 20; // Después de 20 clics sospechosos, bloquear temporalmente
  static const int _blockDurationMs = 30000; // 30 segundos de bloqueo
  static const String _appBackgroundCheater = 'background-cheater';

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
    //Inicializa el reproductor de baja latencia
    await _initLoveBtnLowLatencyPlayer();
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
      if (kDebugMode) debugPrint('Error saving game data to Google Play Games: $e');
    }
  }

  Future<void> _initLoveBtnLowLatencyPlayer() async {
    // Configurar el reproductor de baja latencia
    if (kDebugMode) debugPrint('Configuring loveBtnLowLatencyPlayer...');
    await loveBtnLowLatencyPlayer.setPlayerMode(PlayerMode.lowLatency);
    await loveBtnLowLatencyPlayer.setReleaseMode(ReleaseMode.stop);
    await loveBtnLowLatencyPlayer.setSourceAsset('audio/btn_sound.mp3');
  }

  Future<void> _playLoveBtnSound() async {
    try {
      await loveBtnLowLatencyPlayer.stop();
      await loveBtnLowLatencyPlayer.resume();
    } catch (e) {
      return Future.value();
    }
  }

  Future<void> _playLevelUpSound() async {
    await appAudioPlayer.playSound2('audio/level_up_sound.mp3');
  }

  Future<void> _playUpdatedSound() async {
    if (wasUpdated) await appAudioPlayer.playSound3('audio/updated_sound.mp3');
  }

  Future<void> _playCheaterScreenSound() async {
    await appAudioPlayer.playSound3('audio/cheater_screen_sound.mp3');
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

  /// Muestra la pantalla de bloqueo anti-cheat
  void _showAntiCheatBlock() {
    _playCheaterScreenSound();
    setState(() {
      _appBackground = _appBackgroundCheater;
      _isBlocked = true;
    });
    
    // Auto-desbloquear después del tiempo de penalización
    Future.delayed(const Duration(milliseconds: _blockDurationMs), () {
      if (mounted) {
        setState(() {
          _isBlocked = false;
          _suspiciousClickCount = 0;
        });
      }
    });

    // Restaurar el fondo original después del bloqueo + 16 segundos
    Future.delayed(const Duration(milliseconds: _blockDurationMs + 16000), () {
      if (mounted) {
        setState(() {
          _appBackground = _isMoorning() ? 'background-day' : 'background-night';
        });
      }
    });
    
    unlockAchievementById("CgkI8NLzkooQEAIQBg"); // "God is Watching You" achievement
  }

  /// Verifica si el clic es válido según las reglas anti-cheat
  bool _isValidClick() {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Si está bloqueado temporalmente, rechazar el clic
    if (_isBlocked) {
      return false; // El auto-desbloqueo se maneja en _showAntiCheatBlock
    }

    // Verificar tiempo mínimo entre clics
    if (_lastClickTime > 0 && currentTime - _lastClickTime < _minClickInterval) {
      _suspiciousClickCount++;
      if (_suspiciousClickCount >= _maxSuspiciousClicks) {
        _showAntiCheatBlock();
        if (kDebugMode) debugPrint('Usuario bloqueado temporalmente por clics muy rápidos');
      }
      return false;
    }

    // Mantener historial de clics del último segundo
    _clickTimes.removeWhere((time) => currentTime - time > 1000);
    
    // Verificar límite de clics por segundo
    if (_clickTimes.length >= _maxClicksPerSecond) {
      _suspiciousClickCount++;
      if (_suspiciousClickCount >= _maxSuspiciousClicks) {
        _showAntiCheatBlock();
        if (kDebugMode) debugPrint('Usuario bloqueado temporalmente por demasiados clics por segundo');
      }
      return false;
    }

    // Detectar patrones de autoclicker (intervalos muy regulares)
    if (_clickTimes.length >= 5) {
      List<int> intervals = [];
      for (int i = 1; i < _clickTimes.length; i++) {
        intervals.add(_clickTimes[i] - _clickTimes[i - 1]);
      }
      
      // Si todos los intervalos son muy similares (diferencia < 10ms), es sospechoso
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final maxDeviation = intervals.map((interval) => (interval - avgInterval).abs()).reduce((a, b) => a > b ? a : b);
      
      if (maxDeviation < 10 && avgInterval < 200) {
        _suspiciousClickCount += 2; // Penalizar más los patrones regulares
        if (_suspiciousClickCount >= _maxSuspiciousClicks) {
          _showAntiCheatBlock();
          if (kDebugMode) debugPrint('Usuario bloqueado temporalmente por patrón de autoclicker detectado');
        }
        return false;
      }
    }

    // Si el clic es válido, actualizar datos
    _clickTimes.add(currentTime);
    _lastClickTime = currentTime;
    
    // Reducir contador de clics sospechosos si el comportamiento es normal
    if (_suspiciousClickCount > 0) {
      _suspiciousClickCount--;
    }
    
    return true;
  }

  void _incrementProgress() {
    // Verificar anti-cheat antes de procesar el clic
    if (!_isValidClick()) {
      if (kDebugMode) debugPrint('Clic inválido detectado y bloqueado por el sistema anti-cheat $_suspiciousClickCount');
      //return; // Return si quieres rechazar el clic si no es válido
    }
    
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
                            style: const TextStyle(color: AppColors.nameLabel, fontSize: 34.0),
                            decoration: InputDecoration(
                                suffixIcon: IconButton(
                                    onPressed: () => setState(() {
                                          userName = _userNameTEC.text;
                                          _saveProgress();
                                          writeAThankUTxt();
                                          FocusManager.instance.primaryFocus?.unfocus();
                                        }),
                                    icon: const Icon(Icons.done),
                                    color: AppColors.focusItem),
                                labelText: languageDataManager.getLabel('new-user-name'),
                                labelStyle: const TextStyle(color: AppColors.primaryText, fontSize: 34.0),
                                floatingLabelAlignment: FloatingLabelAlignment.center,
                                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.focusItem)),
                                enabledBorder:
                                    const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.userInputText))),
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
                                  style: const TextStyle(
                                    fontSize: 48.0,
                                    color: AppColors.nameLabel,
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
                                style: const TextStyle(
                                  fontSize: 40.0,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              if (userName != "NULLUSER") ...[
                                const SizedBox(height: 8.0),
                                SizedBox(
                                  height: 16.0,
                                  width: 250.0,
                                  child: LinearProgressIndicator(
                                    value: progress / _maxProgress,
                                    backgroundColor: AppColors.loveBarOpposite,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppColors.loveBar,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32.0),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InventoryScreen(callback: _updateAccessory, pageController: _pageController),
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
              fit: BoxFit.cover,
            ),
          ),
          // Pantalla de bloqueo anti-cheat (debe ir al final para estar encima de todo)
          if (_isBlocked)
          Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/$_appBackgroundCheater.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "God is watching you \n But you don't need to be afraid",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],)));
  }
}
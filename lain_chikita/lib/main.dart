import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;

import 'app.dart';
import 'services/achievements_service.dart';
import 'services/audio_service.dart';
import 'services/translations.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final game = GameState();
  var catalogWasUpdated = false;
  try {
    // Las traducciones van primero porque game.load() escribe el THANKS.txt con un texto traducido
    await Translations.instance.load(Translations.resolveLanguage(PlatformDispatcher.instance.locale.languageCode));
    // game.load() hace la migración de las preferencias legacy, debe ir antes de leer cualquier otra preferencia
    catalogWasUpdated = await game.load();
    await AchievementsService.instance.restoreLocalProgress();
    await AudioService.instance.init();
  } catch (e) {
    // Aunque falle algo, la app debe abrir (con valores por defecto)
    if (kDebugMode) debugPrint('Error during startup: $e');
  }

  runApp(LainChikitaApp(game: game, catalogWasUpdated: catalogWasUpdated));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

import 'dart:convert' show json;

import 'package:flutter/services.dart' show rootBundle;

import '../core/app_assets.dart';

/// Textos de la UI y nombres de accesorios según el idioma (assets/language/*.json).
/// Hay que llamar a [load] antes de usarlos.
class Translations {
  Translations._();
  static final instance = Translations._();

  static const supportedLanguages = ['en', 'es'];
  static const defaultLanguage = 'en';

  Map<String, String> _labels = {};
  Map<String, String> _accessoryNames = {};

  /// Elige el idioma soportado a partir del código de idioma del dispositivo
  static String resolveLanguage(String deviceLanguageCode) {
    final code = deviceLanguageCode.toLowerCase();
    return supportedLanguages.firstWhere(code.contains, orElse: () => defaultLanguage);
  }

  Future<void> load(String languageCode) async {
    _labels = await _loadJson(AppLanguageFiles.labels(languageCode));
    _accessoryNames = await _loadJson(AppLanguageFiles.accessoryNames(languageCode));
  }

  /// Si no existe la llave devuelve la llave tal cual
  String label(String key) => _labels[key] ?? key;

  String accessoryName(String accessoryId) => _accessoryNames[accessoryId] ?? accessoryId;

  static Future<Map<String, String>> _loadJson(String path) async {
    final content = await rootBundle.loadString(path);
    return Map<String, String>.from(json.decode(content) as Map);
  }
}

/// Atajo para los textos de la UI: `tr('level')`
String tr(String key) => Translations.instance.label(key);

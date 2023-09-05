import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert' show json;

/// Clase para administrar el lenguaje de los textos 
/// segun el codigo de leguaje del dispositivo
/// 
/// **Importante hacer load de las variables antes de usar estas**
class LanguageDataManager {
  Map<String, String> _accessoryNames = {};
  Map<String, String> _labels = {};

  /// Hace la inicializacion (load) de los **nombres** de los accesorios (items del inventario del jugador) 
  /// a la variable [_accessoryNames] segun el [languageCode] que demos
  Future<void> loadAccessoryNames(String languageCode) async {
    final accessoryNamesString = await rootBundle.loadString('assets/language/items_name_$languageCode.json');
    _accessoryNames = Map<String, String>.from(json.decode(accessoryNamesString));
  }

  /// Hace la inicializacion (load) de los **nombres** de las etiquetas (textos que utiliza la UI) 
  /// a la variable [_labels] segun el [languageCode] que demos
  Future<void> loadLabels(String languageCode) async {
    final labelsString = await rootBundle.loadString('assets/language/labels_$languageCode.json');
    _labels = Map<String, String>.from(json.decode(labelsString));
  }

  String getAccessoryName(String itemName) {
    return _accessoryNames[itemName] ?? itemName;
  }

  String getLabel(String labelName) {
    return _labels[labelName] ?? labelName;
  }
}
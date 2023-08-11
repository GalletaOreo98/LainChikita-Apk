import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class DataManager {
  Map<String, String> _showedNames = {};

  Future<void> loadShowedNames(String languageCode) async {
    final showNamesString = await rootBundle.loadString('assets/language/items_name_$languageCode.json');
    _showedNames = Map<String, String>.from(json.decode(showNamesString));
  }

  String getShowedName(String itemName) {
    return _showedNames[itemName] ?? itemName;
  }
}
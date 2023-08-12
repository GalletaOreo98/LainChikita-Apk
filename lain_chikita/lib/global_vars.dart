import 'classes/data_manager.dart';
//User vars
int level = 0;
int progress = 0;
String username = "NULLUSER";
String accessoryName = "null";
String userUuid = "";
//Variables sin backup
int coins = 2;

List<Map<String, dynamic>> inventory = [
  {'name': 'null', 'by': 'NULLUSER'},
  {'name': 'sunglasses', 'by': 'oreo_dev'},
];

List<Map<String, dynamic>> unlockedInventory = [
  {'name': 'sunglasses_circle', 'by': 'Navi'},
  {'name': 'sports_glasses', 'by': 'oreo_dev'},
  {'name': 'christmas_cane', 'by': 'oreo_dev'},
  {'name': 'pacman_mob', 'by': 'oreo_dev'},
];

//Preferencias
String language = 'en';
DataManager dataManager = DataManager();
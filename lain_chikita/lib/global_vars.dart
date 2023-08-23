import 'classes/app_colors.dart';
import 'classes/audio_player.dart';
import 'classes/data_manager.dart';

//User vars
int level = 0;
int progress = 0;
String username = "NULLUSER";
String accessoryName = "null";
String userUuid = "";

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

//Variables sin backup
int coins = 2;

//Preferencias y Configuraciones en general
String language = 'en';
LanguageDataManager languageDataManager = LanguageDataManager();
AppAudioPlayer appAudioPlayer = AppAudioPlayer();
AppColors appColors = AppColors();
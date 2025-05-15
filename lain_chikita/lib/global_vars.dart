import 'dart:io' show Platform, Directory;

//My imports
import 'classes/app_colors.dart';
import 'classes/audio_player.dart';
import 'classes/language_data_manager.dart';

//User vars
int level = 0;
int progress = 0;
String userName = "NULLUSER";
String accessoryName = "null";
String userUuid = "";
String userIv = "";
String userSecretKey = "";

/*
Cada vez que se haga un add, delete o update a unlockedInventory se debe aumentar la version de inventoryVersion
(Cuando desimos add, delete o update a unlockedInventory nos referimos a nivel de aplicacion,
como cuando se agrega una nueva skin a la app o se quita u modifica una; también cuando modificas 
algo de los inventarios en general)
*/
int inventoryVersion = 15;

List<Map<String, dynamic>> inventory = [
  {'name': 'null'},
  {'name': 'sunglasses'},
];

List<Map<String, dynamic>> unlockedInventory = [
  {'name': 'sunglasses_circle'},
  {'name': 'sports_glasses'},
  {'name': 'christmas_cane'},
  {'name': 'pacman_mob'},
  {'name': 'vinca_flower'},
  {'name': 'pickaxe_minecraft'},
  {'name': 'pumpkin'},
  {'name': 'rei_chikita'},
  {'name': 'sus'},
  {'name': 'pomni_chikita'},
  {'name': 'nerd_glasses'},
  {'name': 'capybara'},
  {'name': 'omori_cat'},
  {'name': 'c_programming_book'},
  {'name': 'linux_penguin'},
  {'name': 'monster_energy_beverage'},
  {'name': 'fnaf_bonnie'},
  //ADD NEW SKINS HERE
  // (recuerda que si agregas una skin nueva debes agregarla a la lista de lenguajes 
  // en assets/languages/items_name_<en/es>.json)
];

//User vars (sin backup)
int coins = 0;

//String accessoryModPath = "";

//Preferencias y Configuraciones en general
String accessoryPath = '';
String language = 'en';
LanguageDataManager languageDataManager = LanguageDataManager();
AppAudioPlayer appAudioPlayer = AppAudioPlayer();
AppColors appColors = AppColors();
String platformName = _getPlatformName();
Directory appDirectoryStorage = Directory.current; //Debes ser inicializado despues

//Funciones privadas
String _getPlatformName() {
  if (Platform.isAndroid) return "android";
  if (Platform.isIOS) return "ios";
  if (Platform.isMacOS) return "macos";
  if (Platform.isWindows) return "windows";
  if (Platform.isLinux) return "linux";
  return "unknown";
}

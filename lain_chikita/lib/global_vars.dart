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
int inventoryVersion = 11;

List<Map<String, dynamic>> inventory = [
  {'name': 'null', 'by': 'NULLUSER'},
  {'name': 'sunglasses', 'by': 'oreo_dev'},
];

List<Map<String, dynamic>> unlockedInventory = [
  {'name': 'sunglasses_circle', 'by': 'Navi'},
  {'name': 'sports_glasses', 'by': 'oreo_dev'},
  {'name': 'christmas_cane', 'by': 'oreo_dev'},
  {'name': 'pacman_mob', 'by': 'oreo_dev'},
  {'name': 'vinca_flower', 'by': 'oreo_dev'},
  {'name': 'pickaxe_minecraft', 'by': 'oreo_dev'},
  {'name': 'pumpkin', 'by': 'oreo_dev'},
  {'name': 'rei_chikita', 'by': 'oreo_dev'},
  {'name': 'sus', 'by': 'Navi'},
  {'name': 'pomni_chikita', 'by': 'oreo_dev'},
  {'name': 'nerd_glasses', 'by': 'oreo_dev'},
  {'name': 'capybara', 'by': 'Navi'},
  {'name': 'omori_cat', 'by': 'Navi'},
  {'name': 'c_programming_book', 'by': 'Navi'},
  {'name': 'linux_penguin', 'by': 'Navi'},
  {'name': 'monster_energy_beverage', 'by': 'Navi'},
  {'name': 'fnaf_bonnie', 'by': 'Navi'},
  //ADD NEW SKINS HERE
];

//User vars (sin backup)
int coins = 0;

//Mods vars
bool isActiveMod = false;
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

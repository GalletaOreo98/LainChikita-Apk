import 'dart:io' show Platform;

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
  {'name': 'vinca_flower', 'by': 'oreo_dev'},
];

//Variables sin backup
int coins = 2;

//Preferencias y Configuraciones en general
String language = 'en';
LanguageDataManager languageDataManager = LanguageDataManager();
AppAudioPlayer appAudioPlayer = AppAudioPlayer();
AppColors appColors = AppColors();
String platformName = _getPlatformName();

//Funciones privadas
String _getPlatformName(){
  if (Platform.isAndroid) return "android";
  if (Platform.isIOS) return "ios";
  if (Platform.isMacOS) return "macos"; 
  if (Platform.isWindows) return "windows";
  if (Platform.isLinux) return "linux";
  return "unknown";
}
/// Rutas de imágenes (relativas a la raíz del proyecto, para Image.asset / AssetImage)
abstract final class AppImages {
  static const lainChikita = 'assets/images/lain_chikita.png';
  static const backgroundDay = 'assets/images/background-day.png';
  static const backgroundNight = 'assets/images/background-night.png';
  static const backgroundCheater = 'assets/images/background-cheater.png';
  static const coin = 'assets/images/coin.png';
  static const updated = 'assets/images/updated.gif';
  static const working = 'assets/images/working.gif';
  static const snowing = 'assets/images/snowing.gif';

  static String accessory(String accessoryId) => 'assets/images/accessories/$accessoryId.png';
}

/// Rutas de audio (relativas a assets/, que es como las espera AssetSource de audioplayers)
abstract final class AppSounds {
  static const loveButton = 'audio/btn_sound.mp3';
  static const levelUp = 'audio/level_up_sound.mp3';
  static const updated = 'audio/updated_sound.mp3';
  static const cheaterScreen = 'audio/cheater_screen_sound.mp3';
  static const informativePopup = 'audio/informative_popup_sound.mp3';
  static const acceptPopup = 'audio/accept_popup_sound.mp3';
  static const cancel = 'audio/cancel_sound.mp3';
  static const accessoryBought = 'audio/accessory_bought_sound.mp3';
  static const redeemCodeSuccess = 'audio/redeem_code_success_sound.mp3';
  static const selectAccessory = 'audio/select_accessory_sound.mp3';
  static const nyanCatMusic = 'audio/nyan_cat_music.mp3';
}

/// Rutas de los JSON de idiomas
abstract final class AppLanguageFiles {
  static String labels(String languageCode) => 'assets/language/labels_$languageCode.json';
  static String accessoryNames(String languageCode) => 'assets/language/items_name_$languageCode.json';
}

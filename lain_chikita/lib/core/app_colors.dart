import 'dart:ui' show Color;

abstract final class AppColors {
  static const background = Color.fromARGB(255, 14, 14, 42);
  static const loveBar = Color.fromARGB(255, 248, 187, 208);
  static const loveBarOpposite = Color.fromARGB(255, 255, 255, 255);
  static const primaryText = Color.fromARGB(255, 255, 255, 255);
  static const disabledText = Color.fromARGB(255, 170, 170, 170);
  static const nameLabel = Color.fromARGB(255, 255, 193, 7);
  static const userInputText = Color.fromARGB(255, 166, 217, 238);
  static const informativeText = Color.fromARGB(179, 255, 255, 255);
  static const errorText = Color.fromARGB(255, 255, 158, 158);
  static const primaryBtn = Color.fromARGB(255, 52, 58, 116);
  static const secondaryBtn = Color.fromARGB(255, 52, 58, 116);
  static const focusItem = Color.fromARGB(255, 115, 50, 167);
  static const inventoryItem = Color.fromARGB(255, 45, 16, 90);
  static const inventoryItemSelected = Color.fromARGB(255, 20, 6, 43);

  // Botones de la pantalla de datos del juego
  static const signInBtn = Color.fromARGB(255, 24, 110, 3);
  static const signInBtnDisabled = Color.fromARGB(255, 133, 133, 133);
  static const achievementsBtn = Color.fromARGB(255, 207, 127, 23);
  static const leaderboardsBtn = Color.fromARGB(255, 156, 39, 176);
  static const saveProgressBtn = Color.fromARGB(255, 32, 105, 189);
  static const loadProgressBtn = Color.fromARGB(255, 78, 24, 177);

  // Rareza de los logros
  static const rarityCommon = Color.fromARGB(255, 158, 158, 158);
  static const rarityUncommon = Color.fromARGB(255, 102, 187, 106);
  static const rarityRare = Color.fromARGB(255, 91, 139, 212);
  static const rarityEpic = Color.fromARGB(255, 155, 89, 182);
  static const rarityLegendary = Color.fromARGB(255, 230, 126, 34);
}

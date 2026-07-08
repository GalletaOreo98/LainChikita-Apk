import 'dart:math' show Random;

//My imports
import '../global_vars.dart' as global_vars;

/// Crea un numero Random secureRandom
///
/// maxValue es un numero >= 0
///
/// Devuelve un numero >= 0 y < maxValue.
int generateSecureRandom(int maxValue) {
  final secureRandom = Random.secure();
  return secureRandom.nextInt(maxValue);
}


/// Retorna empty (String vacio) si no se puede proceder,
/// en otro caso agrega el item elegido al inventario y retorna true
/// 
/// Gasta el coin cuando se realiza exitosamente
bool buyAccessory() {
  if (global_vars.coins <= 0) return false;
  if (global_vars.unlockedInventory.isEmpty) return false;
  global_vars.coins--;
  int random = generateSecureRandom(global_vars.unlockedInventory.length);
  global_vars.inventory.add(global_vars.unlockedInventory[random]);
  global_vars.unlockedInventory.removeAt(random);
  return true;
}

bool unlockRandomAccessory() {
  if (global_vars.unlockedInventory.isEmpty) return false;
  int random = generateSecureRandom(global_vars.unlockedInventory.length);
  global_vars.inventory.add(global_vars.unlockedInventory[random]);
  global_vars.unlockedInventory.removeAt(random);
  return true;
}

bool unlockAccessoryByName(String accessoryName) {
  for (var accessory in global_vars.unlockedInventory) {
    if (accessory['name'] == accessoryName) {
      global_vars.inventory.add(accessory);
      global_vars.unlockedInventory.remove(accessory);
      return true;
    }
  }
  return false;
}
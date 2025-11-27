import 'dart:math' show Random;

//My imports
import '../global_vars.dart' as gv;

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
  if (gv.coins <= 0) return false;
  if (gv.unlockedInventory.isEmpty) return false;
  gv.coins--;
  int random = generateSecureRandom(gv.unlockedInventory.length);
  gv.inventory.add(gv.unlockedInventory[random]);
  gv.unlockedInventory.removeAt(random);
  return true;
}

bool unlockRandomAccessory() {
  if (gv.unlockedInventory.isEmpty) return false;
  int random = generateSecureRandom(gv.unlockedInventory.length);
  gv.inventory.add(gv.unlockedInventory[random]);
  gv.unlockedInventory.removeAt(random);
  return true;
}

bool unlockAccessoryByName(String accessoryName) {
  for (var accessory in gv.unlockedInventory) {
    if (accessory['name'] == accessoryName) {
      gv.inventory.add(accessory);
      gv.unlockedInventory.remove(accessory);
      return true;
    }
  }
  return false;
}
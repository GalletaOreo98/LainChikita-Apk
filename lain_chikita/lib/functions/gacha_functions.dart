import 'dart:math';
import '../global_vars.dart';

/// Crea un numero Random secureRandom
/// 
/// maxValue es un numero >= 0
/// 
/// Devuelve un numero >= 0 y < maxValue.
int generateSecureRandom(int maxValue) {
    final secureRandom = Random.secure();
    return secureRandom.nextInt(maxValue);
}

void addItemToInventory(dynamic item){
  inventory.add(item);
}

bool buyTicket(){
  if (coins <= 0) return false;
  if (unlockedInventory.isEmpty) return false;
  coins --;
  int random = generateSecureRandom(unlockedInventory.length);
  inventory.add(unlockedInventory[random]);
  unlockedInventory.removeAt(random);
  return true;
}
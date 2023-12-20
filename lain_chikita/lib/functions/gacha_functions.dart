import 'dart:math' show Random;
import 'dart:convert' show json;

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
bool buyTicket() {
  if (gv.coins <= 0) return false;
  if (gv.unlockedInventory.isEmpty) return false;
  gv.coins--;
  int random = generateSecureRandom(gv.unlockedInventory.length);
  gv.inventory.add(gv.unlockedInventory[random]);
  gv.unlockedInventory.removeAt(random);
  return true;
}

/// Retorna empty (String vacio) si no se puede proceder,
/// en otro caso retorna el item elegido aleatoriamente, 
/// ejemplo: {"name":"item_name", "by": "This_is_just_an_example"}
/// 
/// El intem esta json.encode por lo que se puede json.decode para usar como Map<String, String>
/// 
/// Gasta el coin cuando se realiza exitosamente
String buyTicketFor(List<Map<String, dynamic>> unlockedInventory){
  if (gv.coins <= 0) return '';
  if (unlockedInventory.isEmpty) return '';
  gv.coins--;
  int random = generateSecureRandom(unlockedInventory.length);
  Map<String, dynamic> item = unlockedInventory[random];
  String jsonItem = json.encode(item);
  return jsonItem;
}

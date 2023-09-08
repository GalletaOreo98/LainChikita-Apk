List<Map<String, dynamic>> applyInventoryVerionUpdate(List<Map<String, dynamic>> myUnlockedInventary,
    List<Map<String, dynamic>> appUnlokedInventory, List<Map<String, dynamic>> inventory) {

  for (int i = 0; i < inventory.length; i++) {
    appUnlokedInventory.removeWhere((element) {
      return element['name'] == inventory[i]['name'];
    });
  }
  for (int i = 0; i < myUnlockedInventary.length; i++) {
    appUnlokedInventory.removeWhere((element) {
      return element['name'] == myUnlockedInventary[i]['name'];
    });
  }
  if(appUnlokedInventory.isNotEmpty) myUnlockedInventary.addAll(appUnlokedInventory);
  return myUnlockedInventary;
}

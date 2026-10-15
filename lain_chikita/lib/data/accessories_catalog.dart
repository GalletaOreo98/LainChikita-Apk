/// Id del "accesorio vacío" (assets/images/accessories/null.png). Es un id real, no un null de Dart.
const String noAccessoryId = 'null';

/// El Nyan Cat tiene música propia al elegirlo
const String nyanCatAccessoryId = 'nyan_cat';

/// Versión del catálogo de accesorios.
///
/// **Cada vez que agregues, quites o cambies un accesorio del catálogo hay que subir este número.**
/// Al iniciar, si la versión guardada del usuario es distinta, se le agregan los accesorios nuevos
/// a su lista de bloqueados (ver [mergeNewCatalogAccessories]) y se muestra la animación de "actualizado".
const int inventoryVersion = 20;

/// Accesorios con los que empieza todo usuario nuevo
const List<String> starterAccessories = [
  noAccessoryId,
  'sunglasses',
];

/// Accesorios que se pueden desbloquear (gacha o códigos).
///
/// Para agregar uno nuevo:
/// 1. Agrégalo aquí y sube [inventoryVersion]
/// 2. Agrega su imagen en `assets/images/accessories/<id>.png`
/// 3. Agrega su nombre en `assets/language/items_name_en.json` e `items_name_es.json`
const List<String> unlockableAccessories = [
  'sunglasses_circle',
  'sports_glasses',
  'christmas_cane',
  'pacman_mob',
  'vinca_flower',
  'pickaxe_minecraft',
  'pumpkin',
  'rei_chikita',
  'sus',
  'pomni_chikita',
  'nerd_glasses',
  'capybara',
  'omori_cat',
  'c_programming_book',
  'linux_penguin',
  'monster_energy_beverage',
  'fnaf_bonnie',
  'frog',
  'hornet',
  nyanCatAccessoryId,
];

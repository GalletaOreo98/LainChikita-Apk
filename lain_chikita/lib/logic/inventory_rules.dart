import 'dart:convert' show json;

/// Agrega a [locked] los accesorios del [catalog] que el usuario todavía no conoce
/// (los que no están ni en [owned] ni en [locked]). Se usa cuando cambia `inventoryVersion`.
List<String> mergeNewCatalogAccessories({
  required List<String> catalog,
  required List<String> owned,
  required List<String> locked,
}) {
  final newAccessories = catalog.where((id) => !owned.contains(id) && !locked.contains(id));
  return [...locked, ...newAccessories];
}

/// Los inventarios se guardan como JSON `[{"name": "<id>"}, ...]` (formato histórico de la app,
/// tanto en las preferencias como en el guardado en la nube). No cambiar el formato.
String encodeAccessoryList(List<String> accessoryIds) {
  return json.encode([
    for (final id in accessoryIds) {'name': id},
  ]);
}

/// Inverso de [encodeAccessoryList]. Ignora entradas sin `name`.
List<String> decodeAccessoryList(String encoded) {
  final decoded = json.decode(encoded) as List<dynamic>;
  return [
    for (final item in decoded)
      if (item is Map && item['name'] is String) item['name'] as String,
  ];
}

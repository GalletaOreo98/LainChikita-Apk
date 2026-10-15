import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

const SharedPreferencesOptions _prefsOptions = SharedPreferencesOptions();

/// Llave que marca que los datos del SharedPreferences legacy ya fueron migrados.
/// **No cambiar ni borrar**, si no la migración se volvería a ejecutar y sobrescribiría datos nuevos.
const String _legacyMigrationCompletedKey = 'legacyPrefsMigrationCompleted';

/// Almacenamiento de preferencias de la app (sin cache, cada llamada va directo a la plataforma).
/// En Android usa DataStore.
final SharedPreferencesAsync appPrefs = SharedPreferencesAsync(options: _prefsOptions);

/// Migra los datos guardados con el SharedPreferences legacy (versiones anteriores de la app)
/// a [appPrefs]. Solo hace algo la primera vez; debe llamarse antes de leer cualquier preferencia.
Future<void> migrateLegacyPrefsIfNecessary() async {
  try {
    if (await appPrefs.containsKey(_legacyMigrationCompletedKey)) return;
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
      sharedPreferencesAsyncOptions: _prefsOptions,
      migrationCompletedKey: _legacyMigrationCompletedKey,
    );
    if (kDebugMode) debugPrint('Legacy SharedPreferences migrated to SharedPreferencesAsync');
  } catch (e) {
    // Si falla, la llave de migración no se guarda y se reintenta en el siguiente inicio
    if (kDebugMode) debugPrint('Error migrating legacy SharedPreferences: $e');
  }
}

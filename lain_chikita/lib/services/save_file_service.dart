import 'dart:io' show File, Platform;

import 'package:file_selector/file_selector.dart';

import '../models/save_file_data.dart';
import '../private_keys.dart';

/// Respaldo del juego en un archivo .save que el usuario guarda donde quiera (otra carpeta, una USB...)
/// para llevarlo a otro equipo. Solo en Linux y Windows, que no tienen Google Play Games.
class SaveFileService {
  SaveFileService._();
  static final instance = SaveFileService._();

  static const String _extension = 'save';
  static const String _suggestedFileName = 'lain_chikita.$_extension';
  static const _typeGroup = XTypeGroup(label: 'Lain Chikita save', extensions: [_extension]);

  bool get isAvailable => Platform.isLinux || Platform.isWindows;

  /// Abre el diálogo de "Guardar como". Devuelve null si el usuario canceló
  Future<String?> pickSaveLocation() async {
    final location = await getSaveLocation(acceptedTypeGroups: [_typeGroup], suggestedName: _suggestedFileName);
    if (location == null) return null;
    // El diálogo de GTK no agrega la extensión solo
    final path = location.path;
    return path.toLowerCase().endsWith('.$_extension') ? path : '$path.$_extension';
  }

  Future<void> write(String path, SaveFileData data) async {
    await File(path).writeAsString(data.encrypt(SECRET_KEY), flush: true);
  }

  /// Abre el diálogo para elegir un .save y lo lee. Devuelve null si el usuario canceló.
  /// Lanza [FormatException] si el archivo no es un respaldo válido.
  Future<SaveFileData?> pickAndRead() async {
    final file = await openFile(acceptedTypeGroups: [_typeGroup]);
    if (file == null) return null;
    return SaveFileData.decrypt(await file.readAsString(), SECRET_KEY);
  }
}

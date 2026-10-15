import 'dart:convert' show json;

import '../services/crypto.dart';
import 'game_save_data.dart';

/// Contenido de un archivo .save (respaldo manual para plataformas sin Google Play Games).
///
/// Lleva lo mismo que el guardado en la nube ([GameSaveData]) más el progreso de los logros
/// locales. Las monedas no van, igual que en la nube: al cargar un respaldo se pierden.
///
/// En disco va encriptado con AES (SECRET_KEY) para que no se pueda editar a mano.
class SaveFileData {
  const SaveFileData({required this.game, required this.localAchievements, required this.savedAt});

  /// Identifica que el archivo es de Lain Chikita
  static const String formatId = 'lain_chikita_save';

  /// Subir si cambia la estructura del archivo (y mantener la lectura de versiones anteriores)
  static const int formatVersion = 1;

  final GameSaveData game;

  /// Progreso exportado del motor de logros local (null si no hay)
  final Map<String, dynamic>? localAchievements;
  final DateTime savedAt;

  String encrypt(String secretKey) {
    return encryptData(
      json.encode({
        'format': formatId,
        'formatVersion': formatVersion,
        'savedAt': savedAt.toIso8601String(),
        'game': game.toJson(),
        'localAchievements': localAchievements,
      }),
      secretKey,
    );
  }

  /// Lanza [FormatException] si el archivo no es un respaldo válido (dañado, editado, de otra app
  /// o de una versión más nueva de la app)
  factory SaveFileData.decrypt(String encrypted, String secretKey) {
    final Map<String, dynamic> data;
    try {
      data = json.decode(decryptData(encrypted.trim(), secretKey)) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('Save file could not be decrypted');
    }

    if (data['format'] != formatId) throw const FormatException('Not a Lain Chikita save file');
    final version = data['formatVersion'];
    if (version is! int || version > formatVersion) {
      throw FormatException('Unsupported save file version: $version');
    }

    try {
      return SaveFileData(
        game: GameSaveData.fromJson(data['game'] as Map<String, dynamic>),
        localAchievements: data['localAchievements'] as Map<String, dynamic>?,
        savedAt: DateTime.parse(data['savedAt'] as String),
      );
    } catch (_) {
      throw const FormatException('Save file is incomplete');
    }
  }
}

import 'package:audioplayers/audioplayers.dart' show AssetSource, AudioPlayer, PlayerMode, ReleaseMode;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import '../core/app_assets.dart';

/// Todos los sonidos de la app.
///
/// Hay 3 reproductores genéricos (canales) para que distintos sonidos puedan sonar a la vez;
/// un sonido nuevo en el mismo canal reemplaza al que estaba sonando. El botón de amor tiene
/// su propio reproductor de baja latencia porque se spamea.
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioPlayer _channel1 = AudioPlayer(playerId: 'myGlobalPlayer');
  final AudioPlayer _channel2 = AudioPlayer(playerId: 'myGlobalPlayer2');
  final AudioPlayer _channel3 = AudioPlayer(playerId: 'myGlobalPlayer3');
  final AudioPlayer _loveButtonPlayer = AudioPlayer(playerId: 'loveBtnLowLatencyPlayer');

  /// Prepara el reproductor de baja latencia del botón de amor
  Future<void> init() async {
    try {
      await _loveButtonPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _loveButtonPlayer.setReleaseMode(ReleaseMode.stop);
      await _loveButtonPlayer.setSourceAsset(AppSounds.loveButton);
    } catch (e) {
      if (kDebugMode) debugPrint('Error configuring love button player: $e');
    }
  }

  Future<void> playLoveButton() async {
    try {
      await _loveButtonPlayer.stop();
      await _loveButtonPlayer.resume();
    } catch (_) {
      // Ver comentario en _play
    }
  }

  Future<void> playInformativePopup() => _play(_channel1, AppSounds.informativePopup);
  Future<void> playAccessoryBought() => _play(_channel1, AppSounds.accessoryBought);

  Future<void> playLevelUp() => _play(_channel2, AppSounds.levelUp);
  Future<void> playAcceptPopup() => _play(_channel2, AppSounds.acceptPopup);
  Future<void> playRedeemCodeSuccess() => _play(_channel2, AppSounds.redeemCodeSuccess);

  Future<void> playUpdated() => _play(_channel3, AppSounds.updated);
  Future<void> playCheaterScreen() => _play(_channel3, AppSounds.cheaterScreen);
  Future<void> playCancel() => _play(_channel3, AppSounds.cancel);

  /// Sonido al elegir accesorio. El Nyan Cat además pone su música
  Future<void> playSelectAccessory({required bool isNyanCat}) async {
    await _play(_channel3, AppSounds.selectAccessory);
    if (isNyanCat) await _play(_channel3, AppSounds.nyanCatMusic);
  }

  Future<void> _play(AudioPlayer player, String source) async {
    try {
      await player.play(AssetSource(source));
    } catch (_) {
      // Pueden saltar errores al spamear sonidos (sobre todo en Linux); no son críticos
    }
  }
}

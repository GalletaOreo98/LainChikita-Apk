import 'package:audioplayers/audioplayers.dart' show AudioPlayer, AssetSource;

class AppAudioPlayer {
  AudioPlayer player = AudioPlayer(playerId: 'myGlobalPlayer');

  Future<void> playSound(String source) {
    return player.play(AssetSource(source));
  }

}
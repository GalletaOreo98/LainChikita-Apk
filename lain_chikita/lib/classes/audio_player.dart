import 'package:audioplayers/audioplayers.dart' show AudioPlayer, AssetSource;

class AppAudioPlayer {
  AudioPlayer player = AudioPlayer(playerId: 'myGlobalPlayer');
  AudioPlayer player2 = AudioPlayer(playerId: 'myGlobalPlayer2');

  Future<void> playSound(String source) {
    return player.play(AssetSource(source));
  }

  Future<void> playSound2(String source) {
    return player2.play(AssetSource(source));
  }

}
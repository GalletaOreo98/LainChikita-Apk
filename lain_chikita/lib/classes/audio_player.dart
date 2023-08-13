import 'package:audioplayers/audioplayers.dart';

class AppAudioPlayer {
  AudioPlayer player = AudioPlayer(playerId: 'myGlobalPlayer');

  Future<void> playSound(String source) {
    return player.play(AssetSource(source));
  }

}
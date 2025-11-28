import 'package:audioplayers/audioplayers.dart' show AudioPlayer, AssetSource;

class AppAudioPlayer {
  AudioPlayer player = AudioPlayer(playerId: 'myGlobalPlayer');
  AudioPlayer player2 = AudioPlayer(playerId: 'myGlobalPlayer2');
  AudioPlayer player3 = AudioPlayer(playerId: 'myGlobalPlayer3');

  // Surround with try-catch to handle potential errors que no sé cómo surgen, solo sé que es al spamear y en linux mayormente y vulkan xd

  Future<void> playSound(String source) {
    try {
      return player.play(AssetSource(source));
    } catch (e) {
      return Future.value();
    }
  }

  Future<void> playSound2(String source) {
    try {
      return player2.play(AssetSource(source));
    } catch (e) {
      return Future.value();
    }
  }

  Future<void> playSound3(String source) {
    try {
      return player3.play(AssetSource(source));
    } catch (e) {
      return Future.value();
    }
  }
}
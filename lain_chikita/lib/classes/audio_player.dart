import 'package:audioplayers/audioplayers.dart' show AssetSource, AudioPlayer, ReleaseMode;

class AppAudioPlayer {
  // Reproductores de audio genericos globales para la aplicación
  final AudioPlayer player1 = AudioPlayer(playerId: 'myGlobalPlayer');
  final AudioPlayer player2 = AudioPlayer(playerId: 'myGlobalPlayer2');
  final AudioPlayer player3 = AudioPlayer(playerId: 'myGlobalPlayer3');

  // Reproductor de audio para sonidos que necesitan repetirse N veces
  final AudioPlayer playerNLoops = AudioPlayer(playerId: 'myGlobalPlayerNLoops');

  // Surround with try-catch to handle potential errors que no sé cómo surgen, solo sé que es al spamear y en linux mayormente y vulkan xd
  
  // Al hacer player1.play(AssetSource(source)), cada vez que se llama al playSound1, obligamos a que
  // ese player1 termine de reproducir el sonido que esta reproduciendo actualmente (si es que hay alguno)
  // antes de que se le pueda asignar un nuevo sonido a reproducir. Es decir, lo bloquea con su reproduccion actual
  // y no acepta nuevos sonidos (llamadas a playSound1) hasta que termine


  Future<void> playSound1(String source) {
    try {
      return player1.play(AssetSource(source));
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

  Future<void> playNLoopsSound(String source, int loops) async {
    try {
      int currentLoops = 0;
      await playerNLoops.setReleaseMode(ReleaseMode.stop);
      playerNLoops.onPlayerComplete.listen((event) {
        currentLoops ++;
        if (currentLoops >= loops) {
          playerNLoops.release();
          return;
        }
        playerNLoops.resume();
      });
      await playerNLoops.play(AssetSource(source));
    } catch (e) {
      return Future.value();
    }
  }
}
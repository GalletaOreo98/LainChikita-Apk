import 'package:audioplayers/audioplayers.dart';

//final _player = AudioPlayer(playerId: 'btnLove');

/* Future<void> playBtnSound() async {
    await _player.play(AssetSource("audio/btn_sound.mp3"));
} */

class AppAudioPlayer {
  late AudioPlayer _player;

  Future<void> playSound(String source) async {
    await _player.play(AssetSource(source));
  }

  Future<void> startAppAudioPlayerService() async{
    _player = AudioPlayer();
    await _player.setPlayerMode(PlayerMode.lowLatency);
  }
}
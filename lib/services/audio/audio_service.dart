import 'package:injectable/injectable.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';

@lazySingleton
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.8;

  Future<void> initialize() async {
    await setVolume(_volume);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _player.setVolume(volume);
  }

  Future<void> _play(String assetPath) async {
    try {
      await _player.stop();
      await _player.setAsset(assetPath);
      await _player.play();
    } catch (e) {
      AppLogger.e('AudioService error: $e');
    }
  }

  Future<void> playBuzzer()    => _play(AppConstants.buzzerSoundPath);
  Future<void> playCorrect()   => _play(AppConstants.correctSoundPath);
  Future<void> playWrong()     => _play(AppConstants.wrongSoundPath);
  Future<void> playTick()      => _play(AppConstants.tickSoundPath);
  Future<void> playVictory()   => _play(AppConstants.victoryFanfarePath);
  Future<void> playCountdown() => _play(AppConstants.countdownSoundPath);
  Future<void> stopAll() async => _player.stop();

  @disposeMethod
  void dispose() => _player.dispose();
}

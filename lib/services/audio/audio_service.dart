import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';
import '../../core/utils/app_logger.dart';

@lazySingleton
class AudioService {
  // Lazy map — players are created on first use, not at field-init time.
  // Creating all players up-front before the plugin DLL is fully initialised
  // can trigger _CrtIsValidHeapPointer heap-mismatch crashes on Windows.
  final Map<String, AudioPlayer> _players = {};

  double _volume = 0.8;

  Future<void> initialize() async {
    try {
      // AudioContext (mobile audio session config) is not needed on Windows/Desktop.
      // Calling it on Windows can cause premature plugin DLL initialisation and
      // subsequent heap-corruption crashes in debug builds.
      if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
        await AudioPlayer.global.setAudioContext(AudioContext());
      }
      AppLogger.i('AudioService: initialized');
    } catch (e) {
      AppLogger.e('AudioService: initialize error: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    for (final p in _players.values) {
      await p.setVolume(_volume);
    }
  }

  Future<void> playBuzzer()    => _play('buzzer',    'audio/buzzer.mp3');
  Future<void> playCorrect()   => _play('correct',   'audio/correct.mp3');
  Future<void> playWrong()     => _play('wrong',     'audio/wrong.mp3');
  Future<void> playTick()      => _play('tick',      'audio/tick.mp3');
  Future<void> playVictory()   => _play('victory',   'audio/victory.mp3');
  Future<void> playCountdown() => _play('countdown', 'audio/countdown.mp3');

  Future<void> stopAll() async {
    for (final p in _players.values) {
      try { await p.stop(); } catch (_) {}
    }
  }

  Future<void> _play(String key, String assetPath) async {
    try {
      final player = _players.putIfAbsent(key, () => AudioPlayer());
      await player.stop();
      await player.setVolume(_volume);
      await player.play(AssetSource(assetPath));
    } catch (e) {
      AppLogger.e('AudioService: play($assetPath) error: $e');
    }
  }

  @disposeMethod
  void dispose() {
    for (final p in _players.values) {
      try { p.dispose(); } catch (_) {}
    }
    _players.clear();
    AppLogger.i('AudioService: disposed');
  }
}

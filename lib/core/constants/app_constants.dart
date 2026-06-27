class AppConstants {
  AppConstants._();

  static const String dbName             = 'church_arena';
  static const String buzzerSoundPath    = 'assets/audio/buzzer.mp3';
  static const String correctSoundPath   = 'assets/audio/correct.mp3';
  static const String wrongSoundPath     = 'assets/audio/wrong.mp3';
  static const String tickSoundPath      = 'assets/audio/tick.mp3';
  static const String victoryFanfarePath = 'assets/audio/victory.mp3';
  static const String countdownSoundPath = 'assets/audio/countdown.mp3';
  static const int    defaultTimerSeconds = 30;
  static const int    defaultBaudRate     = 9600;
  static const int    maxTeams            = 8;
  static const int    minTeams            = 2;
  static const List<int> baudRates = [9600, 19200, 38400, 57600, 115200];
}

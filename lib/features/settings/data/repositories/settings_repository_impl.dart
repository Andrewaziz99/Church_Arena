import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

@LazySingleton(as: SettingsRepository)
class SettingsRepositoryImpl implements SettingsRepository {
  static const String _comPortKey     = 'settings_com_port';
  static const String _baudRateKey    = 'settings_baud_rate';
  static const String _volumeKey      = 'settings_volume';
  static const String _timerKey       = 'settings_timer_duration';
  static const String _teamsKey       = 'settings_number_of_teams';
  static const String _fullscreenKey  = 'settings_fullscreen';

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = AppSettings(
        comPort:       prefs.getString(_comPortKey) ?? 'COM3',
        baudRate:      prefs.getInt(_baudRateKey) ?? 9600,
        soundVolume:   prefs.getDouble(_volumeKey) ?? 0.8,
        timerDuration: prefs.getInt(_timerKey) ?? 30,
        numberOfTeams: prefs.getInt(_teamsKey) ?? 2,
        isFullscreen:  prefs.getBool(_fullscreenKey) ?? false,
      );
      return Right(settings);
    } catch (e) {
      AppLogger.e('SettingsRepository.getSettings: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_comPortKey, settings.comPort);
      await prefs.setInt(_baudRateKey, settings.baudRate);
      await prefs.setDouble(_volumeKey, settings.soundVolume);
      await prefs.setInt(_timerKey, settings.timerDuration);
      await prefs.setInt(_teamsKey, settings.numberOfTeams);
      await prefs.setBool(_fullscreenKey, settings.isFullscreen);
      return const Right(unit);
    } catch (e) {
      AppLogger.e('SettingsRepository.saveSettings: $e');
      return Left(DatabaseFailure(e.toString()));
    }
  }
}

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, AppSettings>> getSettings();
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings);
}

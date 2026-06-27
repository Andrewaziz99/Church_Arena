import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

@injectable
class SaveSettingsUseCase {
  final SettingsRepository _repository;
  const SaveSettingsUseCase(this._repository);

  Future<Either<Failure, Unit>> call(AppSettings settings) =>
      _repository.saveSettings(settings);
}

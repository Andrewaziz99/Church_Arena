import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

@injectable
class GetSettingsUseCase {
  final SettingsRepository _repository;
  const GetSettingsUseCase(this._repository);

  Future<Either<Failure, AppSettings>> call() => _repository.getSettings();
}

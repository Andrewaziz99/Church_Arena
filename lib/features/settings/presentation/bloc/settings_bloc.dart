import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../services/arduino/arduino_service.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

part 'settings_event.dart';
part 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase getSettings;
  final SaveSettingsUseCase saveSettings;
  final ArduinoService arduinoService;

  SettingsBloc({
    required this.getSettings,
    required this.saveSettings,
    required this.arduinoService,
  }) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<ToggleFullscreen>(_onToggleFullscreen);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    final result = await getSettings();
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) => emit(SettingsLoaded(settings)),
    );
  }

  Future<void> _onSaveSettings(
    SaveSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await saveSettings(event.settings);
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(SettingsLoaded(event.settings)),
    );
  }

  Future<void> _onToggleFullscreen(
    ToggleFullscreen event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;
    final isFullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullscreen);
    final updated = currentState.settings.copyWith(isFullscreen: !isFullscreen);
    add(SaveSettings(updated));
  }
}

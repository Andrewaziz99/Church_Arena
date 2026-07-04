import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../services/arduino/arduino_service.dart';
import '../../../../services/sync/supabase_sync_service.dart';
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
      (settings) {
        appRoomId = settings.roomId; // apply saved room to sync service
        emit(SettingsLoaded(settings));
        // Auto-connect to Arduino using saved COM port on startup.
        if (settings.comPort.isNotEmpty && !arduinoService.isConnected) {
          arduinoService.connect(settings.comPort, settings.baudRate);
        }
      },
    );
  }

  Future<void> _onSaveSettings(
    SaveSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await saveSettings(event.settings);
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) {
        appRoomId = event.settings.roomId; // apply new room immediately
        emit(SettingsLoaded(event.settings));
        // Reconnect if COM port or baud rate changed.
        final prev = state is SettingsLoaded
            ? (state as SettingsLoaded).settings
            : null;
        final portChanged = prev == null ||
            prev.comPort != event.settings.comPort ||
            prev.baudRate != event.settings.baudRate;
        if (portChanged && event.settings.comPort.isNotEmpty) {
          arduinoService.connect(event.settings.comPort, event.settings.baudRate);
        }
      },
    );
  }

  Future<void> _onToggleFullscreen(
    ToggleFullscreen event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;
    // Fire-and-forget — don't await the OS window transition.
    // This lets the UI stay responsive while Windows animates.
    unawaited(windowManager.setFullScreen(event.value));
    final updated = currentState.settings.copyWith(isFullscreen: event.value);
    add(SaveSettings(updated));
  }
}

part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
  @override
  List<Object> get props => [];
}

class SaveSettings extends SettingsEvent {
  final AppSettings settings;
  const SaveSettings(this.settings);
  @override
  List<Object> get props => [settings];
}

class ToggleFullscreen extends SettingsEvent {
  final bool value;
  const ToggleFullscreen(this.value);
  @override
  List<Object> get props => [value];
}

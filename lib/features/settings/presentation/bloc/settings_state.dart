part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
  @override
  List<Object> get props => [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
  @override
  List<Object> get props => [];
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object> get props => [message];
}

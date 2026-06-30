import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String comPort;
  final int baudRate;
  final double soundVolume;
  final int timerDuration;
  final int numberOfTeams;
  final bool isFullscreen;
  /// Supabase room identifier — scopes this device's sync to a specific room.
  final String roomId;

  const AppSettings({
    this.comPort = 'COM3',
    this.baudRate = 9600,
    this.soundVolume = 0.8,
    this.timerDuration = 30,
    this.numberOfTeams = 2,
    this.isFullscreen = false,
    this.roomId = 'room1',
  });

  AppSettings copyWith({
    String? comPort,
    int? baudRate,
    double? soundVolume,
    int? timerDuration,
    int? numberOfTeams,
    bool? isFullscreen,
    String? roomId,
  }) {
    return AppSettings(
      comPort: comPort ?? this.comPort,
      baudRate: baudRate ?? this.baudRate,
      soundVolume: soundVolume ?? this.soundVolume,
      timerDuration: timerDuration ?? this.timerDuration,
      numberOfTeams: numberOfTeams ?? this.numberOfTeams,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      roomId: roomId ?? this.roomId,
    );
  }

  @override
  List<Object?> get props => [comPort, baudRate, soundVolume, timerDuration,
        numberOfTeams, isFullscreen, roomId];
}

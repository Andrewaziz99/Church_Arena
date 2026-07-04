import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../services/arduino/arduino_service.dart';
import 'package:get_it/get_it.dart';
import '../bloc/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ArduinoService _arduinoService = GetIt.I<ArduinoService>();
  bool _testingConnection = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            context.showSnackBar(state.message, isError: true);
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SettingsLoaded) {
            return _SettingsBody(
              settings: state.settings,
              arduinoService: _arduinoService,
              testingConnection: _testingConnection,
              onTestConnection: (port, baud) => _testConnection(port, baud),
            );
          }
          return const Center(
            child: Text(
              'Loading settings...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        },
      ),
    );
  }

  Future<void> _testConnection(String port, int baud) async {
    setState(() => _testingConnection = true);
    final success = await _arduinoService.connect(port, baud);
    if (mounted) {
      setState(() => _testingConnection = false);
      context.showSnackBar(
        success ? AppStrings.connected : AppStrings.connectionFailed,
        isError: !success,
      );
    }
  }
}

class _SettingsBody extends StatefulWidget {
  final dynamic settings;
  final ArduinoService arduinoService;
  final bool testingConnection;
  final Function(String, int) onTestConnection;

  const _SettingsBody({
    required this.settings,
    required this.arduinoService,
    required this.testingConnection,
    required this.onTestConnection,
  });

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late String _comPort;
  late int _baudRate;
  late double _volume;
  late int _timerDuration;
  late int _numberOfTeams;
  late bool _isFullscreen;
  late TextEditingController _roomIdCtrl;

  @override
  void initState() {
    super.initState();
    _comPort = widget.settings.comPort;
    _baudRate = widget.settings.baudRate;
    _volume = widget.settings.soundVolume;
    _timerDuration = widget.settings.timerDuration;
    _numberOfTeams = widget.settings.numberOfTeams;
    _isFullscreen = widget.settings.isFullscreen;
    _roomIdCtrl = TextEditingController(text: widget.settings.roomId);
  }

  @override
  void dispose() {
    _roomIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availablePorts = widget.arduinoService.getAvailablePorts().toSet().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(AppStrings.serialSettings),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: availablePorts.contains(_comPort)
                              ? _comPort
                              : null,
                          decoration: const InputDecoration(
                            labelText: AppStrings.comPort,
                          ),
                          hint: Text(
                            availablePorts.isEmpty
                                ? 'No ports found'
                                : 'Select port',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                          items: availablePorts
                              .map((p) =>
                                  DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _comPort = v ?? _comPort),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: AppConstants.baudRates.contains(_baudRate)
                              ? _baudRate
                              : AppConstants.baudRates.first,
                          decoration: const InputDecoration(
                            labelText: AppStrings.baudRate,
                          ),
                          items: AppConstants.baudRates
                              .map((b) => DropdownMenuItem(
                                  value: b, child: Text('$b')))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _baudRate = v ?? _baudRate),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.testingConnection
                          ? null
                          : () =>
                              widget.onTestConnection(_comPort, _baudRate),
                      icon: widget.testingConnection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cable),
                      label: Text(widget.testingConnection
                          ? 'Connecting...'
                          : AppStrings.testConnection),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(AppStrings.gameSettings),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.timerDuration}: $_timerDuration s',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  Slider(
                    value: _timerDuration.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 22,
                    label: '$_timerDuration s',
                    onChanged: (v) =>
                        setState(() => _timerDuration = v.round()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        AppStrings.numberOfTeams,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _numberOfTeams > AppConstants.minTeams
                            ? () => setState(() => _numberOfTeams--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_numberOfTeams',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _numberOfTeams < AppConstants.maxTeams
                            ? () => setState(() => _numberOfTeams++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(AppStrings.audioSettings),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.volume}: ${(_volume * 100).round()}%',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    label: '${(_volume * 100).round()}%',
                    onChanged: (v) => setState(() => _volume = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(AppStrings.displaySettings),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    AppStrings.fullscreen,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isFullscreen,
                    onChanged: (v) {
                      setState(() => _isFullscreen = v);
                      context.read<SettingsBloc>().add(ToggleFullscreen(v));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Online Sync'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room ID',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Devices with the same Room ID share scores and session data in real-time.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roomIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room ID',
                      hintText: 'e.g. room1, main-hall, youth-room',
                      prefixIcon: Icon(Icons.meeting_room_rounded),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text(AppStrings.saveSettings),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final roomId = _roomIdCtrl.text.trim();
    final updated = widget.settings.copyWith(
      comPort: _comPort,
      baudRate: _baudRate,
      soundVolume: _volume,
      timerDuration: _timerDuration,
      numberOfTeams: _numberOfTeams,
      isFullscreen: _isFullscreen,
      roomId: roomId.isEmpty ? 'room1' : roomId,
    );
    context.read<SettingsBloc>().add(SaveSettings(updated));
    context.showSnackBar('Settings saved');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

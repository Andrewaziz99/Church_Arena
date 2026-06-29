import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:injectable/injectable.dart';
import '../../core/utils/app_logger.dart';

@lazySingleton
class ArduinoService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _sub;
  bool _locked = false;

  final StreamController<String> _buzzerController =
      StreamController<String>.broadcast();

  Stream<String> get buzzerStream => _buzzerController.stream;

  bool get isConnected {
    try {
      return _port?.isOpen ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns a list of all available COM/serial port names on this machine.
  List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      AppLogger.e('ArduinoService: getAvailablePorts error: $e');
      return [];
    }
  }

  /// Opens [portName] at [baudRate] and starts listening for buzzer events.
  /// Returns true on success.
  Future<bool> connect(String portName, int baudRate) async {
    try {
      disconnect(); // close any existing connection first

      _port = SerialPort(portName);
      if (!_port!.openReadWrite()) {
        final err = SerialPort.lastError;
        AppLogger.e('ArduinoService: failed to open $portName — $err');
        // Do NOT call _port!.dispose() here — disposing a SerialPort whose
        // internal handle was allocated in the plugin DLL's CRT heap and freed
        // from the runner's CRT heap triggers _CrtIsValidHeapPointer in debug.
        // Set to null and let the GC / finalizer handle cleanup.
        _port = null;
        return false;
      }

      // Configure port — baud/bits/parity only.
      // RTS/CTS omitted (cross-heap crash). config.dispose() also omitted for
      // the same reason: the SerialPortConfig struct is allocated inside the
      // plugin DLL's heap; calling dispose() from the runner crosses heap
      // boundaries. The Dart finalizer cleans it up safely instead.
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      _port!.config = config;
      // config.dispose() intentionally omitted — let GC/finalizer handle it.

      // Start reading
      _reader = SerialPortReader(_port!);
      _sub = _reader!.stream.listen(
        _onData,
        onError: (e) => AppLogger.e('ArduinoService: read error: $e'),
      );

      AppLogger.i('ArduinoService: connected to $portName @ $baudRate baud');
      return true;
    } catch (e) {
      AppLogger.e('ArduinoService: connect error: $e');
      return false;
    }
  }

  // Accumulate bytes until a complete message is available.
  final StringBuffer _rxBuffer = StringBuffer();

  /// Called whenever bytes arrive from the Arduino.
  ///
  /// Arduino protocol (from sketch):
  ///   Arduino → Flutter : "TEAM_1\n" … "TEAM_4\n"
  ///   Flutter → Arduino : "RESET\n"
  ///   Arduino → Flutter : "READY\n" on startup, "RESET_DONE\n" after reset
  void _onData(Uint8List data) {
    if (_locked) return;
    _rxBuffer.write(String.fromCharCodes(data));

    // Messages are newline-terminated — wait for a complete line.
    final raw = _rxBuffer.toString();
    if (!raw.contains('\n')) return;

    final msg = raw.substring(0, raw.indexOf('\n')).trim();
    _rxBuffer.clear();

    if (msg.isEmpty || msg == 'READY' || msg == 'RESET_DONE') return;

    // Parse "TEAM_1", "TEAM_2", "TEAM_3", "TEAM_4"
    if (msg.startsWith('TEAM_')) {
      final teamIndex = msg.substring(5).trim(); // "TEAM_1" → "1"
      if (teamIndex.isEmpty) return;
      _locked = true;
      AppLogger.i('ArduinoService: buzzer received — team $teamIndex');
      _buzzerController.add(teamIndex);
    }
  }

  /// Unlocks the buzzer and sends a reset signal to the Arduino
  /// so it re-enables the physical buttons.
  void resetBuzzers() {
    _locked = false;
    sendResetSignal();
  }

  /// Sends "RESET\n" to the Arduino, which clears its lock and turns off LEDs.
  void sendResetSignal() {
    _locked = false;
    try {
      if (_port != null && _port!.isOpen) {
        _port!.write(Uint8List.fromList('RESET\n'.codeUnits));
        AppLogger.i('ArduinoService: RESET command sent');
      }
    } catch (e) {
      AppLogger.e('ArduinoService: sendResetSignal error: $e');
    }
  }

  /// Closes the serial port cleanly.
  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _reader = null;
    _rxBuffer.clear();
    _locked = false;
    try {
      if (_port?.isOpen == true) _port!.close();
    } catch (_) {}
    // _port?.dispose() omitted — same cross-heap reason as config.dispose().
    // The port handle was allocated inside the plugin DLL; disposing from the
    // runner CRT heap in debug mode triggers _CrtIsValidHeapPointer.
    _port = null;
    AppLogger.i('ArduinoService: disconnected');
  }

  @disposeMethod
  void dispose() {
    disconnect();
    _buzzerController.close();
  }
}

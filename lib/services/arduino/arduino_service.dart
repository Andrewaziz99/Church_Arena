import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:injectable/injectable.dart';
import '../../core/utils/app_logger.dart';

@lazySingleton
class ArduinoService {
  SerialPort? _port;
  SerialPortReader? _reader;
  bool _locked = false;
  bool _connected = false;
  final StreamController<String> _buzzerController =
      StreamController<String>.broadcast();

  Stream<String> get buzzerStream => _buzzerController.stream;
  bool get isConnected => _connected;

  List<String> getAvailablePorts() => SerialPort.availablePorts;

  Future<bool> connect(String portName, int baudRate) async {
    try {
      _port = SerialPort(portName);
      if (!_port!.openReadWrite()) {
        AppLogger.e('Failed to open port $portName');
        return false;
      }
      final config = SerialPortConfig();
      config.baudRate = baudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      _port!.config = config;
      _reader = SerialPortReader(_port!);
      _reader!.stream.listen(_onData, onError: (e) {
        AppLogger.e('Serial error: $e');
        _connected = false;
      });
      _connected = true;
      AppLogger.i('Connected to $portName at $baudRate baud');
      return true;
    } catch (e) {
      AppLogger.e('Arduino connect error: $e');
      return false;
    }
  }

  void _onData(List<int> data) {
    if (_locked) return;
    for (final byte in data) {
      final char = String.fromCharCode(byte);
      if (RegExp(r'[1-8]').hasMatch(char)) {
        _locked = true;
        _buzzerController.add(char);
        AppLogger.d('Buzzer pressed: team $char');
        break;
      }
    }
  }

  void resetBuzzers() => _locked = false;

  /// Sends 'R' over serial to the Arduino and unlocks the buzzer lock.
  void sendResetSignal() {
    if (_port != null && _port!.isOpen) {
      try {
        _port!.write(Uint8List.fromList('R'.codeUnits));
        AppLogger.d('Reset signal sent to Arduino');
      } catch (e) {
        AppLogger.e('Failed to send reset signal: $e');
      }
    }
    _locked = false;
  }

  void disconnect() {
    _reader?.close();
    _port?.close();
    _port?.dispose();
    _connected = false;
    AppLogger.i('Disconnected from serial port');
  }

  @disposeMethod
  void dispose() {
    disconnect();
    _buzzerController.close();
  }
}

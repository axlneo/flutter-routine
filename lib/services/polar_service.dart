import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';
import 'package:permission_handler/permission_handler.dart';

enum PolarConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class PolarService {
  static final PolarService _instance = PolarService._internal();
  factory PolarService() => _instance;
  PolarService._internal() {
    _initStreams();
  }

  final Polar _polar = Polar();

  String? _connectedDeviceId;
  PolarConnectionState _connectionState = PolarConnectionState.disconnected;
  int? _currentHr;

  StreamSubscription<PolarDeviceInfo>? _scanSubscription;
  StreamSubscription<PolarHrData>? _hrSubscription;
  StreamSubscription<PolarDeviceInfo>? _connectingSubscription;
  StreamSubscription<PolarDeviceInfo>? _connectedSubscription;
  StreamSubscription<PolarDeviceDisconnectedEvent>? _disconnectedSubscription;

  // Stream controllers
  final _connectionStateController = StreamController<PolarConnectionState>.broadcast();
  final _hrController = StreamController<int>.broadcast();
  final _devicesController = StreamController<List<PolarDeviceInfo>>.broadcast();

  // Getters
  Stream<PolarConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<int> get hrStream => _hrController.stream;
  Stream<List<PolarDeviceInfo>> get devicesStream => _devicesController.stream;
  PolarConnectionState get connectionState => _connectionState;
  int? get currentHr => _currentHr;
  String? get connectedDeviceId => _connectedDeviceId;
  bool get isConnected => _connectionState == PolarConnectionState.connected;

  final List<PolarDeviceInfo> _foundDevices = [];

  void _initStreams() {
    // Listen to connection state changes from Polar SDK
    _connectingSubscription = _polar.deviceConnecting.listen((device) {
      debugPrint('Device connecting: ${device.deviceId}');
      _setConnectionState(PolarConnectionState.connecting);
    });

    _connectedSubscription = _polar.deviceConnected.listen((device) {
      debugPrint('Device connected: ${device.deviceId}');
      _connectedDeviceId = device.deviceId;
      _setConnectionState(PolarConnectionState.connected);
      // Start HR streaming once connected
      _startHrStreaming(device.deviceId);
    });

    _disconnectedSubscription = _polar.deviceDisconnected.listen((event) {
      debugPrint('Device disconnected: ${event.info.deviceId}');
      if (_connectedDeviceId == event.info.deviceId) {
        _connectedDeviceId = null;
        _currentHr = null;
        _setConnectionState(PolarConnectionState.disconnected);
      }
    });
  }

  /// Request BLE permissions
  Future<bool> requestPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final locationWhenInUse = await Permission.locationWhenInUse.request();

    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        locationWhenInUse.isGranted;
  }

  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.isGranted;
    final bluetoothConnect = await Permission.bluetoothConnect.isGranted;
    final locationWhenInUse = await Permission.locationWhenInUse.isGranted;

    return bluetoothScan && bluetoothConnect && locationWhenInUse;
  }

  /// Start scanning for Polar devices
  Future<void> startScan() async {
    if (!await hasPermissions()) {
      final granted = await requestPermissions();
      if (!granted) {
        _setConnectionState(PolarConnectionState.error);
        return;
      }
    }

    _foundDevices.clear();
    _setConnectionState(PolarConnectionState.scanning);

    try {
      _scanSubscription?.cancel();
      _scanSubscription = _polar.searchForDevice().listen(
            (device) {
          debugPrint('Found device: ${device.deviceId} - ${device.name}');

          // Only add H10 devices or Polar devices
          if (device.name.toLowerCase().contains('h10') ||
              device.name.toLowerCase().contains('polar')) {
            if (!_foundDevices.any((d) => d.deviceId == device.deviceId)) {
              _foundDevices.add(device);
              _devicesController.add(List.from(_foundDevices));
            }
          }
        },
        onError: (error) {
          debugPrint('Scan error: $error');
          _setConnectionState(PolarConnectionState.error);
        },
      );

      // Stop scanning after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        stopScan();
      });
    } catch (e) {
      debugPrint('Start scan error: $e');
      _setConnectionState(PolarConnectionState.error);
    }
  }

  /// Stop scanning
  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_connectionState == PolarConnectionState.scanning) {
      _setConnectionState(PolarConnectionState.disconnected);
    }
  }

  /// Connect to a specific device
  Future<void> connectToDevice(String deviceId) async {
    try {
      stopScan();
      _setConnectionState(PolarConnectionState.connecting);

      // The Polar SDK handles connection state via streams
      await _polar.connectToDevice(deviceId);

      debugPrint('Connection initiated to $deviceId');
    } catch (e) {
      debugPrint('Connect error: $e');
      _setConnectionState(PolarConnectionState.error);
    }
  }

  /// Start HR streaming
  Future<void> _startHrStreaming(String deviceId) async {
    try {
      // Wait for streaming features to be ready
      await _polar.sdkFeatureReady.firstWhere(
            (e) => e.identifier == deviceId &&
            e.feature == PolarSdkFeature.onlineStreaming,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Timeout waiting for streaming features');
          throw TimeoutException('Streaming features not ready');
        },
      );

      // Check available data types
      final availableTypes = await _polar.getAvailableOnlineStreamDataTypes(deviceId);
      debugPrint('Available stream types: $availableTypes');

      if (availableTypes.contains(PolarDataType.hr)) {
        _hrSubscription?.cancel();
        _hrSubscription = _polar.startHrStreaming(deviceId).listen(
              (data) {
            if (data.samples.isNotEmpty) {
              final hr = data.samples.first.hr;
              _currentHr = hr;
              _hrController.add(hr);
            }
          },
          onError: (error) {
            debugPrint('HR streaming error: $error');
          },
        );
        debugPrint('HR streaming started');
      } else {
        debugPrint('HR streaming not available');
      }
    } catch (e) {
      debugPrint('Start HR streaming error: $e');
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      _hrSubscription?.cancel();
      _hrSubscription = null;

      if (_connectedDeviceId != null) {
        await _polar.disconnectFromDevice(_connectedDeviceId!);
      }

      _connectedDeviceId = null;
      _currentHr = null;
      _setConnectionState(PolarConnectionState.disconnected);

      debugPrint('Disconnected');
    } catch (e) {
      debugPrint('Disconnect error: $e');
      _setConnectionState(PolarConnectionState.disconnected);
    }
  }

  void _setConnectionState(PolarConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _hrSubscription?.cancel();
    _connectingSubscription?.cancel();
    _connectedSubscription?.cancel();
    _disconnectedSubscription?.cancel();
    _connectionStateController.close();
    _hrController.close();
    _devicesController.close();
  }
}

/// Extension for connection state display
extension PolarConnectionStateExtension on PolarConnectionState {
  String get label {
    switch (this) {
      case PolarConnectionState.disconnected:
        return 'Déconnecté';
      case PolarConnectionState.scanning:
        return 'Recherche...';
      case PolarConnectionState.connecting:
        return 'Connexion...';
      case PolarConnectionState.connected:
        return 'Connecté';
      case PolarConnectionState.error:
        return 'Erreur';
    }
  }

  String get icon {
    switch (this) {
      case PolarConnectionState.disconnected:
        return '📴';
      case PolarConnectionState.scanning:
        return '🔍';
      case PolarConnectionState.connecting:
        return '⏳';
      case PolarConnectionState.connected:
        return '✅';
      case PolarConnectionState.error:
        return '❌';
    }
  }
}

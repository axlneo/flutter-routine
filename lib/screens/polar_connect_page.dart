import 'dart:async';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import '../services/polar_service.dart';
import '../services/storage_service.dart';

class PolarConnectPage extends StatefulWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onSkipped;

  const PolarConnectPage({
    super.key,
    this.onConnected,
    this.onSkipped,
  });

  @override
  State<PolarConnectPage> createState() => _PolarConnectPageState();
}

class _PolarConnectPageState extends State<PolarConnectPage>
    with SingleTickerProviderStateMixin {
  final PolarService _polar = PolarService();
  final StorageService _storage = StorageService();

  List<PolarDeviceInfo> _devices = [];
  StreamSubscription<List<PolarDeviceInfo>>? _devicesSubscription;
  StreamSubscription<PolarConnectionState>? _connectionSubscription;
  StreamSubscription<int>? _hrSubscription;
  
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectingDeviceId;
  String? _errorMessage;
  int? _currentHr;
  Timer? _reconnectTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _subscribeToStreams();
    _checkExistingConnection();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _subscribeToStreams() {
    _devicesSubscription = _polar.devicesStream.listen((devices) {
      setState(() => _devices = devices);
    });

    _connectionSubscription = _polar.connectionStateStream.listen((state) {
      setState(() {
        _isConnecting = state == PolarConnectionState.connecting;

        if (state == PolarConnectionState.connected) {
          _reconnectTimer?.cancel();
          _onConnectionSuccess();
        } else if (state == PolarConnectionState.error) {
          _reconnectTimer?.cancel();
          _errorMessage = 'Erreur de connexion. Réessayez.';
          _isConnecting = false;
          _connectingDeviceId = null;
        }
      });
    });

    _hrSubscription = _polar.hrStream.listen((hr) {
      setState(() => _currentHr = hr);
    });
  }

  void _checkExistingConnection() {
    if (_polar.isConnected) {
      // Already connected - wait a bit then close
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onConnected?.call();
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      // Check for saved device
      final savedDeviceId = _storage.settings.polarDeviceId;
      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        _connectToDevice(savedDeviceId);
        // 15s timeout — if reconnection fails, fallback to scan
        _reconnectTimer = Timer(const Duration(seconds: 15), () {
          if (mounted && _isConnecting && !_polar.isConnected) {
            debugPrint('Reconnection timeout, falling back to scan');
            setState(() {
              _isConnecting = false;
              _connectingDeviceId = null;
              _errorMessage = 'Reconnexion échouée. Lancement du scan...';
            });
            _startScan();
          }
        });
      } else {
        _startScan();
      }
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _errorMessage = null;
    });

    await _polar.startScan();

    // Update scanning state after timeout
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) {
        setState(() => _isScanning = false);
      }
    });
  }

  void _stopScan() {
    _polar.stopScan();
    setState(() => _isScanning = false);
  }

  void _connectToDevice(String deviceId) async {
    setState(() {
      _isConnecting = true;
      _connectingDeviceId = deviceId;
      _errorMessage = null;
    });

    _stopScan();
    await _polar.connectToDevice(deviceId);
  }

  void _onConnectionSuccess() async {
    // Save device ID for future connections
    final settings = _storage.settings;
    settings.polarDeviceId = _polar.connectedDeviceId;
    await _storage.saveSettings(settings);

    // Wait a moment to show connected state
    await Future.delayed(const Duration(milliseconds: 800));

    widget.onConnected?.call();
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _skip() {
    widget.onSkipped?.call();
    Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _pulseController.dispose();
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _hrSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _skip,
        ),
        title: const Text(
          'Connexion Polar H10',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Passer',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Heart animation
              const SizedBox(height: 20),
              _buildHeartAnimation(),
              const SizedBox(height: 30),

              // Status text
              _buildStatusText(),
              const SizedBox(height: 30),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Devices list
              Expanded(
                child: _buildDevicesList(),
              ),

              // Scan button
              if (!_isConnecting) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? _stopScan : _startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning ? Colors.orange : Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                    label: Text(
                      _isScanning ? 'Arrêter la recherche' : 'Rechercher appareils',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartAnimation() {
    final isConnected = _polar.isConnected;
    final color = isConnected ? Colors.green : Colors.red;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 120 * (isConnected ? 1.0 : _pulseAnimation.value),
          height: 120 * (isConnected ? 1.0 : _pulseAnimation.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.favorite : Icons.favorite_border,
                  size: 50,
                  color: color,
                ),
                if (_currentHr != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$_currentHr',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    String text;
    Color color;

    if (_polar.isConnected) {
      text = 'Connecté !';
      color = Colors.green;
    } else if (_isConnecting) {
      text = 'Connexion en cours...';
      color = Colors.orange;
    } else if (_isScanning) {
      text = 'Recherche d\'appareils Polar...';
      color = Colors.blue;
    } else {
      text = 'Prêt à connecter';
      color = Colors.white70;
    }

    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (_isScanning || _isConnecting) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDevicesList() {
    if (_devices.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun appareil trouvé',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur Rechercher pour scanner',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnecting = _connectingDeviceId == device.deviceId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnecting ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.watch,
                color: Colors.red,
                size: 28,
              ),
            ),
            title: Text(
              device.name.isNotEmpty ? device.name : 'Polar Device',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'ID: ${device.deviceId}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.orange),
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
            onTap: isConnecting ? null : () => _connectToDevice(device.deviceId),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Conseils',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Humidifiez les électrodes de la ceinture\n'
            '• Portez la ceinture sous la poitrine\n'
            '• Attendez que le voyant clignote',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

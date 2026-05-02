import 'dart:async';
import 'package:flutter/material.dart';
import 'package:polar/polar.dart';
import '../services/polar_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

class PolarConnectPage extends StatefulWidget {
  final VoidCallback? onConnected;
  final VoidCallback? onSkipped;

  const PolarConnectPage({super.key, this.onConnected, this.onSkipped});

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
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
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onConnected?.call();
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      final savedDeviceId = _storage.settings.polarDeviceId;
      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        _connectToDevice(savedDeviceId);
        _reconnectTimer = Timer(const Duration(seconds: 15), () {
          if (mounted && _isConnecting && !_polar.isConnected) {
            debugPrint('Reconnection timeout, falling back to scan');
            setState(() {
              _isConnecting = false;
              _connectingDeviceId = null;
              _errorMessage = 'Reconnexion échouée. Lancement du scan…';
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
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) setState(() => _isScanning = false);
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
    final settings = _storage.settings;
    settings.polarDeviceId = _polar.connectedDeviceId;
    await _storage.saveSettings(settings);
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onConnected?.call();
    if (mounted) Navigator.pop(context, true);
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
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Polar H10',
            subtitle: 'Connexion ceinture HR',
            onBack: _skip,
            actions: [
              TextButton(
                onPressed: _skip,
                child: const Text(
                  'Passer',
                  style: TextStyle(color: AppColors.textOnDarkMuted, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  _buildHeartAnimation(),
                  const SizedBox(height: 18),
                  _buildStatusText(),
                  const SizedBox(height: 18),
                  if (_errorMessage != null) ...[
                    AppCard(
                      color: AppColors.heartSoft,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.heart, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.heart, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Expanded(child: _buildDevicesList()),
                  if (!_isConnecting) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? _stopScan : _startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isScanning ? AppColors.warning : AppColors.heart,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching, size: 20),
                        label: Text(
                          _isScanning ? 'Arrêter' : 'Rechercher',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInstructions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation() {
    final isConnected = _polar.isConnected;
    final color = isConnected ? AppColors.success : AppColors.heart;
    final softColor = isConnected ? AppColors.successSoft : AppColors.heartSoft;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isConnected ? 1.0 : _pulseAnimation.value;
        return Container(
          width: 110 * scale,
          height: 110 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: softColor,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.favorite : Icons.favorite_border,
                  size: 44,
                  color: color,
                ),
                if (_currentHr != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_currentHr',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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
      text = 'Connecté';
      color = AppColors.success;
    } else if (_isConnecting) {
      text = 'Connexion en cours…';
      color = AppColors.warning;
    } else if (_isScanning) {
      text = 'Recherche d\'appareils…';
      color = AppColors.info;
    } else {
      text = 'Prêt à connecter';
      color = AppColors.textSecondary;
    }

    return Column(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        if (_isScanning || _isConnecting) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(color)),
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
            const AppIconBadge(
              icon: Icons.bluetooth_disabled,
              color: AppColors.textTertiary,
              soft: AppColors.surfaceMuted,
              size: 60,
            ),
            const SizedBox(height: 14),
            const Text(
              'Aucun appareil trouvé',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Appuie sur "Rechercher" pour scanner',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
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

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: isConnecting ? null : () => _connectToDevice(device.deviceId),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AppIconBadge(
                  icon: Icons.favorite,
                  color: isConnecting ? AppColors.warning : AppColors.heart,
                  soft: isConnecting ? const Color(0xFFFFF3E0) : AppColors.heartSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name.isNotEmpty ? device.name : 'Polar Device',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        device.deviceId,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (isConnecting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.warning)),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return AppCard(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              Text(
                'CONSEILS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Humidifie les électrodes de la ceinture\n'
            '• Porte la ceinture sous la poitrine\n'
            '• Attends que le voyant clignote',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

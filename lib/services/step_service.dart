import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

enum StepStatus {
  /// Health Connect not installed (Android only)
  healthConnectUnavailable,

  /// Permissions not yet granted
  noPermission,

  /// Ready and fetching data
  ready,
}

class StepService {
  static final StepService _instance = StepService._internal();
  factory StepService() => _instance;
  StepService._internal();

  static const _healthConnectPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';

  final _stepsController = StreamController<int>.broadcast();
  final _statusController = StreamController<StepStatus>.broadcast();
  Timer? _refreshTimer;
  int? _todaySteps;
  bool _initialized = false;
  StepStatus _status = StepStatus.noPermission;

  Stream<int> get stepsStream => _stepsController.stream;
  Stream<StepStatus> get statusStream => _statusController.stream;
  int? get todaySteps => _todaySteps;
  StepStatus get status => _status;

  /// Initialize Health (lightweight — no permission dialog).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    Health().configure();

    if (Platform.isAndroid) {
      final sdkStatus = await Health().getHealthConnectSdkStatus();
      debugPrint('StepService: Health Connect SDK status = $sdkStatus');
      final available = sdkStatus == HealthConnectSdkStatus.sdkAvailable;
      if (!available) {
        debugPrint('StepService: Health Connect NOT available, status=$sdkStatus');
        _setStatus(StepStatus.healthConnectUnavailable);
        return;
      }
    }

    final hasPerm = await _checkPermissions();
    debugPrint('StepService: hasPermissions = $hasPerm');
    if (hasPerm) {
      _setStatus(StepStatus.ready);
      await refreshSteps();
    } else {
      _setStatus(StepStatus.noPermission);
    }

    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_status == StepStatus.ready) refreshSteps();
    });
  }

  void _setStatus(StepStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Future<bool> _checkPermissions() async {
    try {
      final result = await Health().hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      return result == true;
    } catch (e) {
      debugPrint('StepService: permission check error — $e');
      return false;
    }
  }

  /// Open Play Store to install Health Connect (HTTPS fallback for MIUI).
  Future<bool> installHealthConnect() async {
    final uri = Uri.parse(_healthConnectPlayStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    debugPrint('StepService: cannot open Play Store URL');
    return false;
  }

  /// Open Health Connect settings via Android intent.
  Future<bool> openHealthConnectSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      const intent = AndroidIntent(
        action: 'android.health.connect.action.HEALTH_HOME_SETTINGS',
      );
      await intent.launch();
      return true;
    } catch (e) {
      debugPrint('StepService: cannot open Health Connect settings — $e');
      return false;
    }
  }

  /// Re-check permissions/availability after returning from settings.
  Future<void> recheckAfterSettings() async {
    if (Platform.isAndroid) {
      final available = await Health().isHealthConnectAvailable();
      if (!available) {
        _setStatus(StepStatus.healthConnectUnavailable);
        return;
      }
    }
    final hasPerm = await _checkPermissions();
    if (hasPerm) {
      _setStatus(StepStatus.ready);
      await refreshSteps();
    }
  }

  /// Re-check availability after returning from Play Store.
  Future<void> recheckAvailability() async {
    if (Platform.isAndroid) {
      final available = await Health().isHealthConnectAvailable();
      if (available && _status == StepStatus.healthConnectUnavailable) {
        _setStatus(StepStatus.noPermission);
      }
    }
  }

  /// Request Health Connect / HealthKit permissions (opens system UI).
  /// Returns a message string on failure (null on success).
  Future<String?> requestPermissions() async {
    if (Platform.isAndroid) {
      final available = await Health().isHealthConnectAvailable();
      if (!available) {
        _setStatus(StepStatus.healthConnectUnavailable);
        return 'Health Connect non disponible';
      }
    }

    try {
      debugPrint('StepService: calling requestAuthorization...');
      final granted = await Health().requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      debugPrint('StepService: requestAuthorization returned $granted');

      if (!granted) return 'Permission refusée';

      final verified = await _checkPermissions();
      debugPrint('StepService: post-auth hasPermissions = $verified');
      if (verified) {
        _setStatus(StepStatus.ready);
        return null; // success
      }
      return 'Permission non accordée dans Health Connect';
    } catch (e) {
      debugPrint('StepService: permission request error — $e');
      return 'Erreur : ouvrir Health Connect manuellement';
    }
  }

  // SOURCE: Health Connect — modifier cette méthode pour changer de provider
  /// Fetch today's total steps from midnight to now.
  Future<int> fetchTodaySteps() async {
    if (_status != StepStatus.ready) return 0;
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await Health().getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('StepService: fetch error — $e');
      return 0;
    }
  }

  Future<void> refreshSteps() async {
    final steps = await fetchTodaySteps();
    _todaySteps = steps;
    _stepsController.add(steps);
  }

  void dispose() {
    _refreshTimer?.cancel();
    _stepsController.close();
    _statusController.close();
  }
}

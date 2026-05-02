import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int _morningNotifId = 1;
  static const int _eveningNotifId = 2;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      await _createAndroidChannel();
    }

    _initialized = true;

    final settings = StorageService().settings;
    if (settings.notificationsEnabled) {
      var hasPerm = await hasPermissions();
      if (!hasPerm) {
        hasPerm = await requestPermissions();
      }
      if (hasPerm) {
        await scheduleAllNotifications();
        debugPrint('Notifications re-scheduled on startup');
      } else {
        settings.notificationsEnabled = false;
        await StorageService().saveSettings(settings);
        debugPrint('Notifications disabled (permission not granted)');
      }
    }
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      'fitness_reminders',
      'Rappels Fitness',
      description: 'Notifications pour les routines et médicaments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      final impl = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (impl == null) return false;
      final result = await impl.checkPermissions();
      return result?.isEnabled ?? false;
    }
    return false;
  }

  /// Schedule both daily notifications using current settings.
  Future<void> scheduleAllNotifications() async {
    await cancelAllNotifications();
    final settings = StorageService().settings;
    await _scheduleDailyNotification(
      id: _morningNotifId,
      title: '🌅 Routine du Matin',
      body: 'C\'est l\'heure de ta routine + médicaments du matin !\n'
          '💊 Ramipril, Bisoprolol, Metformine, Oméga-3, Multivitamines',
      hour: settings.morningHour,
      minute: settings.morningMinute,
      payload: 'morning',
    );
    await _scheduleDailyNotification(
      id: _eveningNotifId,
      title: '🌙 Routine du Soir',
      body: 'C\'est l\'heure de ta routine + médicaments du soir !\n'
          '💊 Aspirine, Bisoprolol, Atorvastatine + ézétimibe, Metformine, Multivitamines',
      hour: settings.eveningHour,
      minute: settings.eveningMinute,
      payload: 'evening',
    );
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    const androidDetails = AndroidNotificationDetails(
      'fitness_reminders',
      'Rappels Fitness',
      channelDescription: 'Notifications pour les routines et médicaments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'ic_notification',
      color: Color(0xFF7E57C2),
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('Scheduled notif $id at $scheduledTime');
    } catch (e, stack) {
      debugPrint('Failed to schedule notif $id: $e\n$stack');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id: id);
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() {
    return _notifications.pendingNotificationRequests();
  }

  /// Show immediate notification (for testing).
  Future<void> showTestNotification() async {
    final hasPerm = await hasPermissions();
    if (!hasPerm) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    const androidDetails = AndroidNotificationDetails(
      'fitness_reminders',
      'Rappels Fitness',
      channelDescription: 'Notifications pour les routines et médicaments',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification',
      color: Color(0xFF7E57C2),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      id: 999,
      title: '🔔 Test',
      body: 'Les notifications fonctionnent !',
      notificationDetails: details,
    );
  }
}

import 'dart:io';
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

  // Notification IDs
  static const int _morningNotifId = 1;
  static const int _eveningNotifId = 2;

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Paris'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
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
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _createAndroidChannel();
    }

    _initialized = true;

    // Re-schedule notifications if they were previously enabled
    final settings = StorageService().settings;
    if (settings.notificationsEnabled) {
      final hasPerm = await hasPermissions();
      if (hasPerm) {
        await scheduleAllNotifications();
        debugPrint('Notifications re-scheduled on startup');
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
    // Handle notification tap - could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      
      // For Android 12+, also request exact alarm permission
      if (Platform.isAndroid) {
        await Permission.scheduleExactAlarm.request();
      }
      
      return status.isGranted;
    } else if (Platform.isIOS) {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return false;
  }

  /// Check if permissions are granted
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't have a simple check, assume granted after request
      return true;
    }
    return false;
  }

  /// Schedule both daily notifications
  Future<void> scheduleAllNotifications() async {
    await cancelAllNotifications();
    await _scheduleMorningNotification();
    await _scheduleEveningNotification();
  }

  /// Schedule morning notification at 7:00
  Future<void> _scheduleMorningNotification() async {
    const title = '🌅 Routine du Matin';
    const body = 'C\'est l\'heure de ta routine + médicaments du matin !\n'
        '💊 Ramipril, Bisoprolol, Metformine, Oméga-3, Multivitamines';

    await _scheduleDailyNotification(
      id: _morningNotifId,
      title: title,
      body: body,
      hour: 7,
      minute: 0,
      payload: 'morning',
    );
  }

  /// Schedule evening notification at 19:00
  Future<void> _scheduleEveningNotification() async {
    const title = '🌙 Routine du Soir';
    const body = 'C\'est l\'heure de ta routine + médicaments du soir !\n'
        '💊 Aspirine, Bisoprolol, Atorvastatine + ézétimibe, Metformine, Multivitamines';

    await _scheduleDailyNotification(
      id: _eveningNotifId,
      title: title,
      body: body,
      hour: 19,
      minute: 0,
      payload: 'evening',
    );
  }

  /// Schedule a daily repeating notification
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
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('Scheduled notification $id at $scheduledTime');
  }

  /// Get next instance of specified time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Show immediate notification (for testing).
  /// Requests permission first if not already granted.
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
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999,
      '🔔 Test',
      'Les notifications fonctionnent !',
      details,
    );
  }
}

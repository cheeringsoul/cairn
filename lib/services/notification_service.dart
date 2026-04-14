import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages local notifications for review reminders.
class NotificationService {
  static const _reviewReminderId = 0;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Stream that fires when the user taps a notification.
  /// The payload string identifies which screen to open.
  static final onNotificationTap = StreamController<String>.broadcast();

  /// Initialize the notification plugin. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Handle the case where the app was launched by tapping a notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      _onTap(launchDetails.notificationResponse!);
    }

    _initialized = true;
  }

  static void _onTap(NotificationResponse response) {
    onNotificationTap.add(response.payload ?? 'review');
  }

  /// Request notification permission (iOS 10+).
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  /// Schedule a review reminder that fires [delay] from now. Each
  /// call cancels the previous one, so as long as the user keeps
  /// opening the app within [delay] they'll never see the
  /// notification. If they go inactive for longer, the last
  /// scheduled notification fires.
  static Future<void> scheduleInactivityReminder({
    Duration delay = const Duration(hours: 24),
    required int dueCount,
  }) async {
    await cancelReviewReminder();
    if (dueCount == 0) return;

    await _plugin.zonedSchedule(
      id: _reviewReminderId,
      title: 'Time to review!',
      body: '$dueCount item${dueCount == 1 ? '' : 's'} due for review',
      payload: 'review',
      scheduledDate: tz.TZDateTime.now(tz.local).add(delay),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'review_reminder',
          'Review Reminders',
          channelDescription: 'Reminds you to review when inactive',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelReviewReminder() async {
    await _plugin.cancel(id: 0);
  }

  /// Schedule a one-off local notification at [when]. Returns the id so
  /// the caller can cancel it later. Used by the AI reminder tool.
  static Future<int> scheduleOneOff({
    required String title,
    required String body,
    required DateTime when,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      payload: 'user_reminder',
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          'user_reminder',
          'Reminders',
          channelDescription: 'One-off reminders created by the AI',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    return id;
  }
}

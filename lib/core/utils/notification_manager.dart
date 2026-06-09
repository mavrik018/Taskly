import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Provider to hold the task ID from a notification tap event
final notificationTapProvider = NotifierProvider<NotificationTapNotifier, int?>(
  NotificationTapNotifier.new,
);

class NotificationTapNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? id) => state = id;
}

class NotificationManager {
  NotificationManager._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _permissionRequestedKey =
      'notifications_permission_requested';

  /// Initializes the local notification plugin and timezones
  static Future<void> init(WidgetRef ref) async {
    // 1. Initialize timezones
    tz.initializeTimeZones();
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Safe fallback to UTC timezone
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Setup initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null) {
          final id = int.tryParse(payload);
          if (id != null) {
            // Update the provider state on main thread to trigger UI deep-link
            ref.read(notificationTapProvider.notifier).set(id);
          }
        }
      },
    );

    // Check if launched from notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null) {
        final id = int.tryParse(payload);
        if (id != null) {
          ref.read(notificationTapProvider.notifier).set(id);
        }
      }
    }
  }

  /// Helper to prompt a friendly double-dialog permission flow
  static Future<bool> requestPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_permissionRequestedKey) ?? false;

    if (alreadyRequested) {
      // Permission already requested once, directly trigger native system prompt
      return await _requestNativePermissions();
    }

    // First time request: show friendly explanatory dialog first
    if (!context.mounted) return false;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          icon: Icon(Icons.notifications_active_outlined,
              color: theme.colorScheme.primary, size: 40),
          title: Text(
            'Enable Reminders?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Receive reminders so you never miss a deadline. TaskFlow sends offline push notifications to keep you on track.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Maybe Later'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );

    if (proceed == true) {
      await prefs.setBool(_permissionRequestedKey, true);
      return await _requestNativePermissions();
    }
    return false;
  }

  static Future<bool> _requestNativePermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    } else if (Platform.isIOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Schedules a zoned push notification for a specific task
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'taskflow_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for task reminders and deadlines',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
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

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDateTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: id.toString(),
    );
  }

  /// Cancels any scheduled notification for the given task ID
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }
}

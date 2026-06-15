import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
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
    _resolveLocalTimezone();

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

  /// Resolves the device's local timezone to a valid IANA name.
  /// Android may return abbreviations (e.g. "PKT") or full names that differ
  /// from IANA names. This method tries several strategies with UTC as fallback.
  static void _resolveLocalTimezone() {
    // Strategy 1: Try the raw timezone name from Dart
    try {
      final rawName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(rawName));
      return;
    } catch (_) {}

    // Strategy 2: Map common timezone abbreviations to IANA names
    try {
      final rawName = DateTime.now().timeZoneName;
      final ianaName = _timezoneAbbreviationMap[rawName];
      if (ianaName != null) {
        tz.setLocalLocation(tz.getLocation(ianaName));
        return;
      }
    } catch (_) {}

    // Strategy 3: Use the UTC offset to guess the timezone

    try {
      final offset = DateTime.now().timeZoneOffset;
      final offsetHours = offset.inHours;
      final ianaByOffset = _offsetToTimezone[offsetHours];
      if (ianaByOffset != null) {
        tz.setLocalLocation(tz.getLocation(ianaByOffset));
        return;
      }
    } catch (_) {}

    // Final fallback: UTC
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  /// Maps common timezone abbreviations to IANA timezone names
  static const Map<String, String> _timezoneAbbreviationMap = {
    'PKT': 'Asia/Karachi',
    'IST': 'Asia/Kolkata',
    'EST': 'America/New_York',
    'CST': 'America/Chicago',
    'MST': 'America/Denver',
    'PST': 'America/Los_Angeles',
    'GMT': 'Europe/London',
    'UTC': 'UTC',
    'CET': 'Europe/Paris',
    'EET': 'Europe/Athens',
    'JST': 'Asia/Tokyo',
    'CST_CN': 'Asia/Shanghai',
    'AEST': 'Australia/Sydney',
    'SGT': 'Asia/Singapore',
    'GST': 'Asia/Dubai',
    'AST': 'America/Halifax',
    'BRT': 'America/Sao_Paulo',
    'MSK': 'Europe/Moscow',
  };

  /// Maps UTC offset hours to a representative IANA timezone
  static const Map<int, String> _offsetToTimezone = {
    -12: 'Etc/GMT+12',
    -11: 'Pacific/Apia',
    -10: 'Pacific/Honolulu',
    -9: 'America/Anchorage',
    -8: 'America/Los_Angeles',
    -7: 'America/Denver',
    -6: 'America/Chicago',
    -5: 'America/New_York',
    -4: 'America/Halifax',
    -3: 'America/Sao_Paulo',
    -2: 'Etc/GMT+2',
    -1: 'Atlantic/Azores',
    0: 'Europe/London',
    1: 'Europe/Paris',
    2: 'Europe/Athens',
    3: 'Europe/Moscow',
    4: 'Asia/Dubai',
    5: 'Asia/Karachi',
    6: 'Asia/Almaty',
    7: 'Asia/Bangkok',
    8: 'Asia/Shanghai',
    9: 'Asia/Tokyo',
    10: 'Australia/Sydney',
    11: 'Pacific/Noumea',
    12: 'Pacific/Auckland',
  };

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

  /// Motivational messages shown as notification body
  static const List<String> _attentionMessages = [
    'This task needs your attention!',
    'Time to tackle this one — you\'ve got this!',
    'Don\'t let this one slip through the cracks.',
    'Action needed — stay on top of your game!',
    'This is calling your name. Get it done!',
    'Knock this task out and keep the momentum!',
    'Quick reminder — this task is waiting for you.',
    'Finish line is close. Take care of this now!',
    'Hey! This task needs a little love today.',
    'One step closer to done — handle this task!',
    'Champions don\'t procrastinate. Time to act!',
    'Deadline\'s approaching — don\'t wait too long!',
  ];

  /// Returns a random attention message
  static String _randomMessage() {
    return _attentionMessages[Random().nextInt(_attentionMessages.length)];
  }

  /// Schedules a zoned push notification for a specific task
  static Future<void> scheduleNotification({
    required int id,
    required String title,
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
      body: _randomMessage(),
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

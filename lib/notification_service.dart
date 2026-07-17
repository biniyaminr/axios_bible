import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications for the single daily reading reminder.
///
/// Every method swallows [MissingPluginException] so that unit tests (and
/// platforms without the plugin) can exercise the settings logic without
/// a real notification backend.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name.identifier));
      } catch (e) {
        // Fall back to the package default (UTC); the reminder still fires,
        // just at the wrong wall-clock time until the app is reopened.
        debugPrint('Could not resolve local timezone: $e');
      }
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permissions are requested explicitly when the user enables the
        // reminder, not at app launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  /// Asks the OS for notification permission. Returns false only when the
  /// user explicitly denied it; unknown/unsupported platforms return true so
  /// scheduling is still attempted.
  Future<bool> requestPermissions() async {
    await init();
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      final macos = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      if (macos != null) {
        final granted = await macos.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? true;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return true;
  }

  /// Schedules (or reschedules) the repeating daily reminder.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await init();
    if (!_initialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var first = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!first.isAfter(now)) {
        first = first.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: _dailyReminderId,
        title: title,
        body: body,
        scheduledDate: first,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reading reminder',
            channelDescription: 'Reminds you to do your daily Bible reading',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        // Inexact avoids the SCHEDULE_EXACT_ALARM permission dance; a daily
        // reminder does not need to-the-second accuracy.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Scheduling reminder failed: $e');
    }
  }

  Future<void> cancelDailyReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: _dailyReminderId);
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Cancelling reminder failed: $e');
    }
  }

  static const int _votdBaseId = 100;

  /// How many days of verse notifications are kept scheduled ahead.
  static const int votdDays = 7;

  /// Schedules one-shot verse notifications for the next [votdDays] days.
  ///
  /// The verse text differs per day, so a single repeating notification
  /// won't do — each day is scheduled individually, and the whole batch is
  /// refreshed on every app launch (and whenever the setting changes).
  /// `entries[i]` is the content for today + i days; a day whose time has
  /// already passed is skipped.
  Future<void> scheduleVerseOfDay({
    required int hour,
    required int minute,
    required List<({String title, String body})> entries,
  }) async {
    await init();
    if (!_initialized) return;
    try {
      await _cancelVotdIds();
      final now = tz.TZDateTime.now(tz.local);
      for (var i = 0; i < entries.length && i < votdDays; i++) {
        // Translations with data gaps can yield an empty verse — skip that
        // day rather than delivering a blank notification. entries[i] stays
        // bound to today + i days, so later days keep their own verse.
        if (entries[i].body.trim().isEmpty) continue;
        final when = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).add(Duration(days: i));
        if (!when.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          id: _votdBaseId + i,
          title: entries[i].title,
          body: entries[i].body,
          scheduledDate: when,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'verse_of_day',
              'Verse of the day',
              channelDescription: 'A daily verse from the Bible',
              importance: Importance.high,
              priority: Priority.high,
              // Expanded view shows the whole verse, not one truncated line.
              styleInformation: BigTextStyleInformation(entries[i].body),
            ),
            iOS: const DarwinNotificationDetails(),
            macOS: const DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Scheduling verse of the day failed: $e');
    }
  }

  Future<void> cancelVerseOfDay() async {
    if (!_initialized) return;
    try {
      await _cancelVotdIds();
    } on MissingPluginException {
      // Unit tests / unsupported platform.
    } catch (e) {
      debugPrint('Cancelling verse of the day failed: $e');
    }
  }

  Future<void> _cancelVotdIds() async {
    for (var i = 0; i < votdDays; i++) {
      await _plugin.cancel(id: _votdBaseId + i);
    }
  }
}

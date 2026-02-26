import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
  }

  static Future<void> scheduleReminders({int intervalHours = 1}) async {
    // Note: periodicallyShow has limited intervals (min 1 hour).
    // For specific custom intervals, we would use zonedSchedule.
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Cancel existing to avoid duplicates when changing interval
    await cancelAll();

    await _notificationsPlugin.periodicallyShow(
      0,
      'Drink Water 💧',
      'Stay hydrated! It is time for a glass of water.',
      RepeatInterval.hourly, // Defaulting to hourly for simplicity in this version
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_test_channel',
      'Test Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      99,
      'Test Notification 💧',
      'This is a test notification to verify settings.',
      notificationDetails,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}

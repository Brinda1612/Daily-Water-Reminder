import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // We try to use 'launcher_icon' which we just copied to drawable.
    // If it fails, the app will catch it in main.dart or here.
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('launcher_icon');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle notification tap
        },
      );
    } catch (e) {
      print('Notification initialization failed with launcher_icon, trying fallback: $e');
      // Fallback to default flutter icon if launcher_icon is still problematic
      try {
        const AndroidInitializationSettings fallbackSettings =
            AndroidInitializationSettings('ic_launcher');
        const InitializationSettings initSettings = InitializationSettings(
          android: fallbackSettings,
          iOS: DarwinInitializationSettings(),
        );
        await _notificationsPlugin.initialize(initSettings);
      } catch (fallbackError) {
        print('Notification initialization failed completely: $fallbackError');
      }
    }
    tz.initializeTimeZones();
  }

  static Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    
    // For iOS
    final bool? granted = await _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return granted ?? false;
  }

  static Future<void> scheduleReminders({int? intervalMinutes, int? intervalHours}) async {
    final int minutes = intervalMinutes ?? (intervalHours ?? 1) * 60;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'launcher_icon',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Cancel existing to avoid duplicates
    await cancelAll();

    // For better testing experience, if interval is short (<= 30 mins), schedule multiple
    int instances = minutes <= 30 ? 6 : 1; 

    for (int i = 1; i <= instances; i++) {
      await _notificationsPlugin.zonedSchedule(
        i,
        'Drink Water 💧',
        'Stay hydrated! It is time for a glass of water.',
        tz.TZDateTime.now(tz.local).add(Duration(minutes: i * minutes)),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    
    print('Scheduled notifications every $minutes minutes ($instances instances)');
  }

  static Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_test_channel',
      'Test Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
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

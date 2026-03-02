import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const MethodChannel _settingsChannel = MethodChannel('com.example.smart_task/settings');
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
      
      // Ensure channel is created during initialization
      await _createChannel();
      print('Notification service initialized and channel created.');
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
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Local timezone set to: $timeZoneName');
    } catch (e) {
      print('Could not get local timezone, falling back: $e');
    }
  }

  static Future<Map<String, bool>> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool notificationsGranted = false;
    bool exactAlarmGranted = true; // Assume true for older Android
    
    if (androidImplementation != null) {
      notificationsGranted = await androidImplementation.requestNotificationsPermission() ?? false;
      
      // On Android 12+, we need to check if exact alarm permission is actually granted
      try {
        final bool? canSchedule = await _settingsChannel.invokeMethod<bool>('canScheduleExactAlarms');
        exactAlarmGranted = canSchedule ?? true;
        print('DEBUG: Exact Alarm permission status: $exactAlarmGranted');
      } catch (e) {
        print('Error checking exact alarm status: $e');
      }
    }
    
    // For iOS
    final bool? iosGranted = await _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return {
      'notifications': notificationsGranted || (iosGranted ?? false),
      'exactAlarm': exactAlarmGranted,
    };
  }

  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _settingsChannel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      print('Error opening battery settings: $e');
    }
  }

  static Future<void> openExactAlarmSettings() async {
    try {
      await _settingsChannel.invokeMethod('openExactAlarmSettings');
    } catch (e) {
      print('Error opening exact alarm settings: $e');
    }
  }

  static Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'water_reminder_channel_v3',
      'Water Reminders (Critical)',
      description: 'Priority reminders to drink water',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  static Future<void> scheduleReminders({int? intervalMinutes, int? intervalHours}) async {
    final int minutes = intervalMinutes ?? (intervalHours ?? 1) * 60;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_channel_v3',
      'Water Reminders (Critical)',
      channelDescription: 'Priority reminders to drink water',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'Time to drink water',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Cancel existing to avoid duplicates
    await cancelAll();

    // Schedule 100 instances to cover more time
    const int instances = 100; 
    int scheduledCount = 0;

    for (int i = 1; i <= instances; i++) {
      try {
        final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: i * minutes));
        if (i == 1) {
          print('DEBUG: First notification scheduled for: $scheduledTime');
          print('DEBUG: Device local time: ${DateTime.now()}');
          print('DEBUG: TZ local time: ${tz.TZDateTime.now(tz.local)}');
          print('DEBUG: TZ local location: ${tz.local.name}');
        }
        await _notificationsPlugin.zonedSchedule(
          i,
          'Drink Water 💧',
          'Stay hydrated! It is time for a glass of water.',
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        scheduledCount++;
      } catch (e) {
        print('Failed to schedule notification #$i: $e');
        if (i == 1) rethrow;
      }
    }
    
    print('Scheduled $scheduledCount notifications every $minutes minutes using exactAllowWhileIdle mode');
  }

  static Future<void> showTestAlarm() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'water_reminder_channel_v3',
      'Water Reminders (Critical)',
      channelDescription: 'Priority reminders to drink water',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    print('DEBUG: Test alarm scheduled for: $scheduledTime (in 10 seconds)');

    await _notificationsPlugin.zonedSchedule(
      999,
      'Test Alarm 🔔',
      'This is a 10-second test alarm to verify background work.',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<int> getPendingNotificationCount() async {
    final List<PendingNotificationRequest> pending = 
        await _notificationsPlugin.pendingNotificationRequests();
    return pending.length;
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

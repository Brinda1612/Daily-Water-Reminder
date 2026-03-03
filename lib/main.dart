import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/services/notification_service.dart';
import 'features/water/bloc/water_bloc.dart';
import 'features/water/bloc/water_event.dart';
import 'app.dart';
import 'features/water/model/water_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(WaterModelAdapter());
    
    // Initialize Services
    await NotificationService.init();
    final permissions = await NotificationService.requestPermissions();
    debugPrint('Permissions status: $permissions');
    
    try {
      final settingsBox = await Hive.openBox('settings_box');
      int minutes = settingsBox.get('reminderMinutes', defaultValue: -1) as int;
      if (minutes == -1) {
        // Default to 2 hours (120 minutes)
        minutes = 120;
      }
      await NotificationService.scheduleReminders(intervalMinutes: minutes);
    } catch (e) {
      debugPrint('Failed to schedule reminders: $e');
    }

    runApp(
      BlocProvider(
        create: (context) => WaterBloc()..add(InitWater()),
        child: const WaterReminderApp(),
      ),
    );
  } catch (e) {
    debugPrint('Critical initialization error: $e');
    // Run minimal app or show error screen if needed
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e\nPlease restart the app.'),
          ),
        ),
      ),
    );
  }
}

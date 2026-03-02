import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_event.dart';
import '../bloc/water_state.dart';
import '../../../core/services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterBloc, WaterState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Goal Settings'),
            _buildGoalTile(context, state),
            const Divider(),
            _buildSectionHeader('Personal Info'),
            _buildStatTile(context, 'Weight', '${state.weight} kg', Icons.monitor_weight_outlined),
            _buildStatTile(context, 'Height', '${state.height} cm', Icons.height_outlined),
            const Divider(),
            _buildSectionHeader('Notifications'),
            _buildNotificationTile(context, state),
            FutureBuilder<Map<String, bool>>(
              future: NotificationService.requestPermissions(),
              builder: (context, snapshot) {
                final status = snapshot.data;
                final notificationsOn = status?['notifications'] ?? false;
                final exactAlarmOn = status?['exactAlarm'] ?? false;
                
                return Column(
                  children: [
                    FutureBuilder<int>(
                      future: NotificationService.getPendingNotificationCount(),
                      builder: (context, countSnapshot) {
                        final count = countSnapshot.data ?? 0;
                        return ListTile(
                          leading: Icon(
                            count > 0 ? Icons.schedule_outlined : Icons.timer_off_outlined,
                            color: count > 0 ? Colors.green : Colors.red,
                          ),
                          title: const Text('Pending Reminders'),
                          subtitle: Text('$count notifications currently queued'),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              final currentMinutes = state.reminderMinutes;
                              await NotificationService.scheduleReminders(intervalMinutes: currentMinutes);
                              // Force rebuild to update count
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        );
                      }
                    ),
                    ListTile(
                      leading: Icon(
                        exactAlarmOn ? Icons.alarm_on_outlined : Icons.alarm_add_outlined,
                        color: exactAlarmOn ? Colors.green : Colors.orange,
                      ),
                      title: const Text('Exact Alarm Permission'),
                      subtitle: Text(exactAlarmOn ? 'Status: Granted (Precise reminders)' : 'Status: Required (For timely reminders)'),
                      trailing: exactAlarmOn ? const Icon(Icons.check_circle_outline, color: Colors.green) : TextButton(
                        onPressed: () => NotificationService.openExactAlarmSettings(),
                        child: const Text('GRANT'),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSettingsButton(
                      'Battery Optimization',
                      'Avoid background kills (Recommended)',
                      Icons.battery_charging_full_outlined,
                      () => NotificationService.openBatteryOptimizationSettings(),
                    ),
                    _buildSettingsButton(
                      'Test Alarm (10s)',
                      'Schedule alarm for 10 seconds from now',
                      Icons.timer_outlined,
                      () async {
                        await NotificationService.showTestAlarm();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test alarm scheduled for 10 seconds! Put app in background now.')),
                        );
                        // Force rebuild to update count
                        (context as Element).markNeedsBuild();
                      },
                    ),
                  ],
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Test Notification'),
              subtitle: const Text('Send an immediate notification'),
              onTap: () async {
                await NotificationService.showImmediateNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent! 💧')),
                );
              },
            ),
            const Divider(),
            _buildSectionHeader('Account & Data'),
            _buildNameTile(),
            _buildClearDataTile(context),
            const Divider(),
            _buildSectionHeader('About'),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Version'),
              trailing: Text('1.0.0'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGoalTile(BuildContext context, WaterState state) {
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: const Text('Daily Intake Goal'),
      subtitle: Text('${state.dailyGoal} ml'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showGoalDialog(context, state),
    );
  }

  void _showGoalDialog(BuildContext context, WaterState state) {
    final controller = TextEditingController(text: state.dailyGoal.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Daily Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter goal in ml',
            suffixText: 'ml',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                context.read<WaterBloc>().add(UpdateDailyGoal(goal));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WaterState state) {
    String frequencyText;
    if (state.reminderMinutes < 60) {
      frequencyText = 'Notify every ${state.reminderMinutes} minutes';
    } else {
      final hours = state.reminderMinutes / 60;
      frequencyText = 'Notify every ${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} hour${hours == 1 ? '' : 's'}';
    }

    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('Reminder Frequency'),
      subtitle: Text(frequencyText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFrequencyDialog(context, state),
    );
  }

  void _showFrequencyDialog(BuildContext context, WaterState state) {
    final intervals = [
      {'label': 'Every 1 minute (Test)', 'value': 1},
      {'label': 'Every 15 minutes', 'value': 15},
      {'label': 'Every 30 minutes', 'value': 30},
      {'label': 'Every 45 minutes', 'value': 45},
      {'label': 'Every 1 hour', 'value': 60},
      {'label': 'Every 1.5 hours', 'value': 90},
      {'label': 'Every 2 hours', 'value': 120},
      {'label': 'Every 3 hours', 'value': 180},
      {'label': 'Every 4 hours', 'value': 240},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reminder Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text(interval['label'] as String),
              value: interval['value'] as int,
              groupValue: state.reminderMinutes,
              onChanged: (val) {
                if (val != null) {
                  context.read<WaterBloc>().add(SetReminderInterval(val));
                  Navigator.pop(dialogContext);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: () => _showStatDialog(context, title),
    );
  }

  void _showStatDialog(BuildContext context, String title) {
    final state = context.read<WaterBloc>().state;
    final isWeight = title == 'Weight';
    final controller = TextEditingController(
      text: (isWeight ? state.weight : state.height).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            suffixText: isWeight ? 'kg' : 'cm',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                final weight = isWeight ? val : state.weight;
                final height = isWeight ? state.height : val;
                context.read<WaterBloc>().add(CompleteOnboarding(weight: weight, height: height));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameTile() {
    return const ListTile(
      leading: Icon(Icons.person_outline),
      title: Text('User Name'),
      subtitle: Text('Guest User'),
      trailing: Icon(Icons.edit, size: 20),
    );
  }

  Widget _buildClearDataTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
      title: const Text('Clear All Data', style: TextStyle(color: Colors.redAccent)),
      onTap: () => _showClearConfirmation(context),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will delete all your water intake history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              context.read<WaterBloc>().add(ClearHistory());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('History cleared successfully')),
              );
            },
            child: const Text('CLEAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: onTap,
    );
  }
}

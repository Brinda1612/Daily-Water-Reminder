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
    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('Reminder Frequency'),
      subtitle: Text('Notify every ${state.reminderHours} hour${state.reminderHours > 1 ? 's' : ''}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFrequencyDialog(context, state),
    );
  }

  void _showFrequencyDialog(BuildContext context, WaterState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reminder Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 6].map((hour) {
            return RadioListTile<int>(
              title: Text('Every $hour hour${hour > 1 ? 's' : ''}'),
              value: hour,
              groupValue: state.reminderHours,
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
}

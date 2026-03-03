import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_task/l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(l10n.goalSettings),
            _buildGoalTile(context, state),
            const Divider(),
            _buildSectionHeader(l10n.personalInfo),
            _buildStatTile(context, l10n.weight, '${state.weight} ${l10n.kg}', Icons.monitor_weight_outlined),
            _buildStatTile(context, l10n.height, '${state.height} ${l10n.cm}', Icons.height_outlined),
            const Divider(),
            _buildSectionHeader(l10n.language),
            _buildLanguageTile(context, state),
            const Divider(),
            _buildSectionHeader(l10n.notifications),
            _buildNotificationTile(context, state),
            FutureBuilder<Map<String, bool>>(
              future: NotificationService.requestPermissions(),
              builder: (context, snapshot) {
                final status = snapshot.data;
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
                          subtitle: Text('$count notifications currently queued. If 0, tap refresh.'),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            onPressed: () async {
                              final currentMinutes = state.reminderMinutes;
                              await NotificationService.scheduleReminders(intervalMinutes: currentMinutes);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminders rescheduled!')),
                              );
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
                      title: Text(l10n.exactAlarmPermission),
                      subtitle: Text(exactAlarmOn ? l10n.statusGranted : l10n.statusRequired),
                      trailing: exactAlarmOn ? const Icon(Icons.check_circle_outline, color: Colors.green) : TextButton(
                        onPressed: () async {
                          final success = await NotificationService.openExactAlarmSettings();
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open settings. Please check your app settings manually.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(l10n.grant),
                      ),
                    ),
                    const Divider(height: 1),
                    _buildSettingsButton(
                      l10n.batteryOptimization,
                      'Avoid background kills (Recommended)',
                      Icons.battery_charging_full_outlined,
                      () async {
                        final success = await NotificationService.openBatteryOptimizationSettings();
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open settings. Please check your app settings manually.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    _buildSettingsButton(
                      l10n.testAlarm,
                      l10n.testAlarmSub,
                      Icons.timer_outlined,
                      () async {
                        await NotificationService.showTestAlarm();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.testAlarmScheduled)),
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
              title: Text(l10n.testNotification),
              subtitle: const Text('Send an immediate notification'),
              onTap: () async {
                await NotificationService.showImmediateNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Test notification sent! 💧')),
                );
              },
            ),
            const Divider(),
            _buildSectionHeader(l10n.accountData),
            _buildNameTile(),
            _buildClearDataTile(context),
            const Divider(),
            _buildSectionHeader(l10n.about),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.version),
              trailing: const Text('1.0.0'),
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
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(l10n.dailyGoal),
      subtitle: Text('${state.dailyGoal} ${l10n.ml}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showGoalDialog(context, state),
    );
  }

  void _showGoalDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: state.dailyGoal.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editGoal),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter goal in ml',
            suffixText: l10n.ml,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                context.read<WaterBloc>().add(UpdateDailyGoal(goal));
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    String frequencyText;
    if (state.reminderMinutes < 60) {
      frequencyText = 'Notify every ${state.reminderMinutes} minutes';
    } else {
      final hours = state.reminderMinutes / 60;
      frequencyText = 'Notify every ${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} hour${hours == 1 ? '' : 's'}';
    }

    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: Text(l10n.reminderFrequency),
      subtitle: Text(frequencyText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showFrequencyDialog(context, state),
    );
  }

  void _showFrequencyDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.reminderFrequency),
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
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<WaterBloc>().state;
    final isWeight = title == l10n.weight;
    final controller = TextEditingController(
      text: (isWeight ? state.weight : state.height).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${l10n.save} $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            suffixText: isWeight ? l10n.kg : l10n.cm,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
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
            child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
      title: Text(l10n.clearData, style: const TextStyle(color: Colors.redAccent)),
      onTap: () => _showClearConfirmation(context),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearDataTitle),
        content: Text(l10n.clearDataSub),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.read<WaterBloc>().add(ClearHistory());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.historyCleared)),
              );
            },
            child: Text(l10n.clearData, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(String title, String subtitle, IconData icon, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLanguageTile(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    String languageName = l10n.english;
    if (state.locale == 'hi') languageName = l10n.hindi;
    if (state.locale == 'gu') languageName = l10n.gujarati;

    return ListTile(
      leading: const Icon(Icons.language_outlined),
      title: Text(l10n.language),
      subtitle: Text(languageName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, state),
    );
  }

  void _showLanguageDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final languages = [
      {'label': l10n.english, 'value': 'en'},
      {'label': l10n.hindi, 'value': 'hi'},
      {'label': l10n.gujarati, 'value': 'gu'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return RadioListTile<String>(
              title: Text(lang['label'] as String),
              value: lang['value'] as String,
              groupValue: state.locale,
              onChanged: (val) {
                if (val != null) {
                  context.read<WaterBloc>().add(ChangeLanguage(val));
                  Navigator.pop(dialogContext);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

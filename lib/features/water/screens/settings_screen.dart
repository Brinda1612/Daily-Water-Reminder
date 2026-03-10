import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app.dart';
import '../../../l10n/app_localizations.dart';
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
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settings,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your water reminder experience',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSection(context, l10n.goalSettings, [
                    _buildGoalCard(context, state),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, l10n.notifications, [
                    _buildNotificationCard(context, state),
                    _buildPermissionCard(context),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, l10n.personalInfo, [
                    _buildPersonalInfoCard(context, state),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, l10n.language, [
                    _buildLanguageCard(context, state),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, l10n.accountData, [
                    _buildDataCard(context),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection(context, l10n.about, [
                    _buildAboutCard(context),
                  ]),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: WaterReminderApp.primaryWaterDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final displayGoal = state.dailyGoal > 0 ? state.dailyGoal : 3000;
    return _buildSettingsCard(
      context,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.flag_outlined, color: Colors.white),
        ),
        title: Text(l10n.dailyGoal),
        subtitle: Text(state.dailyGoal > 0 ? '$displayGoal ${l10n.ml}' : l10n.notSet),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _showGoalDialog(context, state),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    String frequencyText;
    if (state.reminderMinutes < 60) {
      frequencyText = 'Every ${state.reminderMinutes} min';
    } else {
      final hours = state.reminderMinutes / 60;
      frequencyText = 'Every ${hours.toStringAsFixed(hours.truncateToDouble() == hours ? 0 : 1)} hour${hours == 1 ? '' : 's'}';
    }

    return _buildSettingsCard(
      context,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        title: Text(l10n.reminderFrequency),
        subtitle: Text(frequencyText),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _showFrequencyDialog(context, state),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSettingsCard(
      context,
      child: FutureBuilder<Map<String, bool>>(
        future: NotificationService.requestPermissions(),
        builder: (context, snapshot) {
          final status = snapshot.data;
          final exactAlarmOn = status?['exactAlarm'] ?? false;
          final notificationsOn = status?['notifications'] ?? false;

          return Column(
            children: [
              _buildPermissionItem(
                context,
                icon: Icons.alarm,
                title: l10n.exactAlarmPermission,
                isGranted: exactAlarmOn,
                onTap: () async {
                  final success = await NotificationService.openExactAlarmSettings();
                  if (!success) {
                    _showErrorSnackBar(context, 'Could not open settings. Please check manually.');
                  }
                },
              ),
              const Divider(height: 20),
              _buildPermissionItem(
                context,
                icon: Icons.battery_charging_full,
                title: l10n.batteryOptimization,
                subtitle: 'Prevent background kills',
                isGranted: true, // We can't check this easily
                actionLabel: 'Open',
                onTap: () async {
                  final success = await NotificationService.openBatteryOptimizationSettings();
                  if (!success) {
                    _showErrorSnackBar(context, 'Could not open settings. Please check manually.');
                  }
                },
              ),
              const Divider(height: 20),
              _buildPermissionItem(
                context,
                icon: Icons.notifications_active,
                title: 'Notification Status',
                isGranted: notificationsOn,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isGranted,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isGranted ? Colors.green : Colors.orange).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: WaterReminderApp.primaryWater.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel ?? (isGranted ? 'Granted' : 'Grant'),
                  style: TextStyle(
                    color: WaterReminderApp.primaryWaterDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Icon(
                isGranted ? Icons.check_circle : Icons.cancel,
                color: isGranted ? Colors.green : Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final displayWeight = state.weight > 0 ? state.weight : 70.0;
    final displayHeight = state.height > 0 ? state.height : 170.0;
    return _buildSettingsCard(
      context,
      child: Column(
        children: [
          _buildInfoTile(
            context,
            icon: Icons.monitor_weight_outlined,
            title: l10n.weight,
            value: state.weight > 0 ? '$displayWeight ${l10n.kg}' : l10n.notSet,
            onTap: () => _showStatDialog(context, l10n.weight, state.weight > 0 ? state.weight : 70.0, true),
          ),
          const Divider(height: 20),
          _buildInfoTile(
            context,
            icon: Icons.height_outlined,
            title: l10n.height,
            value: state.height > 0 ? '$displayHeight ${l10n.cm}' : l10n.notSet,
            onTap: () => _showStatDialog(context, l10n.height, state.height > 0 ? state.height : 170.0, false),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WaterReminderApp.primaryWater.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: WaterReminderApp.primaryWater, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    String languageName = l10n.english;
    if (state.locale == 'hi') languageName = l10n.hindi;
    if (state.locale == 'gu') languageName = l10n.gujarati;

    return _buildSettingsCard(
      context,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.language_outlined, color: Colors.white),
        ),
        title: Text(l10n.language),
        subtitle: Text(languageName),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _showLanguageDialog(context, state),
      ),
    );
  }

  Widget _buildDataCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildSettingsCard(
      context,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.red),
        ),
        title: Text(l10n.clearData, style: const TextStyle(color: Colors.red)),
        subtitle: const Text('Reset all your drinking history'),
        onTap: () => _showClearConfirmation(context),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return _buildSettingsCard(
      context,
      child: Column(
        children: [
          _buildAboutTile(
            context,
            icon: Icons.info_outline,
            title: 'Version',
            value: '1.0.0',
          ),
          const Divider(height: 20),
          _buildAboutTile(
            context,
            icon: Icons.favorite_outline,
            title: 'Made with',
            value: '❤️ for healthy living',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: WaterReminderApp.primaryWater.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: WaterReminderApp.primaryWater, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: WaterReminderApp.getGlassBox(),
      child: child,
    );
  }

  void _showGoalDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final initialGoal = state.dailyGoal > 0 ? state.dailyGoal : 3000;
    final controller = TextEditingController(text: initialGoal.toString());
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.editGoal),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter goal in ml',
            suffixText: l10n.ml,
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
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

  void _showFrequencyDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final intervals = [
      {'label': 'Every 15 minutes', 'value': 15},
      {'label': 'Every 30 minutes', 'value': 30},
      {'label': 'Every 45 minutes', 'value': 45},
      {'label': 'Every 1 hour', 'value': 60},
      {'label': 'Every 1.5 hours', 'value': 90},
      {'label': 'Every 2 hours', 'value': 120},
      {'label': 'Every 3 hours', 'value': 180},
      {'label': 'Every 4 hours', 'value': 240},
      {'label': l10n.custom, 'value': -1},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.reminderFrequency),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            final value = interval['value'] as int;
            final isSelected = state.reminderMinutes == value;
            return InkWell(
              onTap: () {
                Navigator.pop(dialogContext);
                if (value == -1) {
                  _showCustomFrequencyDialog(context, state);
                } else {
                  context.read<WaterBloc>().add(SetReminderInterval(value));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? WaterReminderApp.primaryWater.withOpacity(0.1) : null,
                  border: isSelected
                      ? Border(left: BorderSide(color: WaterReminderApp.primaryWater, width: 4))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: WaterReminderApp.primaryWater,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(interval['label'] as String)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStatDialog(BuildContext context, String title, double value, bool isWeight) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<WaterBloc>().state;
    final controller = TextEditingController(text: value.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            suffixText: isWeight ? l10n.kg : l10n.cm,
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
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

  void _showLanguageDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final languages = [
      {'label': l10n.english, 'value': 'en', 'flag': '🇬🇧'},
      {'label': l10n.hindi, 'value': 'hi', 'flag': '🇮🇳'},
      {'label': l10n.gujarati, 'value': 'gu', 'flag': '🇮🇳'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.selectLanguage),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final value = lang['value'] as String;
            final isSelected = state.locale == value;
            return InkWell(
              onTap: () {
                context.read<WaterBloc>().add(ChangeLanguage(value));
                Navigator.pop(dialogContext);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? WaterReminderApp.primaryWater.withOpacity(0.1) : null,
                  border: isSelected
                      ? Border(left: BorderSide(color: WaterReminderApp.primaryWater, width: 4))
                      : null,
                ),
                child: Row(
                  children: [
                    Text(lang['flag'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: WaterReminderApp.primaryWater,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(lang['label'] as String)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.red)),
        content: Text(l10n.clearDataSub),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<WaterBloc>().add(ClearHistory());
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.historyCleared)),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  void _showCustomFrequencyDialog(BuildContext context, WaterState state) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: state.reminderMinutes.toString());

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${l10n.custom} ${l10n.reminderFrequency}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter minutes',
            suffixText: 'min',
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                context.read<WaterBloc>().add(SetReminderInterval(minutes));
                Navigator.pop(dialogContext);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

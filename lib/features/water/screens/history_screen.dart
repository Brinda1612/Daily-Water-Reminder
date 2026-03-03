import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_task/l10n/app_localizations.dart';
import '../../../app.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_state.dart';
import '../model/water_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<WaterBloc, WaterState>(
        builder: (context, state) {
          final filteredHistory = _getFilteredHistoryWithToday(state);

          return Column(
            children: [
              _buildHeader(context),
              _buildMonthSelector(context),
              _buildStatsCards(context, filteredHistory),
              Expanded(
                child: filteredHistory.isEmpty
                    ? _buildEmptyState(context)
                    : _buildHistoryList(filteredHistory),
              ),
            ],
          );
        },
      ),
    );
  }

  // Include today's data in the history list
  List<WaterModel> _getFilteredHistoryWithToday(WaterState state) {
    final now = DateTime.now();
    final todayStr = DateFormat('MMM d, y').format(now);

    // Check if today already exists in history
    final todayExists = state.history.any((item) => item.date == todayStr);

    // Create combined list with today's data if not in history
    List<WaterModel> combined = List.from(state.history);

    if (!todayExists && state.todayIntake > 0) {
      combined.add(WaterModel(
        date: todayStr,
        intake: state.todayIntake,
        goal: state.dailyGoal,
      ));
    }

    return _filterByMonth(combined);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.intakeHistory,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: WaterReminderApp.deepWater,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your hydration journey',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WaterReminderApp.primaryWater.withOpacity(0.1),
            WaterReminderApp.primaryWaterLight.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WaterReminderApp.primaryWater.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
              });
            },
            icon: const Icon(Icons.chevron_left),
            color: WaterReminderApp.primaryWaterDark,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  months[_selectedMonth - 1],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: WaterReminderApp.deepWater,
                  ),
                ),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                if (_selectedMonth == now.month && _selectedYear == now.year) return;
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
              });
            },
            icon: const Icon(Icons.chevron_right),
            color: WaterReminderApp.primaryWaterDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, List<WaterModel> history) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalIntake = history.fold<int>(0, (sum, item) => sum + item.intake);
    final daysLogged = history.length;
    final avgIntake = daysLogged > 0 ? totalIntake ~/ daysLogged : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '$totalIntake ml',
              Icons.water_drop,
              WaterReminderApp.primaryWater,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Days',
              '$daysLogged',
              Icons.calendar_today,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Average',
              '$avgIntake ml',
              Icons.trending_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WaterReminderApp.getGlassBox(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: WaterReminderApp.deepWater,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WaterReminderApp.primaryWaterLight.withOpacity(0.2),
                  WaterReminderApp.primaryWater.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 80,
              color: WaterReminderApp.primaryWater,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No data for this month',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: WaterReminderApp.deepWater,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start drinking to track your progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<WaterModel> history) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final percent = item.intake / item.goal;
        final isGoalReached = percent >= 1.0;

        // Check if this is today
        final now = DateTime.now();
        final todayStr = DateFormat('MMM d, y').format(now);
        final isToday = item.date == todayStr;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: WaterReminderApp.getGlassBox(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildDateIndicator(item, isGoalReached, isToday),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: WaterReminderApp.deepWater,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: WaterReminderApp.primaryWater,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.intake} / ${item.goal} ml',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: WaterReminderApp.primaryWater.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percent.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isGoalReached
                                      ? [Colors.green, Colors.green.shade700]
                                      : [
                                          WaterReminderApp.primaryWaterLight,
                                          WaterReminderApp.primaryWater,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isGoalReached
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [
                              WaterReminderApp.primaryWaterLight,
                              WaterReminderApp.primaryWater,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${(percent * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateIndicator(WaterModel item, bool isGoalReached, bool isToday) {
    // Extract day from date string (format: "Jan 15, 2024")
    final parts = item.date.split(' ');
    final day = parts.length > 1 ? parts[1].replaceAll(',', '') : '';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isToday
              ? [WaterReminderApp.primaryWaterLight, WaterReminderApp.primaryWater]
              : isGoalReached
                  ? [Colors.green.shade400, Colors.green.shade600]
                  : [Colors.blue.shade300, Colors.blue.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isToday ? WaterReminderApp.primaryWater : isGoalReached ? Colors.green : Colors.blue).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<WaterModel> _filterByMonth(List<WaterModel> history) {
    return history.where((item) {
      final dateStr = item.date;
      try {
        final parts = dateStr.split(' ');
        if (parts.length >= 3) {
          final monthStr = parts[0];
          final yearStr = parts[2];

          final months = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
          };

          final itemMonth = months[monthStr];
          final itemYear = int.tryParse(yearStr);

          return itemMonth == _selectedMonth && itemYear == _selectedYear;
        }
      } catch (e) {
        return false;
      }
      return false;
    }).toList();
  }
}

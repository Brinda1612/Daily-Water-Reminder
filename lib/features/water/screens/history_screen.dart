import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/water_bloc.dart';
import '../bloc/water_state.dart';
import '../model/water_model.dart';

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

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildStreakCards(context, state),
                const SizedBox(height: 16),
                _buildWeeklyChart(context, state),
                const SizedBox(height: 16),
                _buildMonthSelector(context),
                _buildStatsCards(context, filteredHistory),
                filteredHistory.isEmpty
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: _buildEmptyState(context),
                      )
                    : _buildHistoryList(filteredHistory),
              ],
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
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

  Widget _buildStreakCards(BuildContext context, WaterState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStreakCard(
              context,
              'Current Streak',
              '${state.currentStreak} ${state.currentStreak == 1 ? 'day' : 'days'}',
              Icons.local_fire_department,
              state.currentStreak > 0 ? Colors.orange : Colors.grey,
              state.currentStreak > 0,
              _getStreakMessage(state.currentStreak),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStreakCard(
              context,
              'Best Streak',
              '${state.longestStreak} ${state.longestStreak == 1 ? 'day' : 'days'}',
              Icons.emoji_events,
              state.longestStreak > 0 ? Colors.amber : Colors.grey,
              state.longestStreak > 0,
              state.longestStreak > 5 ? 'Amazing!' : 'Keep going!',
            ),
          ),
        ],
      ),
    );
  }

  String _getStreakMessage(int streak) {
    if (streak == 0) return 'Start today!';
    if (streak < 3) return 'Good start!';
    if (streak < 7) return 'Keep going!';
    if (streak < 14) return 'On fire! 🔥';
    if (streak < 30) return 'Unstoppable!';
    return 'Legend! 🏆';
  }

  Widget _buildStreakCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isActive,
    String message,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              )
            : null,
        color: isActive ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive ? color : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? WaterReminderApp.deepWater : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isActive ? color : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? color.withOpacity(0.8) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, WaterState state) {
    if (state.weeklyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: WaterReminderApp.getGlassBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: WaterReminderApp.deepWater,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: WaterReminderApp.primaryWater.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: WaterReminderApp.primaryWater,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Goal Progress',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: WaterReminderApp.primaryWaterDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.2,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < state.weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.weeklyData[index].day.substring(0, 1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: WaterReminderApp.deepWater,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: List.generate(
                  state.weeklyData.length,
                  (index) {
                    final data = state.weeklyData[index];
                    final isToday = data.day == 'Today';

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.percentage.clamp(0.0, 1.0),
                          color: data.percentage >= 1.0
                              ? Colors.green
                              : isToday
                                  ? WaterReminderApp.primaryWater
                                  : WaterReminderApp.primaryWater.withOpacity(0.7),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: data.percentage >= 1.0
                                ? [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                  ]
                                : isToday
                                    ? [
                                        WaterReminderApp.primaryWaterLight,
                                        WaterReminderApp.primaryWater,
                                      ]
                                    : [
                                        WaterReminderApp.primaryWater.withOpacity(0.5),
                                        WaterReminderApp.primaryWater.withOpacity(0.8),
                                      ],
                          ),
                          width: 24,
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isToday ? WaterReminderApp.primaryWaterDark : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('0%', Colors.grey[400]!),
              const SizedBox(width: 16),
              _buildChartLegend('50%', WaterReminderApp.primaryWater.withOpacity(0.7)),
              const SizedBox(width: 16),
              _buildChartLegend('100%', Colors.green),
              const SizedBox(width: 16),
              _buildChartLegend('Today', WaterReminderApp.primaryWater, isDashed: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                          Expanded(
                            child: Text(
                              item.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: WaterReminderApp.deepWater,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          ]
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

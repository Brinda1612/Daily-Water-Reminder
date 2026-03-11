import 'package:equatable/equatable.dart';
import '../model/water_model.dart';

class WaterState extends Equatable {
  final int todayIntake;
  final int dailyGoal;
  final int selectedCupSize;
  final int reminderMinutes;
  final double weight; // in kg
  final double height; // in cm
  final bool onboardingCompleted;
  final List<WaterModel> history;
  final String locale;
  final List<int> customCups;
  final int currentStreak;
  final int longestStreak;
  final List<WeeklyData> weeklyData;

  const WaterState({
    this.todayIntake = 0,
    this.dailyGoal = 0,
    this.selectedCupSize = 200,
    this.reminderMinutes = 120,
    this.weight = 0,
    this.height = 0,
    this.onboardingCompleted = false,
    this.history = const [],
    this.locale = 'en',
    this.customCups = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weeklyData = const [],
  });

  double get progress => dailyGoal > 0 ? todayIntake / dailyGoal : 0.0;

  WaterState copyWith({
    int? todayIntake,
    int? dailyGoal,
    int? selectedCupSize,
    int? reminderMinutes,
    double? weight,
    double? height,
    bool? onboardingCompleted,
    List<WaterModel>? history,
    String? locale,
    List<int>? customCups,
    int? currentStreak,
    int? longestStreak,
    List<WeeklyData>? weeklyData,
  }) {
    return WaterState(
      todayIntake: todayIntake ?? this.todayIntake,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      selectedCupSize: selectedCupSize ?? this.selectedCupSize,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      history: history ?? this.history,
      locale: locale ?? this.locale,
      customCups: customCups ?? this.customCups,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      weeklyData: weeklyData ?? this.weeklyData,
    );
  }

  @override
  List<Object?> get props => [
        todayIntake,
        dailyGoal,
        selectedCupSize,
        reminderMinutes,
        weight,
        height,
        onboardingCompleted,
        history,
        locale,
        customCups,
        currentStreak,
        longestStreak,
        weeklyData,
      ];
}

class WeeklyData extends Equatable {
  final String day;
  final int intake;
  final int goal;
  final double percentage;

  const WeeklyData({
    required this.day,
    required this.intake,
    required this.goal,
    required this.percentage,
  });

  @override
  List<Object?> get props => [day, intake, goal, percentage];
}

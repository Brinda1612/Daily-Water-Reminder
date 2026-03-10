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
      ];
}

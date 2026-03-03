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

  const WaterState({
    this.todayIntake = 0,
    this.dailyGoal = 3000,
    this.selectedCupSize = 200,
    this.reminderMinutes = 120,
    this.weight = 0,
    this.height = 0,
    this.onboardingCompleted = false,
    this.history = const [],
    this.locale = 'en',
  });

  double get progress => todayIntake / dailyGoal;

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
      ];
}

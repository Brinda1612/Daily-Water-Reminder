import 'package:equatable/equatable.dart';
import '../model/water_model.dart';

class WaterState extends Equatable {
  final int todayIntake;
  final int dailyGoal;
  final int selectedCupSize;
  final int reminderHours;
  final double weight; // in kg
  final double height; // in cm
  final bool onboardingCompleted;
  final List<WaterModel> history;

  const WaterState({
    this.todayIntake = 0,
    this.dailyGoal = 3000,
    this.selectedCupSize = 200,
    this.reminderHours = 1,
    this.weight = 0,
    this.height = 0,
    this.onboardingCompleted = false,
    this.history = const [],
  });

  double get progress => todayIntake / dailyGoal;

  WaterState copyWith({
    int? todayIntake,
    int? dailyGoal,
    int? selectedCupSize,
    int? reminderHours,
    double? weight,
    double? height,
    bool? onboardingCompleted,
    List<WaterModel>? history,
  }) {
    return WaterState(
      todayIntake: todayIntake ?? this.todayIntake,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      selectedCupSize: selectedCupSize ?? this.selectedCupSize,
      reminderHours: reminderHours ?? this.reminderHours,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        todayIntake,
        dailyGoal,
        selectedCupSize,
        reminderHours,
        weight,
        height,
        onboardingCompleted,
        history,
      ];
}

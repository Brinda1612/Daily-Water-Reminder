import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../model/water_model.dart';
import 'water_event.dart';
import 'water_state.dart';

class WaterBloc extends Bloc<WaterEvent, WaterState> {
  static const String boxName = 'water_box';
  static const String settingsBoxName = 'settings_box';

  WaterBloc() : super(const WaterState()) {
    on<InitWater>(_onInit);
    on<AddWater>(_onAddWater);
    on<SetCupSize>(_onSetCupSize);
    on<UpdateDailyGoal>(_onUpdateDailyGoal);
    on<ClearHistory>(_onClearHistory);
    on<SetReminderInterval>(_onSetReminderInterval);
    on<CompleteOnboarding>(_onCompleteOnboarding);
    on<ResetWater>(_onResetToday);
  }

  Future<void> _onInit(InitWater event, Emitter<WaterState> emit) async {
    await Hive.openBox(settingsBoxName);
    final settingsBox = Hive.box(settingsBoxName);
    
    final weight = settingsBox.get('weight', defaultValue: 0.0) as double;
    final height = settingsBox.get('height', defaultValue: 0.0) as double;
    final onboardingCompleted = settingsBox.get('onboardingCompleted', defaultValue: false) as bool;
    final reminderHours = settingsBox.get('reminderHours', defaultValue: 1) as int;

    final box = await Hive.openBox<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = box.get(today);

    // Initial goal calculation if stats exist but goal not set
    int goal = settingsBox.get('dailyGoal', defaultValue: 3000) as int;
    if (onboardingCompleted && weight > 0) {
       // Calculation: weight * 35 (standard recommended intake)
       goal = (weight * 35).round();
    }

    int intake = 0;
    if (data != null) {
      intake = data.intake;
      goal = data.goal;
    } else {
      final newEntry = WaterModel(date: today, intake: 0, goal: goal);
      await box.put(today, newEntry);
    }

    final history = box.values.toList();
    history.sort((a, b) => b.date.compareTo(a.date));

    emit(state.copyWith(
      todayIntake: intake,
      dailyGoal: goal,
      weight: weight,
      height: height,
      onboardingCompleted: onboardingCompleted,
      reminderHours: reminderHours,
      history: history,
    ));
  }

  Future<void> _onAddWater(AddWater event, Emitter<WaterState> emit) async {
    final addAmount = event.amount ?? state.selectedCupSize;
    final newIntake = state.todayIntake + addAmount;
    
    final box = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final data = box.get(today) ?? WaterModel(date: today, intake: 0, goal: state.dailyGoal);
    data.intake = newIntake;
    await box.put(today, data);
    
    final history = box.values.toList();
    history.sort((a, b) => b.date.compareTo(a.date));

    emit(state.copyWith(
      todayIntake: newIntake,
      history: history,
    ));
  }

  void _onSetCupSize(SetCupSize event, Emitter<WaterState> emit) {
    emit(state.copyWith(selectedCupSize: event.size));
  }

  Future<void> _onUpdateDailyGoal(UpdateDailyGoal event, Emitter<WaterState> emit) async {
    final box = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final data = box.get(today) ?? WaterModel(date: today, intake: state.todayIntake, goal: event.goal);
    data.goal = event.goal;
    await box.put(today, data);

    emit(state.copyWith(dailyGoal: event.goal));
  }

  Future<void> _onClearHistory(ClearHistory event, Emitter<WaterState> emit) async {
    final box = Hive.box<WaterModel>(boxName);
    await box.clear();
    
    // Re-initialize today's entry after clearing
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await box.put(today, WaterModel(date: today, intake: 0, goal: state.dailyGoal));

    emit(state.copyWith(
      todayIntake: 0,
      history: [box.get(today)!],
    ));
  }

  Future<void> _onSetReminderInterval(SetReminderInterval event, Emitter<WaterState> emit) async {
    final settingsBox = Hive.box(settingsBoxName);
    await settingsBox.put('reminderHours', event.hours);
    await NotificationService.scheduleReminders(intervalHours: event.hours);
    emit(state.copyWith(reminderHours: event.hours));
  }

  Future<void> _onCompleteOnboarding(CompleteOnboarding event, Emitter<WaterState> emit) async {
    final settingsBox = Hive.box(settingsBoxName);
    final calculatedGoal = (event.weight * 35).round();

    await settingsBox.put('weight', event.weight);
    await settingsBox.put('height', event.height);
    await settingsBox.put('onboardingCompleted', true);
    await settingsBox.put('dailyGoal', calculatedGoal);

    // Update today's entry in water_box if it exists
    final waterBox = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = waterBox.get(today);
    if (data != null) {
      data.goal = calculatedGoal;
      await waterBox.put(today, data);
    }

    emit(state.copyWith(
      weight: event.weight,
      height: event.height,
      onboardingCompleted: true,
      dailyGoal: calculatedGoal,
    ));
  }

  Future<void> _onResetToday(ResetWater event, Emitter<WaterState> emit) async {
    const newIntake = 0;
    final box = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final data = box.get(today);
    if (data != null) {
      data.intake = newIntake;
      await box.put(today, data);
    }
    
    final history = box.values.toList();
    history.sort((a, b) => b.date.compareTo(a.date));

    emit(state.copyWith(
      todayIntake: newIntake,
      history: history,
    ));
  }
}

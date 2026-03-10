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
    on<ChangeLanguage>(_onChangeLanguage);
    on<DeleteCustomCup>(_onDeleteCustomCup);
  }

  Future<void> _onInit(InitWater event, Emitter<WaterState> emit) async {
    await Hive.openBox(settingsBoxName);
    final settingsBox = Hive.box(settingsBoxName);

    final weight = settingsBox.get('weight', defaultValue: 0.0) as double;
    final height = settingsBox.get('height', defaultValue: 0.0) as double;
    final onboardingCompleted = settingsBox.get('onboardingCompleted', defaultValue: false) as bool;
    final locale = settingsBox.get('locale', defaultValue: 'en') as String;
    final selectedCupSize = settingsBox.get('selectedCupSize', defaultValue: 200) as int;
    final customCupsList = settingsBox.get('customCups', defaultValue: <int>[]) as List;
    final customCups = customCupsList.cast<int>();

    // Migration: Check for reminderHours and convert to minutes if reminderMinutes doesn't exist
    int reminderMinutes = settingsBox.get('reminderMinutes', defaultValue: -1) as int;
    if (reminderMinutes == -1) {
      final oldHours = settingsBox.get('reminderHours', defaultValue: 1) as int;
      reminderMinutes = oldHours * 60;
      await settingsBox.put('reminderMinutes', reminderMinutes);
    }

    final box = await Hive.openBox<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = box.get(today);

    // Initial goal calculation if stats exist but goal not set
    // Initial goal calculation if stats exist but goal not set
    int goal = settingsBox.get('dailyGoal', defaultValue: 0) as int;
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
      reminderMinutes: reminderMinutes,
      history: history,
      locale: locale,
      selectedCupSize: selectedCupSize,
      customCups: customCups,
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

  Future<void> _onSetCupSize(SetCupSize event, Emitter<WaterState> emit) async {
    final settingsBox = Hive.box(settingsBoxName);
    await settingsBox.put('selectedCupSize', event.size);
    
    final standardSizes = [100, 125, 150, 175, 200, 250, 300, 400];
    List<int> updatedCustomCups = List.from(state.customCups);
    
    if (!standardSizes.contains(event.size) && !updatedCustomCups.contains(event.size)) {
      updatedCustomCups.add(event.size);
      updatedCustomCups.sort();
      await settingsBox.put('customCups', updatedCustomCups);
    }
    
    emit(state.copyWith(
      selectedCupSize: event.size,
      customCups: updatedCustomCups,
    ));
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
    await settingsBox.put('reminderMinutes', event.minutes);
    try {
      await NotificationService.scheduleReminders(intervalMinutes: event.minutes);
    } catch (e) {
      print('CRITICAL: Error scheduling reminders in WaterBloc: $e');
      // In a real app, we might add an error state to the BLoC to show a SnackBar
    }
    emit(state.copyWith(reminderMinutes: event.minutes));
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
  
  Future<void> _onChangeLanguage(ChangeLanguage event, Emitter<WaterState> emit) async {
    final settingsBox = Hive.box(settingsBoxName);
    await settingsBox.put('locale', event.locale);
    emit(state.copyWith(locale: event.locale));
  }

  Future<void> _onDeleteCustomCup(DeleteCustomCup event, Emitter<WaterState> emit) async {
    final settingsBox = Hive.box(settingsBoxName);
    List<int> updatedCustomCups = List.from(state.customCups);
    updatedCustomCups.remove(event.size);
    await settingsBox.put('customCups', updatedCustomCups);
    
    int newSelectedSize = state.selectedCupSize;
    if (newSelectedSize == event.size) {
      newSelectedSize = 200; // Reset to default if deleted cup was selected
      await settingsBox.put('selectedCupSize', newSelectedSize);
    }
    
    emit(state.copyWith(
      customCups: updatedCustomCups,
      selectedCupSize: newSelectedSize,
    ));
  }
}

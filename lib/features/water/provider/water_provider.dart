import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../model/water_model.dart';

class WaterProvider extends ChangeNotifier {
  static const String boxName = 'water_box';
  
  int _todayIntake = 0;
  int _dailyGoal = 3000;
  int _selectedCupSize = 200; // Default cup size
  List<WaterModel> _history = [];

  int get todayIntake => _todayIntake;
  int get dailyGoal => _dailyGoal;
  int get selectedCupSize => _selectedCupSize;
  List<WaterModel> get history => _history;

  void setSelectedCupSize(int size) {
    _selectedCupSize = size;
    notifyListeners();
  }

  double get progress => _todayIntake / _dailyGoal;

  Future<void> init() async {
    final box = await Hive.openBox<WaterModel>(boxName);
    _loadTodayData(box);
    _loadHistory(box);
  }

  void _loadTodayData(Box<WaterModel> box) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = box.get(today);
    
    if (data != null) {
      _todayIntake = data.intake;
      _dailyGoal = data.goal;
    } else {
      _todayIntake = 0;
      // You could load a saved goal from settings here if needed
      final newEntry = WaterModel(date: today, intake: 0, goal: _dailyGoal);
      box.put(today, newEntry);
    }
    notifyListeners();
  }

  void _loadHistory(Box<WaterModel> box) {
    _history = box.values.toList();
    _history.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addWater([int? amount]) async {
    final addAmount = amount ?? _selectedCupSize;
    _todayIntake += addAmount;
    final box = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final data = box.get(today) ?? WaterModel(date: today, intake: 0, goal: _dailyGoal);
    data.intake = _todayIntake;
    await box.put(today, data);
    
    _loadHistory(box); // Refresh history
    notifyListeners();
  }

  Future<void> resetToday() async {
    _todayIntake = 0;
    final box = Hive.box<WaterModel>(boxName);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final data = box.get(today);
    if (data != null) {
      data.intake = 0;
      await box.put(today, data);
    }
    
    _loadHistory(box);
    notifyListeners();
  }
}

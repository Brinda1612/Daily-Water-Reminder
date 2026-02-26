import 'package:hive/hive.dart';

part 'water_model.g.dart';

@HiveType(typeId: 0)
class WaterModel extends HiveObject {
  @HiveField(0)
  final String date;
  
  @HiveField(1)
  int intake;
  
  @HiveField(2)
  int goal;

  WaterModel({
    required this.date,
    required this.intake,
    required this.goal,
  });
}

import 'package:equatable/equatable.dart';

abstract class WaterEvent extends Equatable {
  const WaterEvent();

  @override
  List<Object?> get props => [];
}

class InitWater extends WaterEvent {}

class AddWater extends WaterEvent {
  final int? amount;
  const AddWater([this.amount]);

  @override
  List<Object?> get props => [amount];
}

class SetCupSize extends WaterEvent {
  final int size;
  const SetCupSize(this.size);

  @override
  List<Object?> get props => [size];
}

class UpdateDailyGoal extends WaterEvent {
  final int goal;
  const UpdateDailyGoal(this.goal);

  @override
  List<Object?> get props => [goal];
}

class ClearHistory extends WaterEvent {}

class SetReminderInterval extends WaterEvent {
  final int hours;
  const SetReminderInterval(this.hours);

  @override
  List<Object?> get props => [hours];
}

class CompleteOnboarding extends WaterEvent {
  final double weight;
  final double height;
  const CompleteOnboarding({required this.weight, required this.height});

  @override
  List<Object?> get props => [weight, height];
}

class ResetWater extends WaterEvent {}

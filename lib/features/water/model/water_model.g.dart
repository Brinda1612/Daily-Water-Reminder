// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterModelAdapter extends TypeAdapter<WaterModel> {
  @override
  final int typeId = 0;

  @override
  WaterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterModel(
      date: fields[0] as String,
      intake: fields[1] as int,
      goal: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WaterModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.intake)
      ..writeByte(2)
      ..write(obj.goal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 10;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      stars: fields[3] as int,
      hidden: fields[4] as bool,
      unlocked: fields[5] as bool,
      unlockedAt: fields[6] as DateTime?,
      criteria: fields[7] as String,
      progress: fields[8] as int?,
      goal: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.stars)
      ..writeByte(4)
      ..write(obj.hidden)
      ..writeByte(5)
      ..write(obj.unlocked)
      ..writeByte(6)
      ..write(obj.unlockedAt)
      ..writeByte(7)
      ..write(obj.criteria)
      ..writeByte(8)
      ..write(obj.progress)
      ..writeByte(9)
      ..write(obj.goal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

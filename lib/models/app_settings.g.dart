// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      currency: fields[0] as String,
      theme: fields[1] as String,
      familyMode: fields[2] as bool,
      familyCount: fields[3] as int,
      familyNames: (fields[4] as List?)?.cast<String>(),
      carryoverMode: fields[5] as bool? ?? false,
      goalsEnabled: fields[6] as bool? ?? false,
      // fields[7] e fields[8] (goalName/goalTarget antigos) são ignorados
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.theme)
      ..writeByte(2)
      ..write(obj.familyMode)
      ..writeByte(3)
      ..write(obj.familyCount)
      ..writeByte(4)
      ..write(obj.familyNames)
      ..writeByte(5)
      ..write(obj.carryoverMode)
      ..writeByte(6)
      ..write(obj.goalsEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

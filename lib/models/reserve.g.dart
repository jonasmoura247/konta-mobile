// GENERATED CODE - DO NOT MODIFY BY HAND
// ⚠️  KONTA PATCH: null-safety aplicada manualmente. Se regenerar, re-aplicar os ?? fallbacks.
// Ver: Plano 6 — Hive Migration Safety

part of 'reserve.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReserveAdapter extends TypeAdapter<Reserve> {
  @override
  final int typeId = 3;

  @override
  Reserve read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reserve(
      id: fields[0] as String? ?? '',
      description: fields[1] as String? ?? '',
      amount: (fields[2] as num?)?.toDouble() ?? 0.0,
      date: fields[3] as DateTime? ?? DateTime.now(),
      type: fields[4] as String? ?? 'entrada',
    );
  }

  @override
  void write(BinaryWriter writer, Reserve obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReserveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

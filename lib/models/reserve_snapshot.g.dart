// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserve_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReserveSnapshotAdapter extends TypeAdapter<ReserveSnapshot> {
  @override
  final int typeId = 4;

  @override
  ReserveSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReserveSnapshot(
      reserveId: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      type: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReserveSnapshot obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reserveId)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReserveSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_due_date.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardDueDateAdapter extends TypeAdapter<CardDueDate> {
  @override
  final int typeId = 7;

  @override
  CardDueDate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardDueDate(
      bankId: fields[0] as String,
      closureDay: fields[1] as int,
      paymentDay: fields[2] as int,
      overrideClosure: (fields[3] as Map?)?.cast<String, int>(),
      overridePayment: (fields[4] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, CardDueDate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.bankId)
      ..writeByte(1)
      ..write(obj.closureDay)
      ..writeByte(2)
      ..write(obj.paymentDay)
      ..writeByte(3)
      ..write(obj.overrideClosure)
      ..writeByte(4)
      ..write(obj.overridePayment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardDueDateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

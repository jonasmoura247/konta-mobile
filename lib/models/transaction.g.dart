// GENERATED CODE - DO NOT MODIFY BY HAND
// ⚠️  KONTA PATCH: null-safety aplicada manualmente. Se regenerar, re-aplicar os ?? fallbacks.
// Ver: Plano 6 — Hive Migration Safety

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String? ?? '',
      groupId: fields[1] as String? ?? 'avista',
      categoryId: fields[2] as String? ?? 'outros',
      description: fields[3] as String? ?? '',
      totalAmount: (fields[4] as num?)?.toDouble() ?? 0.0,
      installments: (fields[5] as num?)?.toInt() ?? 1,
      startDate: fields[6] as DateTime? ?? DateTime.now(),
      isSubscription: fields[7] as bool? ?? false,
      bankId: fields[8] as String?,
      familyMode: fields[9] as bool? ?? false,
      familyMember: fields[10] as String?,
      cancelledFrom: fields[11] as DateTime?,
      createdAt: fields[12] as DateTime? ?? DateTime.now(),
      subscriptionSeriesId: fields[13] as String?,
      paymentSubtype: fields[14] as String?,
      applyClosureDate: fields[15] as bool? ?? false,
      invoiceMonth: fields[16] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.installments)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.isSubscription)
      ..writeByte(8)
      ..write(obj.bankId)
      ..writeByte(9)
      ..write(obj.familyMode)
      ..writeByte(10)
      ..write(obj.familyMember)
      ..writeByte(11)
      ..write(obj.cancelledFrom)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.subscriptionSeriesId)
      ..writeByte(14)
      ..write(obj.paymentSubtype)
      ..writeByte(15)
      ..write(obj.applyClosureDate)
      ..writeByte(16)
      ..write(obj.invoiceMonth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

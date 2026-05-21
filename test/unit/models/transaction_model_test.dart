import 'package:flutter_test/flutter_test.dart';
import 'package:konta/models/transaction.dart';

Transaction makeTransaction({
  String id = 'test-id',
  String groupId = 'avista',
  double totalAmount = 100.0,
  int installments = 1,
  DateTime? startDate,
  DateTime? invoiceMonth,
  DateTime? cancelledFrom,
}) {
  return Transaction(
    id: id,
    groupId: groupId,
    categoryId: 'alimentacao',
    description: 'Mercado',
    totalAmount: totalAmount,
    installments: installments,
    startDate: startDate ?? DateTime(2026, 5, 10),
    createdAt: DateTime(2026, 5, 10, 12, 0),
    invoiceMonth: invoiceMonth,
    cancelledFrom: cancelledFrom,
  );
}

void main() {
  group('Transaction.toJson / fromJson', () {
    test('round-trip preserves all required fields', () {
      final tx = makeTransaction(totalAmount: 250.90, installments: 3);
      final restored = Transaction.fromJson(tx.toJson());

      expect(restored.id, tx.id);
      expect(restored.groupId, tx.groupId);
      expect(restored.categoryId, tx.categoryId);
      expect(restored.description, tx.description);
      expect(restored.totalAmount, tx.totalAmount);
      expect(restored.installments, tx.installments);
      expect(restored.startDate, DateTime(2026, 5, 10));
    });

    test('round-trip preserves null invoiceMonth', () {
      final tx = makeTransaction(invoiceMonth: null);
      final restored = Transaction.fromJson(tx.toJson());
      expect(restored.invoiceMonth, isNull);
    });

    test('round-trip preserves non-null invoiceMonth', () {
      final tx = makeTransaction(invoiceMonth: DateTime(2026, 6));
      final restored = Transaction.fromJson(tx.toJson());
      expect(restored.invoiceMonth, DateTime(2026, 6));
    });

    test('round-trip preserves cancelledFrom', () {
      final tx = makeTransaction(cancelledFrom: DateTime(2026, 8));
      final restored = Transaction.fromJson(tx.toJson());
      expect(restored.cancelledFrom, DateTime(2026, 8));
    });

    test('fromJson defaults installments to 1 when field is absent', () {
      final json = makeTransaction().toJson()..remove('installments');
      final restored = Transaction.fromJson(json);
      expect(restored.installments, 1);
    });

    test('fromJson defaults isSubscription to false when field is absent', () {
      final json = makeTransaction().toJson()..remove('isSubscription');
      final restored = Transaction.fromJson(json);
      expect(restored.isSubscription, false);
    });

    test('fromJson defaults applyClosureDate to false when field is absent', () {
      final json = makeTransaction().toJson()..remove('applyClosureDate');
      final restored = Transaction.fromJson(json);
      expect(restored.applyClosureDate, false);
    });

    test('round-trip preserves familyMode true', () {
      final tx = Transaction(
        id: 'fam',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Família',
        totalAmount: 400.0,
        startDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
        familyMode: true,
      );
      final restored = Transaction.fromJson(tx.toJson());
      expect(restored.familyMode, true);
    });
  });
}

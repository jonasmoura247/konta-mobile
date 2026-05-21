import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:konta/models/card_due_date.dart';
import 'package:konta/models/transaction.dart';
import 'package:konta/services/finance_calculator.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('billing_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(CardDueDateAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    if (!Hive.isBoxOpen('card_due_dates')) {
      await Hive.openBox<CardDueDate>('card_due_dates');
    }
  });

  tearDown(() async {
    await Hive.box<CardDueDate>('card_due_dates').clear();
  });

  group('getBillingMonth com applyClosureDate', () {
    test('purchase before closure day → billing next month', () async {
      final cdd =
          CardDueDate(bankId: 'nubank', closureDay: 20, paymentDay: 5);
      await Hive.box<CardDueDate>('card_due_dates').put('nubank', cdd);

      // Compra no dia 19 (antes do fechamento dia 20) → fatura junho
      final tx = Transaction(
        id: 'c1',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 100,
        startDate: DateTime(2026, 5, 19),
        applyClosureDate: true,
        bankId: 'nubank',
        isSubscription: false,
        createdAt: DateTime(2026, 5, 19),
      );

      expect(FinanceCalculator.getBillingMonth(tx), DateTime(2026, 6));
    });

    test('purchase on closure day → billing in 2 months', () async {
      final cdd =
          CardDueDate(bankId: 'itau', closureDay: 20, paymentDay: 5);
      await Hive.box<CardDueDate>('card_due_dates').put('itau', cdd);

      // Compra no dia 20 (no fechamento) → fatura julho
      final tx = Transaction(
        id: 'c2',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 100,
        startDate: DateTime(2026, 5, 20),
        applyClosureDate: true,
        bankId: 'itau',
        isSubscription: false,
        createdAt: DateTime(2026, 5, 20),
      );

      expect(FinanceCalculator.getBillingMonth(tx), DateTime(2026, 7));
    });

    test('purchase after closure day → billing in 2 months', () async {
      final cdd =
          CardDueDate(bankId: 'inter', closureDay: 15, paymentDay: 5);
      await Hive.box<CardDueDate>('card_due_dates').put('inter', cdd);

      // Compra dia 20 (após fechamento dia 15) → fatura em 2 meses
      final tx = Transaction(
        id: 'c3',
        groupId: 'parcelamento',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 600,
        installments: 3,
        startDate: DateTime(2026, 5, 20),
        applyClosureDate: true,
        bankId: 'inter',
        isSubscription: false,
        createdAt: DateTime(2026, 5, 20),
      );

      expect(FinanceCalculator.getBillingMonth(tx), DateTime(2026, 7));
    });

    test('bankId not in box returns startDate month', () async {
      // Nenhum CardDueDate para 'bradesco' no box
      final tx = Transaction(
        id: 'c4',
        groupId: 'avista',
        categoryId: 'outros',
        description: 'Compra',
        totalAmount: 100,
        startDate: DateTime(2026, 5, 25),
        applyClosureDate: true,
        bankId: 'bradesco',
        isSubscription: false,
        createdAt: DateTime(2026, 5, 25),
      );

      expect(FinanceCalculator.getBillingMonth(tx), DateTime(2026, 5, 25));
    });
  });
}

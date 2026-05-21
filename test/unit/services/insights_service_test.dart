import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:konta/models/income.dart';
import 'package:konta/models/transaction.dart';
import 'package:konta/services/insights_service.dart';

Transaction t(String id, String groupId, double amount, String categoryId,
    {DateTime? date, String? description}) {
  final d = date ?? DateTime(2026, 5, 10);
  return Transaction(
    id: id,
    groupId: groupId,
    categoryId: categoryId,
    description: description ?? id,
    totalAmount: amount,
    installments: 1,
    startDate: d,
    isSubscription: false,
    createdAt: d,
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('insights_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>('meta');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final may = DateTime(2026, 5);
  final april = DateTime(2026, 4);

  group('computeMonthInsights', () {
    test('biggestPurchase returns highest amount transaction', () {
      final txs = [
        t('pequena', 'avista', 50, 'outros'),
        t('grande', 'avista', 500, 'outros'),
        t('media', 'avista', 200, 'outros'),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.biggestPurchase!.transaction.id, 'grande');
    });

    test('biggestPurchase is null when no transactions', () {
      final insights =
          InsightsService.computeMonthInsights([], [], may, april, 1);
      expect(insights.biggestPurchase, isNull);
    });

    test('mostFrequentDescription requires at least 2 occurrences', () {
      final txs = [
        t('uber1', 'avista', 20, 'transporte'),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.mostFrequentDescription, isNull);
    });

    test('mostFrequentDescription found when 2+ same descriptions', () {
      final txs = [
        t('uber1', 'avista', 20, 'transporte', description: 'Uber'),
        t('uber2', 'avista', 25, 'transporte', description: 'Uber'),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.mostFrequentDescription, 'uber');
    });

    test('avgDailySpend = total / days in month (may has 31 days)', () {
      final txs = [
        t('tx1', 'avista', 310, 'outros'),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.avgDailySpend, closeTo(10.0, 0.01));
    });

    test('avgDailySpend is 0 when no transactions', () {
      final insights =
          InsightsService.computeMonthInsights([], [], may, april, 1);
      expect(insights.avgDailySpend, 0.0);
    });

    test('topCategoryByAmountId returns category with highest sum', () {
      final txs = [
        t('a1', 'avista', 100, 'alimentacao'),
        t('a2', 'avista', 200, 'alimentacao'),
        t('t1', 'avista', 50, 'transporte'),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.topCategoryByAmountId, 'alimentacao');
    });

    test('activeInstallmentCount counts active installments', () {
      final txs = [
        Transaction(
          id: 'tv',
          groupId: 'parcelamento',
          categoryId: 'outros',
          description: 'TV',
          totalAmount: 3000,
          installments: 12,
          startDate: DateTime(2026, 5, 1),
          isSubscription: false,
          createdAt: DateTime(2026, 5, 1),
        ),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);

      expect(insights.activeInstallmentCount, 1);
    });

    test('incomeCommittedPercent is 0 when no income', () {
      final txs = [t('tx1', 'avista', 100, 'outros')];
      final insights =
          InsightsService.computeMonthInsights(txs, [], may, april, 1);
      expect(insights.incomeCommittedPercent, 0.0);
    });

    test('incomeCommittedPercent calculated when income provided', () {
      final txs = [t('tx1', 'avista', 1000, 'outros')];
      final incomes = [
        Income(
          id: 'sal',
          description: r'Salário',
          amount: 4000,
          date: DateTime(2026, 5, 1),
          recurring: false,
        ),
      ];

      final insights =
          InsightsService.computeMonthInsights(txs, incomes, may, april, 1);

      expect(insights.incomeCommittedPercent, closeTo(25.0, 0.01));
    });
  });
}

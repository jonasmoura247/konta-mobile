import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../services/finance_calculator.dart';
import '../utils/formatters.dart';

class CategoryBar {
  final String categoryId;
  final String categoryName;
  final Color color;
  final double amount;
  final double fraction;

  const CategoryBar({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.amount,
    required this.fraction,
  });
}

class MonthInsights {
  final TransactionOccurrence? biggestPurchase;
  final TransactionOccurrence? biggestCashPurchase;
  final TransactionOccurrence? biggestInstallmentPurchase;
  final String? mostFrequentDescription;
  final String? topCategoryById;
  final String? topCategoryByAmountId;
  final double avgDailySpend;
  final int? topWeekday;
  final int? topHour;
  final int longestNoSpendStreak;
  final TransactionOccurrence? impulsivePurchase;
  final double avgTicket;
  final double totalPendingInstallments;
  final int activeInstallmentCount;
  final String? mostUsedBankId;
  final double nextMonthTotal;
  final double avgMonthlyBill;
  final double incomeCommittedPercent;
  final String? topCategoryOnCardId;
  final List<CategoryBar> topCategories;
  final List<String> insights;

  const MonthInsights({
    this.biggestPurchase,
    this.biggestCashPurchase,
    this.biggestInstallmentPurchase,
    this.mostFrequentDescription,
    this.topCategoryById,
    this.topCategoryByAmountId,
    required this.avgDailySpend,
    this.topWeekday,
    this.topHour,
    required this.longestNoSpendStreak,
    this.impulsivePurchase,
    required this.avgTicket,
    required this.totalPendingInstallments,
    required this.activeInstallmentCount,
    this.mostUsedBankId,
    required this.nextMonthTotal,
    required this.avgMonthlyBill,
    required this.incomeCommittedPercent,
    this.topCategoryOnCardId,
    required this.topCategories,
    required this.insights,
  });
}

class YearInsights {
  final DateTime? mostEconomicMonth;
  final DateTime? mostExpensiveMonth;
  final String? topCategoryById;
  final String? topCategoryByAmountId;
  final double avgMonthlySpend;
  final double avgTicket;
  final String? mostFrequentDescription;
  final String? mostUsedBankId;
  final int monthsWithFutureInstallments;
  final double totalYearSpend;
  final double totalYearCard;
  final double totalYearCash;
  final double totalYearInstallments;
  final TransactionOccurrence? biggestInstallmentOfYear;
  final TransactionOccurrence? biggestCashOfYear;
  final List<CategoryBar> topCategories;
  final List<String> insights;

  const YearInsights({
    this.mostEconomicMonth,
    this.mostExpensiveMonth,
    this.topCategoryById,
    this.topCategoryByAmountId,
    required this.avgMonthlySpend,
    required this.avgTicket,
    this.mostFrequentDescription,
    this.mostUsedBankId,
    required this.monthsWithFutureInstallments,
    required this.totalYearSpend,
    required this.totalYearCard,
    required this.totalYearCash,
    required this.totalYearInstallments,
    this.biggestInstallmentOfYear,
    this.biggestCashOfYear,
    required this.topCategories,
    required this.insights,
  });
}

class InsightsService {
  static MonthInsights computeMonthInsights(
    List<Transaction> transactions,
    List<Income> incomes,
    DateTime month,
    DateTime prevMonth,
    int familyCount, {
    String currency = 'BRL',
  }) {
    final creditOccs = FinanceCalculator.getOccurrencesForMonth(transactions, month, familyCount);
    final debitOccs = FinanceCalculator.getDebitOccurrencesForMonth(transactions, month, familyCount);
    final allOccs = [...creditOccs, ...debitOccs];

    final summary = FinanceCalculator.summarize(transactions, incomes, month, familyCount);
    final prevSummary = FinanceCalculator.summarize(transactions, incomes, prevMonth, familyCount);

    // Biggest purchase overall
    TransactionOccurrence? biggestPurchase;
    if (allOccs.isNotEmpty) {
      biggestPurchase = allOccs.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    // Biggest cash purchase (avista)
    final cashOccs = creditOccs.where((o) => o.transaction.groupId == 'avista').toList();
    TransactionOccurrence? biggestCashPurchase;
    if (cashOccs.isNotEmpty) {
      biggestCashPurchase = cashOccs.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    // Biggest installment by totalAmount
    final installOccs = creditOccs.where((o) => o.transaction.groupId == 'parcelamento').toList();
    TransactionOccurrence? biggestInstallmentPurchase;
    if (installOccs.isNotEmpty) {
      biggestInstallmentPurchase = installOccs.reduce((a, b) =>
          a.transaction.totalAmount > b.transaction.totalAmount ? a : b);
    }

    // Most frequent description (min 2 appearances)
    final descCounts = <String, int>{};
    for (final occ in allOccs) {
      final key = occ.transaction.description.trim().toLowerCase();
      descCounts[key] = (descCounts[key] ?? 0) + 1;
    }
    String? mostFrequentDescription;
    if (descCounts.isNotEmpty) {
      final maxEntry = descCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (maxEntry.value >= 2) mostFrequentDescription = maxEntry.key;
    }

    // Top category by count
    final catCountMap = <String, int>{};
    for (final occ in allOccs) {
      catCountMap[occ.transaction.categoryId] = (catCountMap[occ.transaction.categoryId] ?? 0) + 1;
    }
    String? topCategoryById;
    if (catCountMap.isNotEmpty) {
      topCategoryById = catCountMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Top category by amount (credit only)
    String? topCategoryByAmountId;
    if (summary.byCategory.isNotEmpty) {
      topCategoryByAmountId = summary.byCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Avg daily spend
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalSpend = summary.totalExpenses + summary.totalDebit;
    final avgDailySpend = totalSpend / daysInMonth;

    // Top weekday (> 30% of purchases)
    final weekdayCounts = <int, int>{};
    for (final occ in allOccs) {
      final wd = occ.transaction.startDate.weekday;
      weekdayCounts[wd] = (weekdayCounts[wd] ?? 0) + 1;
    }
    int? topWeekday;
    if (weekdayCounts.isNotEmpty) {
      final total = weekdayCounts.values.fold(0, (a, b) => a + b);
      if (total >= 3) {
        final maxEntry = weekdayCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        if (maxEntry.value / total > 0.30) topWeekday = maxEntry.key;
      }
    }

    // Top hour via createdAt (> 25% threshold)
    final hourCounts = <int, int>{};
    for (final occ in creditOccs) {
      final h = occ.transaction.createdAt.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    int? topHour;
    if (hourCounts.isNotEmpty) {
      final total = hourCounts.values.fold(0, (a, b) => a + b);
      if (total >= 4) {
        final maxEntry = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
        if (maxEntry.value / total > 0.25) topHour = maxEntry.key;
      }
    }

    // Longest no-spend streak (days in month with no occurrence)
    final daysWithSpend = <int>{};
    for (final occ in allOccs) {
      if (isSameMonth(occ.transaction.startDate, month)) {
        daysWithSpend.add(occ.transaction.startDate.day);
      }
    }
    int longestNoSpendStreak = 0;
    int currentStreak = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      if (!daysWithSpend.contains(d)) {
        currentStreak++;
        longestNoSpendStreak = max(longestNoSpendStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }

    // Avg ticket (credit)
    final creditCount = creditOccs.length;
    final avgTicket = creditCount > 0 ? summary.totalExpenses / creditCount : 0.0;

    // Impulsive purchase: amount > 2.5× avgTicket AND > R$50
    TransactionOccurrence? impulsivePurchase;
    if (avgTicket > 0) {
      final threshold = avgTicket * 2.5;
      final candidates = creditOccs.where((o) => o.amount > threshold && o.amount > 50.0).toList();
      if (candidates.isNotEmpty) {
        impulsivePurchase = candidates.reduce((a, b) => a.amount > b.amount ? a : b);
      }
    }

    // Pending installments from next month onwards
    double totalPendingInstallments = 0.0;
    int activeInstallmentCount = 0;
    final nextMonthDate = DateTime(month.year, month.month + 1);
    for (final t in transactions.where((t) => t.groupId == 'parcelamento')) {
      final billingStart = t.applyClosureDate
          ? FinanceCalculator.getBillingMonth(t)
          : DateTime(t.startDate.year, t.startDate.month);
      final elapsedBeforeNext = max(0, monthDiff(billingStart, nextMonthDate));
      final remainingFromNext = max(0, t.installments - elapsedBeforeNext);
      if (remainingFromNext > 0) {
        double amount = t.totalAmount / t.installments;
        if (t.familyMode && familyCount > 1) amount /= familyCount;
        totalPendingInstallments += remainingFromNext * amount;
        activeInstallmentCount++;
      }
    }

    // Most used bank
    final bankCounts = <String, int>{};
    for (final occ in creditOccs) {
      final bankId = occ.transaction.bankId;
      if (bankId != null && bankId.isNotEmpty) {
        bankCounts[bankId] = (bankCounts[bankId] ?? 0) + 1;
      }
    }
    String? mostUsedBankId;
    if (bankCounts.isNotEmpty) {
      mostUsedBankId = bankCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Next month preview
    final nextMonthSummary = FinanceCalculator.summarize(transactions, incomes, nextMonthDate, familyCount);
    final nextMonthTotal = nextMonthSummary.totalExpenses;

    // Avg monthly bill (last 3 months)
    double avgMonthlyBill = 0.0;
    {
      double billTotal = 0.0;
      for (int i = 1; i <= 3; i++) {
        final m = DateTime(month.year, month.month - i);
        billTotal += FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalExpenses;
      }
      avgMonthlyBill = billTotal / 3;
    }

    // Income committed %
    final incomeCommittedPercent =
        summary.totalIncome > 0 ? (summary.totalExpenses / summary.totalIncome) * 100 : 0.0;

    // Top category on card (same as byAmount since byCategory = credit only)
    final topCategoryOnCardId = topCategoryByAmountId;

    // Top categories bar chart (merge credit + debit)
    final mergedByCategory = <String, double>{...summary.byCategory};
    for (final e in summary.byDebitCategory.entries) {
      mergedByCategory[e.key] = (mergedByCategory[e.key] ?? 0) + e.value;
    }
    final topCategories = _buildCategoryBars(mergedByCategory);

    final insights = _generateMonthInsights(
      summary: summary,
      prevSummary: prevSummary,
      biggestPurchase: biggestPurchase,
      topCategoryByAmountId: topCategoryByAmountId,
      topWeekday: topWeekday,
      topHour: topHour,
      totalPendingInstallments: totalPendingInstallments,
      incomeCommittedPercent: incomeCommittedPercent,
      impulsivePurchase: impulsivePurchase,
      creditOccs: creditOccs,
      currency: currency,
    );

    return MonthInsights(
      biggestPurchase: biggestPurchase,
      biggestCashPurchase: biggestCashPurchase,
      biggestInstallmentPurchase: biggestInstallmentPurchase,
      mostFrequentDescription: mostFrequentDescription,
      topCategoryById: topCategoryById,
      topCategoryByAmountId: topCategoryByAmountId,
      avgDailySpend: avgDailySpend,
      topWeekday: topWeekday,
      topHour: topHour,
      longestNoSpendStreak: longestNoSpendStreak,
      impulsivePurchase: impulsivePurchase,
      avgTicket: avgTicket,
      totalPendingInstallments: totalPendingInstallments,
      activeInstallmentCount: activeInstallmentCount,
      mostUsedBankId: mostUsedBankId,
      nextMonthTotal: nextMonthTotal,
      avgMonthlyBill: avgMonthlyBill,
      incomeCommittedPercent: incomeCommittedPercent,
      topCategoryOnCardId: topCategoryOnCardId,
      topCategories: topCategories,
      insights: insights,
    );
  }

  static YearInsights computeYearInsights(
    List<Transaction> transactions,
    List<Income> incomes,
    int year,
    int familyCount, {
    String currency = 'BRL',
  }) {
    final yearSummary = FinanceCalculator.summarizeYear(transactions, incomes, year, familyCount);
    final untilMonth = yearSummary.untilMonth;
    final now = DateTime.now();

    // Most economic / expensive month
    DateTime? mostEconomicMonth;
    DateTime? mostExpensiveMonth;
    double minSpend = double.infinity;
    double maxSpend = 0;
    for (int i = 0; i < untilMonth; i++) {
      final ms = yearSummary.monthSummaries[i];
      final spend = ms.totalExpenses + ms.totalDebit;
      if (spend <= 0) continue;
      if (spend < minSpend) {
        minSpend = spend;
        mostEconomicMonth = yearSummary.months[i];
      }
      if (spend > maxSpend) {
        maxSpend = spend;
        mostExpensiveMonth = yearSummary.months[i];
      }
    }

    // Aggregate across all months of the year
    final yearByCategory = <String, double>{};
    final yearByCount = <String, int>{};
    final yearDescCounts = <String, int>{};
    final yearBankCounts = <String, int>{};
    final seenInstallmentIds = <String>{};
    double totalYearCash = 0.0;
    double totalYearInstallments = 0.0;
    int totalOccurrenceCount = 0;
    TransactionOccurrence? biggestInstallmentOfYear;
    TransactionOccurrence? biggestCashOfYear;

    for (int m = 1; m <= untilMonth; m++) {
      final mDate = DateTime(year, m);
      final occs = FinanceCalculator.getOccurrencesForMonth(transactions, mDate, familyCount);
      final debitOccs = FinanceCalculator.getDebitOccurrencesForMonth(transactions, mDate, familyCount);

      totalOccurrenceCount += occs.length + debitOccs.length;

      for (final occ in occs) {
        final catId = occ.transaction.categoryId;
        yearByCategory[catId] = (yearByCategory[catId] ?? 0) + occ.amount;
        yearByCount[catId] = (yearByCount[catId] ?? 0) + 1;

        final desc = occ.transaction.description.trim().toLowerCase();
        yearDescCounts[desc] = (yearDescCounts[desc] ?? 0) + 1;

        final bankId = occ.transaction.bankId;
        if (bankId != null && bankId.isNotEmpty) {
          yearBankCounts[bankId] = (yearBankCounts[bankId] ?? 0) + 1;
        }

        if (occ.transaction.groupId == 'avista') {
          totalYearCash += occ.amount;
          if (biggestCashOfYear == null || occ.amount > biggestCashOfYear.amount) {
            biggestCashOfYear = occ;
          }
        } else if (occ.transaction.groupId == 'parcelamento') {
          totalYearInstallments += occ.amount;
          // Only count each installment transaction once (by startDate year)
          final txId = occ.transaction.id;
          if (occ.transaction.startDate.year == year && !seenInstallmentIds.contains(txId)) {
            seenInstallmentIds.add(txId);
            if (biggestInstallmentOfYear == null ||
                occ.transaction.totalAmount > biggestInstallmentOfYear.transaction.totalAmount) {
              biggestInstallmentOfYear = occ;
            }
          }
        }
      }

      for (final occ in debitOccs) {
        final catId = occ.transaction.categoryId;
        yearByCategory[catId] = (yearByCategory[catId] ?? 0) + occ.amount;
        yearByCount[catId] = (yearByCount[catId] ?? 0) + 1;
      }
    }

    // Top category by amount
    String? topCategoryByAmountId;
    if (yearByCategory.isNotEmpty) {
      topCategoryByAmountId = yearByCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Top category by count
    String? topCategoryById;
    if (yearByCount.isNotEmpty) {
      topCategoryById = yearByCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Most frequent description
    String? mostFrequentDescription;
    if (yearDescCounts.isNotEmpty) {
      final maxEntry = yearDescCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (maxEntry.value >= 2) mostFrequentDescription = maxEntry.key;
    }

    // Most used bank
    String? mostUsedBankId;
    if (yearBankCounts.isNotEmpty) {
      mostUsedBankId = yearBankCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Avg monthly spend (only months with data)
    int monthsWithData = 0;
    for (int i = 0; i < untilMonth; i++) {
      final ms = yearSummary.monthSummaries[i];
      if (ms.totalExpenses + ms.totalDebit + ms.totalIncome > 0) monthsWithData++;
    }
    final avgMonthlySpend =
        monthsWithData > 0 ? (yearSummary.totalExpenses + yearSummary.totalDebit) / monthsWithData : 0.0;

    // Avg ticket
    final avgTicket =
        totalOccurrenceCount > 0 ? (yearSummary.totalExpenses + yearSummary.totalDebit) / totalOccurrenceCount : 0.0;

    // Months with future installments (in this year, after now)
    int monthsWithFutureInstallments = 0;
    {
      final nowMonth = DateTime(now.year, now.month);
      final futureMonthsSet = <String>{};
      for (final t in transactions.where((t) => t.groupId == 'parcelamento')) {
        final billingStart = t.applyClosureDate
            ? FinanceCalculator.getBillingMonth(t)
            : DateTime(t.startDate.year, t.startDate.month);
        for (int i = 0; i < t.installments; i++) {
          final installmentMonth = DateTime(billingStart.year, billingStart.month + i);
          if (installmentMonth.isAfter(nowMonth) && installmentMonth.year == year) {
            futureMonthsSet.add('${installmentMonth.year}-${installmentMonth.month}');
          }
        }
      }
      monthsWithFutureInstallments = futureMonthsSet.length;
    }

    final totalYearCard = yearSummary.totalExpenses;
    final totalYearSpend = yearSummary.totalExpenses + yearSummary.totalDebit;
    final topCategories = _buildCategoryBars(yearByCategory);

    final insights = _generateYearInsights(
      yearSummary: yearSummary,
      topCategoryByAmountId: topCategoryByAmountId,
      mostEconomicMonth: mostEconomicMonth,
      currency: currency,
    );

    return YearInsights(
      mostEconomicMonth: mostEconomicMonth,
      mostExpensiveMonth: mostExpensiveMonth,
      topCategoryById: topCategoryById,
      topCategoryByAmountId: topCategoryByAmountId,
      avgMonthlySpend: avgMonthlySpend,
      avgTicket: avgTicket,
      mostFrequentDescription: mostFrequentDescription,
      mostUsedBankId: mostUsedBankId,
      monthsWithFutureInstallments: monthsWithFutureInstallments,
      totalYearSpend: totalYearSpend,
      totalYearCard: totalYearCard,
      totalYearCash: totalYearCash,
      totalYearInstallments: totalYearInstallments,
      biggestInstallmentOfYear: biggestInstallmentOfYear,
      biggestCashOfYear: biggestCashOfYear,
      topCategories: topCategories,
      insights: insights,
    );
  }

  static List<CategoryBar> _buildCategoryBars(Map<String, double> byCategory) {
    if (byCategory.isEmpty) return [];
    final sorted = byCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    if (top.isEmpty) return [];
    final maxAmount = top.first.value;
    return top.map((e) {
      final cat = getCategoryById(e.key);
      return CategoryBar(
        categoryId: e.key,
        categoryName: cat.name,
        color: cat.color,
        amount: e.value,
        fraction: maxAmount > 0 ? e.value / maxAmount : 0.0,
      );
    }).toList();
  }

  static List<String> _generateMonthInsights({
    required MonthSummary summary,
    required MonthSummary prevSummary,
    TransactionOccurrence? biggestPurchase,
    String? topCategoryByAmountId,
    int? topWeekday,
    int? topHour,
    required double totalPendingInstallments,
    required double incomeCommittedPercent,
    TransactionOccurrence? impulsivePurchase,
    required List<TransactionOccurrence> creditOccs,
    required String currency,
  }) {
    final msgs = <String>[];

    // 1. Category comparison with previous month
    if (topCategoryByAmountId != null) {
      final curr = summary.byCategory[topCategoryByAmountId] ?? 0;
      final prev = prevSummary.byCategory[topCategoryByAmountId] ?? 0;
      if (prev > 0 && curr > 0) {
        final pct = ((curr - prev) / prev * 100).round();
        final catName = getCategoryById(topCategoryByAmountId).name;
        if (pct > 10) {
          msgs.add('Você gastou $pct% mais com $catName este mês');
        } else if (pct < -10) {
          msgs.add('Seu gasto com $catName caiu ${pct.abs()}% este mês');
        }
      }
    }

    // 2. Biggest expense
    if (biggestPurchase != null) {
      final catName = getCategoryById(biggestPurchase.transaction.categoryId).name;
      msgs.add('Seu maior gasto foi em $catName (${formatCurrency(biggestPurchase.amount, currency: currency)})');
    }

    // 3. Economy vs previous month
    final prevTotal = prevSummary.totalExpenses + prevSummary.totalDebit;
    final currTotal = summary.totalExpenses + summary.totalDebit;
    if (prevTotal > 0) {
      final diff = currTotal - prevTotal;
      if (diff < -10) {
        msgs.add('Você economizou ${formatCurrency(-diff, currency: currency)} comparado ao mês passado');
      } else if (diff > 10) {
        msgs.add('Você gastou ${formatCurrency(diff, currency: currency)} a mais que no mês passado');
      }
    }

    // 4. Weekday pattern
    if (topWeekday != null) {
      const weekdayNames = ['', 'Segundas', 'Terças', 'Quartas', 'Quintas', 'Sextas', 'Sábados', 'Domingos'];
      msgs.add('Você costuma gastar mais às ${weekdayNames[topWeekday]}');
    }

    // 5. Hour pattern
    if (topHour != null && creditOccs.isNotEmpty) {
      final String period;
      final bool Function(int h) inPeriod;
      if (topHour >= 5 && topHour < 12) {
        period = 'manhã';
        inPeriod = (h) => h >= 5 && h < 12;
      } else if (topHour >= 12 && topHour < 18) {
        period = 'tarde';
        inPeriod = (h) => h >= 12 && h < 18;
      } else if (topHour >= 18) {
        period = 'noite';
        inPeriod = (h) => h >= 18;
      } else {
        period = 'madrugada';
        inPeriod = (h) => h < 5;
      }
      final inPeriodCount = creditOccs.where((o) => inPeriod(o.transaction.createdAt.hour)).length;
      final pct = ((inPeriodCount / creditOccs.length) * 100).round();
      msgs.add('Compras à $period representam $pct% dos seus gastos');
    }

    // 6. Installments
    if (totalPendingInstallments > 0) {
      msgs.add('${formatCurrency(totalPendingInstallments, currency: currency)} pendente em parcelas ativas');
    }
    if (incomeCommittedPercent > 0 && incomeCommittedPercent <= 200) {
      msgs.add('${incomeCommittedPercent.toStringAsFixed(0)}% da sua renda comprometida com cartão');
    }

    // 7. Impulsive purchase
    if (impulsivePurchase != null) {
      final desc = impulsivePurchase.transaction.description;
      msgs.add('Compra acima do padrão: $desc (${formatCurrency(impulsivePurchase.amount, currency: currency)})');
    }

    return msgs.take(5).toList();
  }

  static List<String> _generateYearInsights({
    required YearSummary yearSummary,
    String? topCategoryByAmountId,
    DateTime? mostEconomicMonth,
    required String currency,
  }) {
    final msgs = <String>[];

    // 1. Semester trend
    if (yearSummary.untilMonth > 6) {
      final h1 = yearSummary.monthSummaries
          .take(6)
          .fold(0.0, (s, m) => s + m.totalExpenses + m.totalDebit);
      final h2Months = yearSummary.untilMonth - 6;
      final h2 = yearSummary.monthSummaries
          .skip(6)
          .take(h2Months)
          .fold(0.0, (s, m) => s + m.totalExpenses + m.totalDebit);
      final h1Avg = h1 / 6;
      final h2Avg = h2Months > 0 ? h2 / h2Months : 0.0;
      if (h1Avg > 0) {
        if (h2Avg > h1Avg * 1.05) {
          msgs.add('Seu padrão de gastos aumentou no segundo semestre');
        } else if (h2Avg < h1Avg * 0.95) {
          msgs.add('Seu padrão de gastos reduziu no segundo semestre');
        }
      }
    }

    // 2. Dominant category
    if (topCategoryByAmountId != null) {
      final catName = getCategoryById(topCategoryByAmountId).name;
      msgs.add('$catName foi sua principal categoria do ano');
    }

    // 3. Most economic month
    if (mostEconomicMonth != null) {
      msgs.add('Seu mês mais econômico foi ${capitalize(formatMonth(mostEconomicMonth))}');
    }

    // 4. Best month by balance
    if (yearSummary.bestMonth != null) {
      msgs.add('Melhor saldo em ${capitalize(formatMonth(yearSummary.bestMonth!))}');
    }

    // 5. Total year
    final totalSpend = yearSummary.totalExpenses + yearSummary.totalDebit;
    if (totalSpend > 0) {
      msgs.add('Total gasto em ${yearSummary.year}: ${formatCurrency(totalSpend, currency: currency)}');
    }

    return msgs.take(4).toList();
  }
}

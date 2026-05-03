import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bar_chart_6months.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<DateTime> _months;
  late List<double> _expenses;
  late List<double> _incomes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    final transactions = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    final currency = settings.currency;

    _months = FinanceCalculator.lastNMonths(DateTime.now(), 6);
    _expenses = _months.map((m) => FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalExpenses).toList();
    _incomes = _months.map((m) => FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalIncome).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currency = DatabaseService.getSettings().currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Últimos 6 meses', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
            child: BarChart6Months(months: _months, expenses: _expenses, incomes: _incomes),
          ),
          const SizedBox(height: 24),
          const Text('Resumo mensal', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(_months.length, (i) {
            final balance = _incomes[i] - _expenses[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(capitalize(formatMonth(_months[i])), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(_expenses[i], currency: currency), style: const TextStyle(color: AppColors.expense, fontSize: 13, fontFamily: 'JetBrainsMono')),
                      Text(formatCurrency(balance, currency: currency), style: TextStyle(color: balance >= 0 ? AppColors.income : AppColors.expense, fontSize: 11, fontFamily: 'JetBrainsMono')),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

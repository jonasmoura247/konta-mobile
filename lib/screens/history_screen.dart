import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bar_chart_6months.dart';
import 'insights_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late List<DateTime> _months;
  late List<double> _expenses;
  late List<double> _incomes;
  late List<double> _debits;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    DatabaseService.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    DatabaseService.dataVersion.removeListener(_load);
    super.dispose();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    final transactions = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();
    final familyCount = settings.familyMode ? settings.familyCount : 1;

    final year = DateTime.now().year;
    _months = List.generate(12, (i) => DateTime(year, i + 1));

    _expenses = _months
        .map((m) => FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalExpenses)
        .toList();
    _incomes = _months
        .map((m) => FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalIncome)
        .toList();
    _debits = _months
        .map((m) => FinanceCalculator.summarize(transactions, incomes, m, familyCount).totalDebit)
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currency = DatabaseService.getSettings().currency;
    final year = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Anual'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Histórico Anual ──────────────────────────────────────────
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Visão geral $year',
                style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.kCardBorder),
                ),
                child: BarChart6Months(
                  months: _months,
                  expenses: _expenses,
                  incomes: _incomes,
                  debits: _debits,
                  currency: currency,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Resumo mensal',
                style: TextStyle(
                    color: context.kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(_months.length, (i) {
                final balance = _incomes[i] - _expenses[i] - _debits[i];
                return GestureDetector(
                  onTap: () => context.go('/transactions', extra: _months[i]),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.kCardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                capitalize(formatMonth(_months[i])),
                                style: TextStyle(
                                    color: context.kTextPrimary,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right,
                                  size: 14, color: context.kTextSecondary),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(_expenses[i], currency: currency),
                              style: const TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 13,
                                  fontFamily: 'JetBrainsMono'),
                            ),
                            if (_debits[i] > 0)
                              Text(
                                formatCurrency(_debits[i], currency: currency),
                                style: const TextStyle(
                                    color: AppColors.neonCyan,
                                    fontSize: 11,
                                    fontFamily: 'JetBrainsMono'),
                              ),
                            Text(
                              formatCurrency(balance, currency: currency),
                              style: TextStyle(
                                  color: balance >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                  fontSize: 11,
                                  fontFamily: 'JetBrainsMono'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // ── Tab 2: Insights ─────────────────────────────────────────────────
          const InsightsScreen(),
        ],
      ),
    );
  }
}

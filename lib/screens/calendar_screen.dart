import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _activeMonth = DateTime.now();
  List<TransactionOccurrence> _occurrences = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    setState(() {
      _occurrences = FinanceCalculator.getOccurrencesForMonth(
        DatabaseService.getAllTransactions(),
        _activeMonth,
        settings.familyMode ? settings.familyCount : 1,
      );
    });
  }

  Map<int, double> get _dailyTotals {
    final map = <int, double>{};
    for (final o in _occurrences) {
      final day = o.transaction.startDate.day;
      map[day] = (map[day] ?? 0) + o.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = firstDayOfMonth(_activeMonth);
    final lastDay = lastDayOfMonth(_activeMonth);
    final startWeekday = firstDay.weekday % 7; // 0=Dom
    final totalCells = startWeekday + lastDay.day;
    final rows = (totalCells / 7).ceil();
    final dailyTotals = _dailyTotals;
    final currency = DatabaseService.getSettings().currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { _activeMonth = DateTime(_activeMonth.year, _activeMonth.month - 1); _load(); }),
          Center(child: Text(formatMonth(_activeMonth), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + 1); _load(); }),
        ],
      ),
      body: Column(
        children: [
          // Dias da semana
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb']
                  .map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)))))
                  .toList(),
            ),
          ),
          const Divider(height: 1),
          // Grade de dias
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.75),
              itemCount: rows * 7,
              itemBuilder: (ctx, i) {
                final dayNum = i - startWeekday + 1;
                if (dayNum < 1 || dayNum > lastDay.day) return const SizedBox.shrink();
                final amount = dailyTotals[dayNum];
                final isToday = DateTime.now().year == _activeMonth.year &&
                    DateTime.now().month == _activeMonth.month &&
                    DateTime.now().day == dayNum;
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.accent.withValues(alpha: 0.15) : (amount != null ? AppColors.expense.withValues(alpha: 0.08) : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isToday ? AppColors.accent : AppColors.cardBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(color: isToday ? AppColors.accent : AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      if (amount != null)
                        Text(
                          formatCurrency(amount, currency: currency).replaceAll('R\$ ', '').replaceAll('\$', '').replaceAll('€', ''),
                          style: const TextStyle(color: AppColors.expense, fontSize: 8),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

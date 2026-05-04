import 'package:flutter/material.dart';
import '../models/income.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'add_income_form.dart';

class IncomesListSheet extends StatefulWidget {
  final DateTime activeMonth;
  final List<Income> incomes;
  final String currency;
  final Future<void> Function(Income) onSave;
  final Future<void> Function(Income) onDelete;

  const IncomesListSheet({
    super.key,
    required this.activeMonth,
    required this.incomes,
    required this.currency,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<IncomesListSheet> createState() => _IncomesListSheetState();
}

class _IncomesListSheetState extends State<IncomesListSheet> {
  List<Income> get _monthIncomes => widget.incomes.where((i) => i.recurring || isSameMonth(i.date, widget.activeMonth)).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  double get _total => _monthIncomes.fold(0, (s, i) => s + i.amount);

  void _openEdit(Income income) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIncomeForm(
        editing: income,
        onSave: widget.onSave,
        onDelete: () => widget.onDelete(income),
      ),
    );
  }

  void _openNew() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIncomeForm(
        onSave: widget.onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _monthIncomes;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Entradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.kTextPrimary)),
                          Text(capitalize(formatMonth(widget.activeMonth)), style: TextStyle(fontSize: 12, color: context.kTextSecondary)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.income),
                        onPressed: _openNew,
                        tooltip: 'Nova Entrada',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Lista
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('Nenhuma entrada neste mês', style: TextStyle(color: context.kTextSecondary)))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.kCardBorder),
                      itemBuilder: (ctx, i) {
                        final inc = items[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.income.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.trending_up, color: AppColors.income, size: 20),
                          ),
                          title: Text(inc.description, style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Row(
                            children: [
                              Text(formatDate(inc.date), style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                              if (inc.recurring) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Recorrente', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                          trailing: Text(
                            formatCurrency(inc.amount, currency: widget.currency),
                            style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono', fontSize: 14),
                          ),
                          onTap: () => _openEdit(inc),
                        );
                      },
                    ),
            ),
            // Rodapé total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: context.kCard,
                border: Border(top: BorderSide(color: context.kCardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    formatCurrency(_total, currency: widget.currency),
                    style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono', fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

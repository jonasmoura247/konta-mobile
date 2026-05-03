import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_transaction_form.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _activeMonth = DateTime.now();
  List<TransactionOccurrence> _occurrences = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    setState(() {
      _occurrences = FinanceCalculator.getOccurrencesForMonth(
        DatabaseService.getAllTransactions(),
        _activeMonth,
        familyCount,
      );
    });
  }

  void _changeMonth(int delta) {
    _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + delta);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Center(
            child: Text(formatMonth(_activeMonth), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
      body: _occurrences.isEmpty
          ? const Center(child: Text('Nenhum lançamento neste mês', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _occurrences.length,
              itemBuilder: (ctx, i) {
                final o = _occurrences[i];
                return TransactionCard(
                  occurrence: o,
                  currency: DatabaseService.getSettings().currency,
                  onEdit: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddTransactionForm(
                      editing: o.transaction,
                      onSave: (t) async {
                        await DatabaseService.updateTransaction(t);
                        _load();
                      },
                    ),
                  ),
                  onDelete: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Excluir lançamento?', style: TextStyle(color: AppColors.textPrimary)),
                      content: Text(o.transaction.description, style: const TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () async {
                            await DatabaseService.deleteTransaction(o.transaction);
                            if (context.mounted) Navigator.pop(context);
                            _load();
                          },
                          child: const Text('Excluir', style: TextStyle(color: AppColors.expense)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionForm(
            onSave: (t) async {
              await DatabaseService.addTransaction(t);
              _load();
            },
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

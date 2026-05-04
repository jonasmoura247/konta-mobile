import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/month_picker_button.dart';

// ── Sort options ──────────────────────────────────────────────────────────────
enum TxSort { dateAsc, dateDesc, amountDesc, amountAsc, nameAz, type, category }

extension TxSortLabel on TxSort {
  String get label {
    switch (this) {
      case TxSort.dateAsc:    return 'Data ↑';
      case TxSort.dateDesc:   return 'Data ↓';
      case TxSort.amountDesc: return 'Maior valor';
      case TxSort.amountAsc:  return 'Menor valor';
      case TxSort.nameAz:     return 'Nome A→Z';
      case TxSort.type:       return 'Tipo da conta';
      case TxSort.category:   return 'Categoria';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _activeMonth = DateTime.now();
  List<TransactionOccurrence> _occurrences = [];

  // Filters
  String _filterGroup  = 'all';
  String _filterCat    = 'all';
  String _filterBank   = 'all';
  TxSort _sortBy       = TxSort.dateAsc;

  static const _groupLabels = {
    'avista':       'À Vista',
    'parcelamento': 'Parcelamento',
    'assinatura':   'Assinatura',
  };
  static const _groupOrder = {'assinatura': 0, 'avista': 1, 'parcelamento': 2};

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

  List<TransactionOccurrence> get _filtered {
    List<TransactionOccurrence> list = [..._occurrences];

    if (_filterGroup != 'all') {
      list = list.where((o) => o.transaction.groupId == _filterGroup).toList();
    }
    if (_filterCat != 'all') {
      list = list.where((o) => o.transaction.categoryId == _filterCat).toList();
    }
    if (_filterBank != 'all') {
      if (_filterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list.where((o) => o.transaction.bankId == _filterBank).toList();
      }
    }

    final cats = getAllCategories();
    String catName(String id) => cats.firstWhere((c) => c.id == id, orElse: () => cats.last).name;
    int groupRank(String id) => _groupOrder[id] ?? 99;

    switch (_sortBy) {
      case TxSort.dateAsc:
        list.sort((a, b) => a.transaction.startDate.compareTo(b.transaction.startDate));
      case TxSort.dateDesc:
        list.sort((a, b) => b.transaction.startDate.compareTo(a.transaction.startDate));
      case TxSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case TxSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
      case TxSort.nameAz:
        list.sort((a, b) => a.transaction.description.compareTo(b.transaction.description));
      case TxSort.type:
        list.sort((a, b) {
          final t = groupRank(a.transaction.groupId) - groupRank(b.transaction.groupId);
          if (t != 0) return t;
          final c = catName(a.transaction.categoryId).compareTo(catName(b.transaction.categoryId));
          if (c != 0) return c;
          return a.transaction.startDate.compareTo(b.transaction.startDate);
        });
      case TxSort.category:
        list.sort((a, b) {
          final c = catName(a.transaction.categoryId).compareTo(catName(b.transaction.categoryId));
          if (c != 0) return c;
          final t = groupRank(a.transaction.groupId) - groupRank(b.transaction.groupId);
          if (t != 0) return t;
          return a.transaction.startDate.compareTo(b.transaction.startDate);
        });
    }

    return list;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filterGroup: _filterGroup,
        filterCat: _filterCat,
        filterBank: _filterBank,
        sortBy: _sortBy,
        groupLabels: _groupLabels,
        onApply: (g, c, b, s) {
          setState(() {
            _filterGroup = g;
            _filterCat = c;
            _filterBank = b;
            _sortBy = s;
          });
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filterGroup != 'all' || _filterCat != 'all' || _filterBank != 'all' || _sortBy != TxSort.dateAsc;

  void _clearFilters() => setState(() {
        _filterGroup = 'all';
        _filterCat = 'all';
        _filterBank = 'all';
        _sortBy = TxSort.dateAsc;
      });

  @override
  Widget build(BuildContext context) {
    final currency = DatabaseService.getSettings().currency;
    final filtered = _filtered;
    final total = filtered.fold<double>(0, (s, o) => s + o.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MonthPickerButton(
              activeMonth: _activeMonth,
              onChanged: (m) {
                _activeMonth = m;
                _load();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de filtros ────────────────────────────────────────────
          Container(
            color: context.kBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                // Botão filtrar
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _hasActiveFilters ? AppColors.accent.withValues(alpha: 0.15) : context.kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _hasActiveFilters ? AppColors.accent : context.kCardBorder,
                        width: _hasActiveFilters ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 14,
                            color: _hasActiveFilters ? AppColors.accent : context.kTextSecondary),
                        const SizedBox(width: 6),
                        Text('Filtrar',
                            style: TextStyle(
                              color: _hasActiveFilters ? AppColors.accent : context.kTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 6),
                          Text('· ${_sortBy.label}',
                              style: TextStyle(color: AppColors.accent.withValues(alpha: 0.8), fontSize: 10)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.expense.withValues(alpha: 0.4)),
                      ),
                      child: const Text('Limpar', style: TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const Spacer(),
                // Contador + total
                Text(
                  '${filtered.length} · ${formatCurrency(total, currency: currency)}',
                  style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontFamily: 'JetBrainsMono'),
                ),
              ],
            ),
          ),
          // ── Lista ────────────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💸', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 12),
                      Text(
                        _hasActiveFilters ? 'Nenhum resultado para os filtros.' : 'Nenhum lançamento neste mês',
                        style: TextStyle(color: context.kTextSecondary, fontSize: 13),
                      ),
                    ],
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final o = filtered[i];
                      return TransactionCard(
                        occurrence: o,
                        currency: currency,
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
                            backgroundColor: context.kCard,
                            title: Text('Excluir lançamento?', style: TextStyle(color: context.kTextPrimary)),
                            content: Text(o.transaction.description, style: TextStyle(color: context.kTextSecondary)),
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
          ),
        ],
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

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String filterGroup;
  final String filterCat;
  final String filterBank;
  final TxSort sortBy;
  final Map<String, String> groupLabels;
  final void Function(String, String, String, TxSort) onApply;

  const _FilterSheet({
    required this.filterGroup,
    required this.filterCat,
    required this.filterBank,
    required this.sortBy,
    required this.groupLabels,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _group;
  late String _cat;
  late String _bank;
  late TxSort _sort;

  @override
  void initState() {
    super.initState();
    _group = widget.filterGroup;
    _cat   = widget.filterCat;
    _bank  = widget.filterBank;
    _sort  = widget.sortBy;
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(text,
            style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );

  Widget _optionChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withValues(alpha: 0.15) : context.kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : context.kCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: selected ? AppColors.accent : context.kTextPrimary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              )),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final allCats = getAllCategories();
    final allBanks = getAllBanks();

    return Container(
      decoration: BoxDecoration(
        color: context.kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtros', style: TextStyle(color: context.kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),

            // ── Grupo / Tipo ──────────────────────────────────────────────
            _sectionLabel('TIPO DE LANÇAMENTO'),
            Wrap(
              children: [
                _optionChip('Todos', _group == 'all', () => setState(() => _group = 'all')),
                ...widget.groupLabels.entries.map((e) =>
                    _optionChip(e.value, _group == e.key, () => setState(() => _group = e.key))),
              ],
            ),

            // ── Categoria ─────────────────────────────────────────────────
            _sectionLabel('CATEGORIA'),
            Wrap(
              children: [
                _optionChip('Todas', _cat == 'all', () => setState(() => _cat = 'all')),
                ...allCats.map((c) => _optionChip(c.name, _cat == c.id, () => setState(() => _cat = c.id))),
              ],
            ),

            // ── Banco ─────────────────────────────────────────────────────
            _sectionLabel('CARTÃO / BANCO'),
            Wrap(
              children: [
                _optionChip('Todos', _bank == 'all', () => setState(() => _bank = 'all')),
                ...allBanks.map((b) => _optionChip(b.name, _bank == b.id, () => setState(() => _bank = b.id))),
                _optionChip('Nenhum', _bank == 'none', () => setState(() => _bank = 'none')),
              ],
            ),

            // ── Ordenação ────────────────────────────────────────────────
            _sectionLabel('ORDENAR POR'),
            Wrap(
              children: TxSort.values.map((s) =>
                  _optionChip(s.label, _sort == s, () => setState(() => _sort = s))).toList(),
            ),

            const SizedBox(height: 12),
            // Aplicar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  widget.onApply(_group, _cat, _bank, _sort);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


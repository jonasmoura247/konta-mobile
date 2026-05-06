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
import '../widgets/debit_chart.dart';

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
  final DateTime? initialMonth;
  const TransactionsScreen({super.key, this.initialMonth});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late DateTime _activeMonth;

  List<TransactionOccurrence> _creditOccurrences = [];
  List<TransactionOccurrence> _debitOccurrences = [];

  // Filtros da aba Cartão
  String _creditFilterGroup = 'all';
  String _creditFilterCat   = 'all';
  String _creditFilterBank  = 'all';
  TxSort _creditSortBy      = TxSort.dateAsc;

  // Filtros da aba Débito
  String _debitFilterCat  = 'all';
  String _debitFilterBank = 'all';
  TxSort _debitSortBy     = TxSort.dateAsc;

  static const _groupLabels = {
    'avista':       'À Vista',
    'parcelamento': 'Parcelamento',
    'assinatura':   'Assinatura',
  };
  static const _groupOrder = {'assinatura': 0, 'avista': 1, 'parcelamento': 2};

  @override
  void initState() {
    super.initState();
    _activeMonth = widget.initialMonth ?? DateTime.now();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    DatabaseService.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DatabaseService.dataVersion.removeListener(_load);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final settings = DatabaseService.getSettings();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    final allTx = DatabaseService.getAllTransactions();
    setState(() {
      _creditOccurrences = FinanceCalculator.getOccurrencesForMonth(allTx, _activeMonth, familyCount);
      _debitOccurrences  = FinanceCalculator.getDebitOccurrencesForMonth(allTx, _activeMonth, familyCount);
    });
  }

  // ── Dados computados ──────────────────────────────────────────────────────

  Map<String, double> get _byDebitCategory {
    final map = <String, double>{};
    for (final o in _debitOccurrences) {
      map[o.transaction.categoryId] = (map[o.transaction.categoryId] ?? 0) + o.amount;
    }
    return map;
  }

  double get _totalDebit => _debitOccurrences.fold(0.0, (s, o) => s + o.amount);

  // ── Filtragem e ordenação ─────────────────────────────────────────────────

  List<TransactionOccurrence> get _filteredCredit {
    List<TransactionOccurrence> list = [..._creditOccurrences];

    if (_creditFilterGroup != 'all') {
      list = list.where((o) => o.transaction.groupId == _creditFilterGroup).toList();
    }
    if (_creditFilterCat != 'all') {
      list = list.where((o) => o.transaction.categoryId == _creditFilterCat).toList();
    }
    if (_creditFilterBank != 'all') {
      if (_creditFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list.where((o) => o.transaction.bankId == _creditFilterBank).toList();
      }
    }
    return _applySorting(list, _creditSortBy);
  }

  List<TransactionOccurrence> get _filteredDebit {
    List<TransactionOccurrence> list = [..._debitOccurrences];
    if (_debitFilterCat != 'all') {
      list = list.where((o) => o.transaction.categoryId == _debitFilterCat).toList();
    }
    if (_debitFilterBank != 'all') {
      if (_debitFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list.where((o) => o.transaction.bankId == _debitFilterBank).toList();
      }
    }
    return _applySorting(list, _debitSortBy);
  }

  List<TransactionOccurrence> _applySorting(List<TransactionOccurrence> list, TxSort sort) {
    final cats = getAllCategories();
    String catName(String id) => cats.firstWhere((c) => c.id == id, orElse: () => cats.last).name;
    int groupRank(String id) => _groupOrder[id] ?? 99;

    switch (sort) {
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

  // ── Estados de filtro ativos ──────────────────────────────────────────────

  bool get _creditHasFilters =>
      _creditFilterGroup != 'all' || _creditFilterCat != 'all' ||
      _creditFilterBank != 'all' || _creditSortBy != TxSort.dateAsc;

  bool get _debitHasFilters =>
      _debitFilterCat != 'all' || _debitFilterBank != 'all' || _debitSortBy != TxSort.dateAsc;

  void _clearCurrentFilters() {
    setState(() {
      if (_tabCtrl.index == 0) {
        _creditFilterGroup = 'all';
        _creditFilterCat   = 'all';
        _creditFilterBank  = 'all';
        _creditSortBy      = TxSort.dateAsc;
      } else {
        _debitFilterCat  = 'all';
        _debitFilterBank = 'all';
        _debitSortBy     = TxSort.dateAsc;
      }
    });
  }

  void _showFilterSheet(bool isDebit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filterGroup:    isDebit ? 'all'         : _creditFilterGroup,
        filterCat:      isDebit ? _debitFilterCat  : _creditFilterCat,
        filterBank:     isDebit ? _debitFilterBank : _creditFilterBank,
        sortBy:         isDebit ? _debitSortBy     : _creditSortBy,
        groupLabels:    _groupLabels,
        showGroupFilter: !isDebit,
        onApply: (g, c, b, s) {
          setState(() {
            if (isDebit) {
              _debitFilterCat  = c;
              _debitFilterBank = b;
              _debitSortBy     = s;
            } else {
              _creditFilterGroup = g;
              _creditFilterCat   = c;
              _creditFilterBank  = b;
              _creditSortBy      = s;
            }
          });
        },
      ),
    );
  }

  // ── Construção da UI ──────────────────────────────────────────────────────

  Widget _buildFilterBar(BuildContext context, {required bool isDebit}) {
    final currency = DatabaseService.getSettings().currency;
    final filtered = isDebit ? _filteredDebit : _filteredCredit;
    final total = filtered.fold<double>(0, (s, o) => s + o.amount);
    final hasFilters = isDebit ? _debitHasFilters : _creditHasFilters;
    final activeSort = isDebit ? _debitSortBy : _creditSortBy;

    return Container(
      color: context.kBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showFilterSheet(isDebit),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasFilters ? AppColors.accent.withValues(alpha: 0.15) : context.kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasFilters ? AppColors.accent : context.kCardBorder,
                  width: hasFilters ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 14,
                      color: hasFilters ? AppColors.accent : context.kTextSecondary),
                  const SizedBox(width: 6),
                  Text('Filtrar',
                      style: TextStyle(
                        color: hasFilters ? AppColors.accent : context.kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  if (hasFilters) ...[
                    const SizedBox(width: 6),
                    Text('· ${activeSort.label}',
                        style: TextStyle(color: AppColors.accent.withValues(alpha: 0.8), fontSize: 10)),
                  ],
                ],
              ),
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearCurrentFilters,
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
          Text(
            '${filtered.length} · ${formatCurrency(total, currency: currency)}',
            style: TextStyle(color: context.kTextSecondary, fontSize: 11, fontFamily: 'JetBrainsMono'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<TransactionOccurrence> filtered, {
    required bool isDebit,
    bool hasFilters = false,
  }) {
    final currency = DatabaseService.getSettings().currency;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isDebit ? '💳' : '💸', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'Nenhum resultado para os filtros.'
                  : isDebit
                      ? 'Nenhum débito neste mês'
                      : 'Nenhum lançamento neste mês',
              style: TextStyle(color: context.kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDebitTab = _tabCtrl.index == 1;
    final creditFiltered = _filteredCredit;
    final debitFiltered  = _filteredDebit;

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
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.kTextSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Cartão'),
            Tab(text: 'Débito'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Aba Cartão ────────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterBar(context, isDebit: false),
              Expanded(
                child: _buildTransactionList(
                  context,
                  creditFiltered,
                  isDebit: false,
                  hasFilters: _creditHasFilters,
                ),
              ),
            ],
          ),

          // ── Aba Débito ────────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterBar(context, isDebit: true),
              // Gráfico de débito por categoria (visível quando há dados)
              if (_totalDebit > 0) ...[
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(16),
                  height: 196,
                  decoration: BoxDecoration(
                    color: context.kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.kCardBorder),
                  ),
                  child: DebitChart(
                    byCategory: _byDebitCategory,
                    totalDebit: _totalDebit,
                    currency: DatabaseService.getSettings().currency,
                  ),
                ),
              ],
              Expanded(
                child: _buildTransactionList(
                  context,
                  debitFiltered,
                  isDebit: true,
                  hasFilters: _debitHasFilters,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddTransactionForm(
            isDebit: isDebitTab,
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
  final bool showGroupFilter;
  final void Function(String, String, String, TxSort) onApply;

  const _FilterSheet({
    required this.filterGroup,
    required this.filterCat,
    required this.filterBank,
    required this.sortBy,
    required this.groupLabels,
    required this.onApply,
    this.showGroupFilter = true,
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

            // Tipo de lançamento (apenas aba Cartão)
            if (widget.showGroupFilter) ...[
              _sectionLabel('TIPO DE LANÇAMENTO'),
              Wrap(
                children: [
                  _optionChip('Todos', _group == 'all', () => setState(() => _group = 'all')),
                  ...widget.groupLabels.entries.map((e) =>
                      _optionChip(e.value, _group == e.key, () => setState(() => _group = e.key))),
                ],
              ),
            ],

            _sectionLabel('CATEGORIA'),
            Wrap(
              children: [
                _optionChip('Todas', _cat == 'all', () => setState(() => _cat = 'all')),
                ...allCats.map((c) => _optionChip(c.name, _cat == c.id, () => setState(() => _cat = c.id))),
              ],
            ),

            _sectionLabel('CARTÃO / BANCO'),
            Wrap(
              children: [
                _optionChip('Todos', _bank == 'all', () => setState(() => _bank = 'all')),
                ...allBanks.map((b) => _optionChip(b.name, _bank == b.id, () => setState(() => _bank = b.id))),
                _optionChip('Nenhum', _bank == 'none', () => setState(() => _bank = 'none')),
              ],
            ),

            _sectionLabel('ORDENAR POR'),
            Wrap(
              children: TxSort.values.map((s) =>
                  _optionChip(s.label, _sort == s, () => setState(() => _sort = s))).toList(),
            ),

            const SizedBox(height: 12),
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bank.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/finance_calculator.dart';
import '../services/month_selection_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_transaction_form.dart';
import '../widgets/month_picker_button.dart';
import '../widgets/debit_chart.dart';

// ── Sort options ──────────────────────────────────────────────────────────────
enum TxSort { dateAsc, dateDesc, amountDesc, amountAsc, nameAz, type, category, manual }

extension TxSortLabel on TxSort {
  String get label {
    switch (this) {
      case TxSort.dateAsc:   return 'Data ↑';
      case TxSort.dateDesc:  return 'Data ↓';
      case TxSort.amountDesc: return 'Maior valor';
      case TxSort.amountAsc: return 'Menor valor';
      case TxSort.nameAz:    return 'Nome A→Z';
      case TxSort.type:      return 'Tipo da conta';
      case TxSort.category:  return 'Categoria';
      case TxSort.manual:    return 'Manual';
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
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;      // 4 abas: Todos | Cartão | Pix | Dinheiro
  late final TabController _cartaoSubCtrl; // 2 sub-abas: Crédito | Débito
  late DateTime _activeMonth;

  List<TransactionOccurrence> _creditOccurrences = [];
  List<TransactionOccurrence> _debitOccurrences = [];

  // Ordens manuais por aba — carregadas do banco e atualizadas em tempo real
  Map<String, List<String>> _txOrders = {};
  bool _initialLoadDone = false;

  static const _cartaoGroups = {
    'avista': 'À Vista',
    'parcelamento': 'Parcelamento',
    'assinatura': 'Assinatura',
  };
  static const _groupOrder = {'assinatura': 0, 'avista': 1, 'parcelamento': 2};

  // ── Estado dos filtros ────────────────────────────────────────────────────
  String _todosFilterCat = 'all';
  String _todosFilterBank = 'all';
  TxSort _todosSortBy = TxSort.dateAsc;

  String _cartaoCreditFilterGroup = 'all';
  String _cartaoCreditFilterCat = 'all';
  String _cartaoCreditFilterBank = 'all';
  TxSort _cartaoCreditSortBy = TxSort.dateAsc;

  String _cartaoDebitFilterCat = 'all';
  String _cartaoDebitFilterBank = 'all';
  TxSort _cartaoDebitSortBy = TxSort.dateAsc;

  String _pixFilterCat = 'all';
  String _pixFilterBank = 'all';
  TxSort _pixSortBy = TxSort.dateAsc;

  String _dinheiroFilterCat = 'all';
  TxSort _dinheiroSortBy = TxSort.dateAsc;

  DateTime _monthStart(DateTime date) => MonthSelectionService.normalize(date);
  DateTime _nextMonthStart(DateTime date) => DateTime(date.year, date.month + 1);

  @override
  void initState() {
    super.initState();
    _activeMonth =
        _monthStart(widget.initialMonth ?? MonthSelectionService.activeMonth.value);
    MonthSelectionService.setActiveMonth(_activeMonth);
    _tabCtrl = TabController(length: 4, vsync: this);
    _cartaoSubCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() { if (mounted) setState(() {}); });
    _cartaoSubCtrl.addListener(() { if (mounted) setState(() {}); });
    DatabaseService.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    DatabaseService.dataVersion.removeListener(_load);
    _tabCtrl.dispose();
    _cartaoSubCtrl.dispose();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    MonthSelectionService.setActiveMonth(_activeMonth);
    final settings = DatabaseService.getSettings();
    final familyCount = settings.familyMode ? settings.familyCount : 1;
    final allTx = DatabaseService.getAllTransactions();
    setState(() {
      _creditOccurrences = FinanceCalculator.getOccurrencesForMonth(
          allTx, _activeMonth, familyCount);
      _debitOccurrences = FinanceCalculator.getDebitOccurrencesForMonth(
          allTx, _activeMonth, familyCount);
      _txOrders = {
        'todos':         DatabaseService.getTransactionOrder('todos'),
        'cartao_credit': DatabaseService.getTransactionOrder('cartao_credit'),
        'cartao_debit':  DatabaseService.getTransactionOrder('cartao_debit'),
        'pix':           DatabaseService.getTransactionOrder('pix'),
        'dinheiro':      DatabaseService.getTransactionOrder('dinheiro'),
      };
      // Restaura modo manual na primeira carga se houver ordem salva
      if (!_initialLoadDone) {
        _initialLoadDone = true;
        if ((_txOrders['todos'] ?? []).isNotEmpty) { _todosSortBy = TxSort.manual; }
        if ((_txOrders['cartao_credit'] ?? []).isNotEmpty) { _cartaoCreditSortBy = TxSort.manual; }
        if ((_txOrders['cartao_debit'] ?? []).isNotEmpty) { _cartaoDebitSortBy = TxSort.manual; }
        if ((_txOrders['pix'] ?? []).isNotEmpty) { _pixSortBy = TxSort.manual; }
        if ((_txOrders['dinheiro'] ?? []).isNotEmpty) { _dinheiroSortBy = TxSort.manual; }
      }
    });
  }

  // ── Dados computados ──────────────────────────────────────────────────────

  Map<String, double> get _byCartaoDebitCategory {
    final map = <String, double>{};
    for (final o in _filteredCartaoDebito) {
      map[o.transaction.categoryId] =
          (map[o.transaction.categoryId] ?? 0) + o.amount;
    }
    return map;
  }

  double get _totalCartaoDebit =>
      _filteredCartaoDebito.fold(0.0, (s, o) => s + o.amount);

  // ── Filtragem ─────────────────────────────────────────────────────────────

  List<TransactionOccurrence> get _filteredAll {
    List<TransactionOccurrence> list = [
      ..._creditOccurrences,
      ..._debitOccurrences,
    ];
    if (_todosFilterCat != 'all') {
      list = list.where((o) => o.transaction.categoryId == _todosFilterCat).toList();
    }
    if (_todosFilterBank != 'all') {
      if (_todosFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list.where((o) => o.transaction.bankId == _todosFilterBank).toList();
      }
    }
    return _applySorting(list, _todosSortBy, 'todos');
  }

  /// avista, parcelamento, assinatura + Cartão Pix (groupId=avista, subtype=pix)
  List<TransactionOccurrence> get _filteredCartaoCredito {
    List<TransactionOccurrence> list = List.of(_creditOccurrences);
    if (_cartaoCreditFilterGroup != 'all') {
      list = list
          .where((o) => o.transaction.groupId == _cartaoCreditFilterGroup)
          .toList();
    }
    if (_cartaoCreditFilterCat != 'all') {
      list = list
          .where((o) => o.transaction.categoryId == _cartaoCreditFilterCat)
          .toList();
    }
    if (_cartaoCreditFilterBank != 'all') {
      if (_cartaoCreditFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list
            .where((o) => o.transaction.bankId == _cartaoCreditFilterBank)
            .toList();
      }
    }
    return _applySorting(list, _cartaoCreditSortBy, 'cartao_credit');
  }

  /// debito_direto + legado (paymentSubtype null com groupId='debito')
  List<TransactionOccurrence> get _filteredCartaoDebito {
    List<TransactionOccurrence> list = _debitOccurrences
        .where((o) =>
            o.transaction.paymentSubtype == 'debito_direto' ||
            o.transaction.paymentSubtype == null)
        .toList();
    if (_cartaoDebitFilterCat != 'all') {
      list = list
          .where((o) => o.transaction.categoryId == _cartaoDebitFilterCat)
          .toList();
    }
    if (_cartaoDebitFilterBank != 'all') {
      if (_cartaoDebitFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list
            .where((o) => o.transaction.bankId == _cartaoDebitFilterBank)
            .toList();
      }
    }
    return _applySorting(list, _cartaoDebitSortBy, 'cartao_debit');
  }

  List<TransactionOccurrence> get _filteredPix {
    List<TransactionOccurrence> list = _debitOccurrences
        .where((o) => o.transaction.paymentSubtype == 'pix')
        .toList();
    if (_pixFilterCat != 'all') {
      list = list.where((o) => o.transaction.categoryId == _pixFilterCat).toList();
    }
    if (_pixFilterBank != 'all') {
      if (_pixFilterBank == 'none') {
        list = list.where((o) => o.transaction.bankId == null).toList();
      } else {
        list = list.where((o) => o.transaction.bankId == _pixFilterBank).toList();
      }
    }
    return _applySorting(list, _pixSortBy, 'pix');
  }

  List<TransactionOccurrence> get _filteredDinheiro {
    List<TransactionOccurrence> list = _debitOccurrences
        .where((o) => o.transaction.paymentSubtype == 'dinheiro')
        .toList();
    if (_dinheiroFilterCat != 'all') {
      list = list
          .where((o) => o.transaction.categoryId == _dinheiroFilterCat)
          .toList();
    }
    return _applySorting(list, _dinheiroSortBy, 'dinheiro');
  }

  List<TransactionOccurrence> _applySorting(
      List<TransactionOccurrence> list, TxSort sort, [String tabKey = '']) {
    final cats = getAllCategories();
    String catName(String id) =>
        cats.firstWhere((c) => c.id == id, orElse: () => cats.last).name;
    int groupRank(String id) => _groupOrder[id] ?? 99;

    switch (sort) {
      case TxSort.dateAsc:
        list.sort((a, b) => a.billingDate.compareTo(b.billingDate));
      case TxSort.dateDesc:
        list.sort((a, b) => b.billingDate.compareTo(a.billingDate));
      case TxSort.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case TxSort.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
      case TxSort.nameAz:
        list.sort((a, b) =>
            a.transaction.description.compareTo(b.transaction.description));
      case TxSort.type:
        list.sort((a, b) {
          final t = groupRank(a.transaction.groupId) -
              groupRank(b.transaction.groupId);
          if (t != 0) return t;
          final c = catName(a.transaction.categoryId)
              .compareTo(catName(b.transaction.categoryId));
          if (c != 0) return c;
          return a.billingDate.compareTo(b.billingDate);
        });
      case TxSort.category:
        list.sort((a, b) {
          final c = catName(a.transaction.categoryId)
              .compareTo(catName(b.transaction.categoryId));
          if (c != 0) return c;
          final t = groupRank(a.transaction.groupId) -
              groupRank(b.transaction.groupId);
          if (t != 0) return t;
          return a.billingDate.compareTo(b.billingDate);
        });
      case TxSort.manual:
        final order = _txOrders[tabKey] ?? [];
        list.sort((a, b) {
          int ai = order.indexOf(a.transaction.id);
          int bi = order.indexOf(b.transaction.id);
          if (ai == -1) ai = 999999;
          if (bi == -1) bi = 999999;
          return ai.compareTo(bi);
        });
    }
    return list;
  }

  /// Mescla a ordem manual quando filtros estão ativos.
  /// Itens visíveis são reposicionados; itens ocultos pelos filtros mantêm
  /// suas posições relativas na lista completa.
  List<String> _mergeOrder(
      List<String> stored, List<String> visibleBefore, List<String> visibleAfter) {
    if (stored.isEmpty) return visibleAfter;

    final visibleSet = visibleBefore.toSet();
    final positions = <int>[];
    for (int i = 0; i < stored.length; i++) {
      if (visibleSet.contains(stored[i])) positions.add(i);
    }

    final result = List<String>.from(stored);
    positions.sort();
    for (int i = 0; i < positions.length && i < visibleAfter.length; i++) {
      result[positions[i]] = visibleAfter[i];
    }

    for (final id in visibleAfter) {
      if (!stored.contains(id)) result.add(id);
    }

    return result;
  }

  void _setSortManual(String tabKey) {
    switch (tabKey) {
      case 'todos':         _todosSortBy = TxSort.manual;
      case 'cartao_credit': _cartaoCreditSortBy = TxSort.manual;
      case 'cartao_debit':  _cartaoDebitSortBy = TxSort.manual;
      case 'pix':           _pixSortBy = TxSort.manual;
      case 'dinheiro':      _dinheiroSortBy = TxSort.manual;
    }
  }

  // ── Estados de filtro ativos ──────────────────────────────────────────────

  bool get _todosHasFilters =>
      _todosFilterCat != 'all' ||
      _todosFilterBank != 'all' ||
      _todosSortBy != TxSort.dateAsc;

  bool get _cartaoCreditHasFilters =>
      _cartaoCreditFilterGroup != 'all' ||
      _cartaoCreditFilterCat != 'all' ||
      _cartaoCreditFilterBank != 'all' ||
      _cartaoCreditSortBy != TxSort.dateAsc;

  bool get _cartaoDebitHasFilters =>
      _cartaoDebitFilterCat != 'all' ||
      _cartaoDebitFilterBank != 'all' ||
      _cartaoDebitSortBy != TxSort.dateAsc;

  bool get _pixHasFilters =>
      _pixFilterCat != 'all' ||
      _pixFilterBank != 'all' ||
      _pixSortBy != TxSort.dateAsc;

  bool get _dinheiroHasFilters =>
      _dinheiroFilterCat != 'all' || _dinheiroSortBy != TxSort.dateAsc;

  TxSort get _currentSort => switch (_tabCtrl.index) {
        0 => _todosSortBy,
        1 => _cartaoSubCtrl.index == 0 ? _cartaoCreditSortBy : _cartaoDebitSortBy,
        2 => _pixSortBy,
        3 => _dinheiroSortBy,
        _ => TxSort.dateAsc,
      };

  String _currentTabKey() => switch (_tabCtrl.index) {
        0 => 'todos',
        1 => _cartaoSubCtrl.index == 0 ? 'cartao_credit' : 'cartao_debit',
        2 => 'pix',
        3 => 'dinheiro',
        _ => '',
      };

  void _clearCurrentFilters() {
    final tabKey = _currentTabKey();
    setState(() {
      switch (_tabCtrl.index) {
        case 0:
          _todosFilterCat = 'all';
          _todosFilterBank = 'all';
          _todosSortBy = TxSort.dateAsc;
          _txOrders['todos'] = [];
        case 1:
          if (_cartaoSubCtrl.index == 0) {
            _cartaoCreditFilterGroup = 'all';
            _cartaoCreditFilterCat = 'all';
            _cartaoCreditFilterBank = 'all';
            _cartaoCreditSortBy = TxSort.dateAsc;
            _txOrders['cartao_credit'] = [];
          } else {
            _cartaoDebitFilterCat = 'all';
            _cartaoDebitFilterBank = 'all';
            _cartaoDebitSortBy = TxSort.dateAsc;
            _txOrders['cartao_debit'] = [];
          }
        case 2:
          _pixFilterCat = 'all';
          _pixFilterBank = 'all';
          _pixSortBy = TxSort.dateAsc;
          _txOrders['pix'] = [];
        case 3:
          _dinheiroFilterCat = 'all';
          _dinheiroSortBy = TxSort.dateAsc;
          _txOrders['dinheiro'] = [];
      }
    });
    if (tabKey.isNotEmpty) {
      unawaited(DatabaseService.saveTransactionOrder(tabKey, []));
    }
  }

  void _showFilterSheet() {
    final tabIdx = _tabCtrl.index;
    final isCartaoCredit = tabIdx == 1 && _cartaoSubCtrl.index == 0;
    final isCartaoDebit = tabIdx == 1 && _cartaoSubCtrl.index == 1;
    final isPix = tabIdx == 2;
    final isDinheiro = tabIdx == 3;

    String filterGroup = 'all';
    String filterCat = 'all';
    String filterBank = 'all';
    TxSort sortBy = TxSort.dateAsc;

    if (tabIdx == 0) {
      filterCat = _todosFilterCat;
      filterBank = _todosFilterBank;
      sortBy = _todosSortBy;
    } else if (isCartaoCredit) {
      filterGroup = _cartaoCreditFilterGroup;
      filterCat = _cartaoCreditFilterCat;
      filterBank = _cartaoCreditFilterBank;
      sortBy = _cartaoCreditSortBy;
    } else if (isCartaoDebit) {
      filterCat = _cartaoDebitFilterCat;
      filterBank = _cartaoDebitFilterBank;
      sortBy = _cartaoDebitSortBy;
    } else if (isPix) {
      filterCat = _pixFilterCat;
      filterBank = _pixFilterBank;
      sortBy = _pixSortBy;
    } else if (isDinheiro) {
      filterCat = _dinheiroFilterCat;
      sortBy = _dinheiroSortBy;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filterGroup: filterGroup,
        filterCat: filterCat,
        filterBank: filterBank,
        sortBy: sortBy,
        groupLabels: isCartaoCredit ? _cartaoGroups : const {},
        showGroupFilter: isCartaoCredit,
        showBankFilter: !isDinheiro,
        onApply: (g, c, b, s) {
          setState(() {
            if (tabIdx == 0) {
              _todosFilterCat = c;
              _todosFilterBank = b;
              _todosSortBy = s;
            } else if (isCartaoCredit) {
              _cartaoCreditFilterGroup = g;
              _cartaoCreditFilterCat = c;
              _cartaoCreditFilterBank = b;
              _cartaoCreditSortBy = s;
            } else if (isCartaoDebit) {
              _cartaoDebitFilterCat = c;
              _cartaoDebitFilterBank = b;
              _cartaoDebitSortBy = s;
            } else if (isPix) {
              _pixFilterCat = c;
              _pixFilterBank = b;
              _pixSortBy = s;
            } else if (isDinheiro) {
              _dinheiroFilterCat = c;
              _dinheiroSortBy = s;
            }
          });
        },
      ),
    );
  }

  // ── Edição ────────────────────────────────────────────────────────────────

  Future<void> _showEditForm(TransactionOccurrence occurrence) async {
    final original = occurrence.transaction;
    final isSubscription = original.groupId == 'assinatura';
    final activeMonth = _monthStart(_activeMonth);
    MonthSelectionService.setActiveMonth(activeMonth);
    final hasHistory = isSubscription &&
        DateTime(original.startDate.year, original.startDate.month)
            .isBefore(activeMonth);

    final editedResult = await showModalBottomSheet<TransactionFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionForm(
        editing: original,
        returnTransaction: true,
        subscriptionEditMonth: hasHistory ? activeMonth : null,
        onSave: (edited) async {
          if (hasHistory) {
            if (!mounted) return;
            final applyFromThis = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: context.kCard,
                title: Text('Aplicar alteração',
                    style: TextStyle(color: context.kTextPrimary)),
                content: Text(
                  'Aplicar as alterações a partir de ${formatMonth(activeMonth)}?\n'
                  'Meses anteriores serão preservados.',
                  style: TextStyle(color: context.kTextSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Editar desde o início'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'A partir de ${formatMonth(activeMonth)}',
                      style: const TextStyle(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            );
            if (!mounted) return;
            if (applyFromThis == null) return;
            if (applyFromThis == true) {
              original.cancelledFrom = activeMonth;
              await DatabaseService.updateTransaction(original);
              final newTx = Transaction(
                id: const Uuid().v4(),
                groupId: 'assinatura',
                categoryId: edited.categoryId,
                description: edited.description,
                totalAmount: edited.totalAmount,
                installments: 1,
                startDate: activeMonth,
                isSubscription: true,
                bankId: edited.bankId,
                familyMode: edited.familyMode,
                familyMember: edited.familyMember,
                createdAt: DateTime.now(),
              );
              await DatabaseService.addTransaction(newTx);
            } else {
              await DatabaseService.updateTransaction(edited);
            }
          } else {
            await DatabaseService.updateTransaction(edited);
          }
        },
      ),
    );
    if (!mounted || editedResult == null) return;
    await _saveEditedTransaction(
      original: original,
      result: editedResult,
      activeMonth: activeMonth,
      hasHistory: hasHistory,
    );
  }

  Future<void> _saveEditedTransaction({
    required Transaction original,
    required TransactionFormResult result,
    required DateTime activeMonth,
    required bool hasHistory,
  }) async {
    final edited = result.transaction;
    if (hasHistory &&
        result.subscriptionEditScope == SubscriptionEditScope.fromMonth) {
      await _versionSubscriptionFromMonth(
        original: original,
        edited: edited,
        activeMonth: activeMonth,
      );
      return;
    }

    if (hasHistory &&
        result.subscriptionEditScope == SubscriptionEditScope.fromStart &&
        edited.id.isEmpty) {
      final applyFromThis = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.kCard,
          title: Text('Aplicar alteração',
              style: TextStyle(color: context.kTextPrimary)),
          content: Text(
            'Aplicar as alterações a partir de ${formatMonth(activeMonth)}?\n'
            'Meses anteriores serão preservados.',
            style: TextStyle(color: context.kTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Editar desde o início'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'A partir de ${formatMonth(activeMonth)}',
                style: const TextStyle(color: AppColors.accent),
              ),
            ),
          ],
        ),
      );
      if (!mounted || applyFromThis == null) return;
      if (applyFromThis) {
        original.cancelledFrom = activeMonth;
        await DatabaseService.updateTransaction(original);
        await DatabaseService.addTransaction(Transaction(
          id: const Uuid().v4(),
          groupId: 'assinatura',
          categoryId: edited.categoryId,
          description: edited.description,
          totalAmount: edited.totalAmount,
          installments: 1,
          startDate: activeMonth,
          isSubscription: true,
          bankId: edited.bankId,
          familyMode: edited.familyMode,
          familyMember: edited.familyMember,
          createdAt: DateTime.now(),
        ));
        return;
      }
    }

    await DatabaseService.updateTransaction(edited);
  }

  Future<void> _versionSubscriptionFromMonth({
    required Transaction original,
    required Transaction edited,
    required DateTime activeMonth,
  }) async {
    final seriesId = original.subscriptionSeriesId ?? original.id;
    final originalHadSeriesId = original.subscriptionSeriesId != null;
    original.subscriptionSeriesId = seriesId;
    original.cancelledFrom = activeMonth;
    await DatabaseService.updateTransaction(original);

    final futureSegments = DatabaseService.getAllTransactions().where((t) {
      final tSeriesId = t.subscriptionSeriesId ?? t.id;
      final sameLegacySubscription = !originalHadSeriesId &&
          t.subscriptionSeriesId == null &&
          t.description == original.description &&
          t.categoryId == original.categoryId &&
          t.bankId == original.bankId &&
          t.familyMode == original.familyMode &&
          t.familyMember == original.familyMember;
      return t.id != original.id &&
          t.groupId == 'assinatura' &&
          (tSeriesId == seriesId || sameLegacySubscription) &&
          !_monthStart(t.startDate).isBefore(activeMonth);
    }).toList();

    for (final futureSegment in futureSegments) {
      await DatabaseService.deleteTransaction(futureSegment);
    }

    await DatabaseService.addTransaction(Transaction(
      id: const Uuid().v4(),
      groupId: 'assinatura',
      categoryId: edited.categoryId,
      description: edited.description,
      totalAmount: edited.totalAmount,
      installments: 1,
      startDate: activeMonth,
      isSubscription: true,
      bankId: edited.bankId,
      familyMode: edited.familyMode,
      familyMember: edited.familyMember,
      createdAt: DateTime.now(),
      subscriptionSeriesId: seriesId,
    ));
  }

  // ── Exclusão ──────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(TransactionOccurrence occurrence) async {
    final t = occurrence.transaction;
    if (t.groupId == 'assinatura') {
      await _confirmDeleteSubscription(t);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogContext.kCard,
          title: Text('Excluir lançamento?',
              style: TextStyle(color: dialogContext.kTextPrimary)),
          content: Text(t.description,
              style: TextStyle(color: dialogContext.kTextSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      await _runAfterDeleteDialog(
        confirmed,
        () => DatabaseService.deleteTransaction(t),
      );
    }
  }

  Future<void> _confirmDeleteSubscription(Transaction t) async {
    final activeMonth = _monthStart(_activeMonth);
    final isFirstMonth = isSameMonth(t.startDate, activeMonth);

    if (isFirstMonth) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogContext.kCard,
          title: Text('Excluir assinatura?',
              style: TextStyle(color: dialogContext.kTextPrimary)),
          content: Text(t.description,
              style: TextStyle(color: dialogContext.kTextSecondary)),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      await _runAfterDeleteDialog(
        confirmed,
        () => DatabaseService.deleteTransaction(t),
      );
    } else if (t.cancelledFrom != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogContext.kCard,
          title: Text('Remover cobrança?',
              style: TextStyle(color: dialogContext.kTextPrimary)),
          content: Text(
            '${t.description}\n\nEsta assinatura já está cancelada. Remover a partir de ${formatMonth(activeMonth)}?\nMeses anteriores são preservados.',
            style: TextStyle(color: dialogContext.kTextSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remover',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      await _runAfterDeleteDialog(confirmed, () async {
        t.cancelledFrom = activeMonth;
        await DatabaseService.updateTransaction(t);
      });
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: dialogContext.kCard,
          title: Text('Cancelar assinatura?',
              style: TextStyle(color: dialogContext.kTextPrimary)),
          content: Text(
            '${t.description}\n\nCancelar após ${formatMonth(activeMonth)}?\nEste mês permanece cobrado e os próximos ficam zerados.',
            style: TextStyle(color: dialogContext.kTextSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Voltar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancelar assinatura',
                  style: TextStyle(color: AppColors.expense)),
            ),
          ],
        ),
      );
      await _runAfterDeleteDialog(confirmed, () async {
        t.cancelledFrom = _nextMonthStart(activeMonth);
        await DatabaseService.updateTransaction(t);
      });
    }
  }

  Future<void> _runAfterDeleteDialog(
    bool? confirmed,
    Future<void> Function() action,
  ) async {
    if (confirmed != true || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir: $error')),
      );
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildFilterBar(
    BuildContext context, {
    required List<TransactionOccurrence> filtered,
    required bool hasFilters,
  }) {
    final currency = DatabaseService.getSettings().currency;
    final total = filtered.fold<double>(0, (s, o) => s + o.amount);

    return Container(
      color: context.kBg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasFilters
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : context.kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasFilters ? AppColors.accent : context.kCardBorder,
                  width: hasFilters ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded,
                      size: 14,
                      color: hasFilters
                          ? AppColors.accent
                          : context.kTextSecondary),
                  const SizedBox(width: 6),
                  Text('Filtrar',
                      style: TextStyle(
                        color: hasFilters
                            ? AppColors.accent
                            : context.kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                  if (hasFilters && _currentSort != TxSort.manual) ...[
                    const SizedBox(width: 6),
                    Text('· ${_currentSort.label}',
                        style: TextStyle(
                            color: AppColors.accent.withValues(alpha: 0.8),
                            fontSize: 10)),
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
                  border: Border.all(
                      color: AppColors.expense.withValues(alpha: 0.4)),
                ),
                child: const Text('Limpar',
                    style: TextStyle(
                        color: AppColors.expense,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${filtered.length} · ${formatCurrency(total, currency: currency)}',
            style: TextStyle(
                color: context.kTextSecondary,
                fontSize: 11,
                fontFamily: 'JetBrainsMono'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<TransactionOccurrence> filtered, {
    String emptyLabel = 'Nenhum lançamento neste mês',
    String emptyEmoji = '💸',
    bool hasFilters = false,
    String tabKey = '',
  }) {
    final currency = DatabaseService.getSettings().currency;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emptyEmoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              hasFilters ? 'Nenhum resultado para os filtros.' : emptyLabel,
              style: TextStyle(color: context.kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Lista sempre arrastável — drag handle embutido no card
    final snapshot = filtered.map((o) => o.transaction.id).toList();

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      buildDefaultDragHandles: false,
      proxyDecorator: (child, _, __) => Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        shadowColor: AppColors.accent.withValues(alpha: 0.28),
        color: Colors.transparent,
        child: Stack(
          children: [
            child,
            // Contorno accent alinhado com a borda visual do card (desconta margin: 4)
            Positioned(
              top: 4, bottom: 4, left: 0, right: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.72),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final reorderedIds = List<String>.from(snapshot);
        final moved = reorderedIds.removeAt(oldIndex);
        reorderedIds.insert(newIndex, moved);
        final stored = _txOrders[tabKey] ?? [];
        final merged = _mergeOrder(stored, snapshot, reorderedIds);
        setState(() {
          _txOrders[tabKey] = merged;
          _setSortManual(tabKey);
        });
        unawaited(DatabaseService.saveTransactionOrder(tabKey, merged));
      },
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final o = filtered[i];
        return TransactionCard(
          key: ValueKey(o.transaction.id),
          occurrence: o,
          currency: currency,
          onEdit: () => _showEditForm(o),
          onDelete: () => _confirmDelete(o),
          dragHandle: ReorderableDragStartListener(
            index: i,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Icon(
                Icons.drag_handle_rounded,
                color: ctx.kTextSecondary,
                size: 15,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Aba Cartão (com sub-abas Crédito / Débito) ────────────────────────────

  Widget _buildCartaoTab(BuildContext context) {
    final creditFiltered = _filteredCartaoCredito;
    final debitFiltered = _filteredCartaoDebito;
    final subIdx = _cartaoSubCtrl.index;

    return Column(
      children: [
        // Sub-TabBar
        Container(
          color: context.kBg,
          child: TabBar(
            controller: _cartaoSubCtrl,
            labelColor: AppColors.accent,
            unselectedLabelColor: context.kTextSecondary,
            indicatorColor: AppColors.accent,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Crédito'),
              Tab(text: 'Débito'),
            ],
          ),
        ),
        _buildFilterBar(
          context,
          filtered: subIdx == 0 ? creditFiltered : debitFiltered,
          hasFilters:
              subIdx == 0 ? _cartaoCreditHasFilters : _cartaoDebitHasFilters,
        ),
        Expanded(
          child: TabBarView(
            controller: _cartaoSubCtrl,
            children: [
              // Crédito
              _buildList(
                context,
                creditFiltered,
                emptyEmoji: '💳',
                emptyLabel: 'Nenhum lançamento de cartão neste mês',
                hasFilters: _cartaoCreditHasFilters,
                tabKey: 'cartao_credit',
              ),
              // Débito
              Column(
                children: [
                  if (_totalCartaoDebit > 0) ...[
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
                        byCategory: _byCartaoDebitCategory,
                        totalDebit: _totalCartaoDebit,
                        currency: DatabaseService.getSettings().currency,
                      ),
                    ),
                  ],
                  Expanded(
                    child: _buildList(
                      context,
                      debitFiltered,
                      emptyEmoji: '💳',
                      emptyLabel: 'Nenhum débito de cartão neste mês',
                      hasFilters: _cartaoDebitHasFilters,
                      tabKey: 'cartao_debit',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  PaymentMode get _fabMode => switch (_tabCtrl.index) {
        2 => PaymentMode.pix,
        3 => PaymentMode.dinheiro,
        _ => PaymentMode.cartao,
      };

  String get _fabGroupId {
    if (_tabCtrl.index == 1 && _cartaoSubCtrl.index == 1) return 'debito';
    return 'avista';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allFiltered = _filteredAll;
    final pixFiltered = _filteredPix;
    final dinheiroFiltered = _filteredDinheiro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lançamentos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: MonthPickerButton(
              activeMonth: _activeMonth,
              onChanged: (m) {
                _activeMonth = _monthStart(m);
                MonthSelectionService.setActiveMonth(_activeMonth);
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
            Tab(text: 'Todos'),
            Tab(text: 'Cartão'),
            Tab(text: 'Pix'),
            Tab(text: 'Dinheiro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Todos ──────────────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterBar(context,
                  filtered: allFiltered, hasFilters: _todosHasFilters),
              Expanded(
                child: _buildList(context, allFiltered,
                    hasFilters: _todosHasFilters, tabKey: 'todos'),
              ),
            ],
          ),

          // ── Cartão ─────────────────────────────────────────────────────────
          _buildCartaoTab(context),

          // ── Pix ────────────────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterBar(context,
                  filtered: pixFiltered, hasFilters: _pixHasFilters),
              Expanded(
                child: _buildList(context, pixFiltered,
                    emptyEmoji: '📱',
                    emptyLabel: 'Nenhum Pix neste mês',
                    hasFilters: _pixHasFilters,
                    tabKey: 'pix'),
              ),
            ],
          ),

          // ── Dinheiro ───────────────────────────────────────────────────────
          Column(
            children: [
              _buildFilterBar(context,
                  filtered: dinheiroFiltered, hasFilters: _dinheiroHasFilters),
              Expanded(
                child: _buildList(context, dinheiroFiltered,
                    emptyEmoji: '💵',
                    emptyLabel: 'Nenhum pagamento em dinheiro neste mês',
                    hasFilters: _dinheiroHasFilters,
                    tabKey: 'dinheiro'),
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
            initialMode: _fabMode,
            initialGroupId: _fabGroupId,
            initialDate: _activeMonth,
            onSave: (t) async {
              await DatabaseService.addTransaction(t);
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
  final bool showBankFilter;
  final void Function(String, String, String, TxSort) onApply;

  const _FilterSheet({
    required this.filterGroup,
    required this.filterCat,
    required this.filterBank,
    required this.sortBy,
    required this.groupLabels,
    required this.onApply,
    this.showGroupFilter = false,
    this.showBankFilter = true,
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
    _cat = widget.filterCat;
    _bank = widget.filterBank;
    _sort = widget.sortBy;
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Text(text,
            style: TextStyle(
                color: context.kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      );

  Widget _optionChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.15)
                : context.kCard,
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
    final allCats = getVisibleCategories();
    final allBanks = getVisibleBanks();

    return Container(
      decoration: BoxDecoration(
        color: context.kBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.kCardBorder,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtros',
                    style: TextStyle(
                        color: context.kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),

            if (widget.showGroupFilter) ...[
              _sectionLabel('TIPO DE LANÇAMENTO'),
              Wrap(
                children: [
                  _optionChip('Todos', _group == 'all',
                      () => setState(() => _group = 'all')),
                  ...widget.groupLabels.entries.map((e) => _optionChip(
                      e.value,
                      _group == e.key,
                      () => setState(() => _group = e.key))),
                ],
              ),
            ],

            _sectionLabel('CATEGORIA'),
            Wrap(
              children: [
                _optionChip('Todas', _cat == 'all',
                    () => setState(() => _cat = 'all')),
                ...allCats.map((c) => _optionChip(
                    c.name, _cat == c.id, () => setState(() => _cat = c.id))),
              ],
            ),

            if (widget.showBankFilter) ...[
              _sectionLabel('CARTÃO / BANCO'),
              Wrap(
                children: [
                  _optionChip('Todos', _bank == 'all',
                      () => setState(() => _bank = 'all')),
                  ...allBanks.map((b) => _optionChip(b.name, _bank == b.id,
                      () => setState(() => _bank = b.id))),
                  _optionChip('Nenhum', _bank == 'none',
                      () => setState(() => _bank = 'none')),
                ],
              ),
            ],

            _sectionLabel('ORDENAR POR'),
            Wrap(
              children: TxSort.values
                  .where((s) => s != TxSort.manual)
                  .map((s) => _optionChip(
                      s.label, _sort == s, () => setState(() => _sort = s)))
                  .toList(),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  widget.onApply(_group, _cat, _bank, _sort);
                  Navigator.pop(context);
                },
                child: const Text('Aplicar filtros',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

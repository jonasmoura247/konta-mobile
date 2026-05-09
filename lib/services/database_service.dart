import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/app_settings.dart';
import '../models/reserve.dart';
import '../models/reserve_snapshot.dart';
import '../models/reminder.dart';
import '../models/goal.dart';

class DatabaseService {
  // Incrementado sempre que dados críticos mudam (limpar, importar).
  // As telas escutam isso para se atualizar instantaneamente.
  static final dataVersion = ValueNotifier<int>(0);
  static void _notify() => dataVersion.value++;
  static Box<Transaction> get txBox => Hive.box<Transaction>('transactions');
  static Box<Income> get incomeBox => Hive.box<Income>('incomes');
  static Box<AppSettings> get settingsBox => Hive.box<AppSettings>('settings');
  static Box<String> get metaBox => Hive.box<String>('meta');
  static Box<Reserve> get reservesBox => Hive.box<Reserve>('reserves');
  static Box<ReserveSnapshot> get snapshotsBox =>
      Hive.box<ReserveSnapshot>('reserve_snapshots');
  static Box<Reminder> get remindersBox => Hive.box<Reminder>('reminders');
  static Box<Goal> get goalsBox => Hive.box<Goal>('goals');

  // --- META: Custom Categories ---

  static List<Map<String, dynamic>> getCustomCategories() {
    final json = metaBox.get('custom_categories', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomCategories(
      List<Map<String, dynamic>> cats) async {
    await metaBox.put('custom_categories', jsonEncode(cats));
    _notify();
  }

  // --- META: Custom Banks ---

  static List<Map<String, dynamic>> getCustomBanks() {
    final json = metaBox.get('custom_banks', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomBanks(List<Map<String, dynamic>> banks) async {
    await metaBox.put('custom_banks', jsonEncode(banks));
    _notify();
  }

  // --- META: Hidden Banks ---

  static const _defaultHiddenBanks = [
    'bradesco', 'bb', 'santander', 'sicoob', 'sicredi', 'btg', 'safra',
    'c6', 'neon', 'next', 'picpay', 'pagbank', 'mercadopago', 'stone', 'xp', 'will',
  ];

  static List<String> getHiddenBankIds() {
    final raw = metaBox.get('hidden_banks');
    if (raw == null) return List.from(_defaultHiddenBanks);
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> saveHiddenBankIds(List<String> ids) async {
    await metaBox.put('hidden_banks', jsonEncode(ids));
    _notify();
  }

  // --- META: Hidden Categories ---

  static List<String> getHiddenCategoryIds() {
    final raw = metaBox.get('hidden_categories');
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> saveHiddenCategoryIds(List<String> ids) async {
    await metaBox.put('hidden_categories', jsonEncode(ids));
    _notify();
  }

  static dynamic _keyById<T>(
      Box<T> box, String id, String Function(T item) getId) {
    for (final key in box.keys) {
      final item = box.get(key);
      if (item != null && getId(item) == id) return key;
    }
    return null;
  }

  static Future<void> _putById<T>(
    Box<T> box,
    String id,
    T value,
    String Function(T item) getId,
  ) async {
    if (value is HiveObject && value.isInBox) {
      await value.save();
      return;
    }
    final key = _keyById(box, id, getId);
    if (key == null) {
      await box.add(value);
    } else {
      await box.put(key, value);
    }
  }

  static Future<void> _deleteById<T>(
    Box<T> box,
    String id,
    String Function(T item) getId,
  ) async {
    final key = _keyById(box, id, getId);
    if (key != null) {
      await box.delete(key);
    }
  }

  // --- SETTINGS ---

  static AppSettings getSettings() {
    if (settingsBox.isEmpty) {
      final defaults = AppSettings();
      settingsBox.add(defaults);
      return defaults;
    }
    return settingsBox.getAt(0)!;
  }

  static Future<void> saveSettings(AppSettings settings) async {
    if (settingsBox.isEmpty) {
      await settingsBox.add(settings);
    } else {
      await settingsBox.putAt(0, settings);
    }
    _notify();
  }

  // --- TRANSACTIONS ---

  static List<Transaction> getAllTransactions() => txBox.values.toList();

  static Future<void> addTransaction(Transaction t) async {
    await txBox.add(t);
    _notify();
  }

  static Future<void> updateTransaction(Transaction t) async {
    await _putById(txBox, t.id, t, (item) => item.id);
    _notify();
  }

  static Future<void> deleteTransaction(Transaction t) async {
    await _deleteById(txBox, t.id, (item) => item.id);
    _notify();
  }

  // --- INCOMES ---

  static List<Income> getAllIncomes() => incomeBox.values.toList();

  static Future<void> addIncome(Income i) async {
    await incomeBox.add(i);
    _notify();
  }

  static Future<void> updateIncome(Income i) async {
    await _putById(incomeBox, i.id, i, (item) => item.id);
    _notify();
  }

  static Future<void> deleteIncome(Income i) async {
    await _deleteById(incomeBox, i.id, (item) => item.id);
    _notify();
  }

  // --- RESERVES ---

  static List<Reserve> getAllReserves() =>
      reservesBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  static Future<void> addReserve(Reserve r) async {
    await reservesBox.add(r);
    await snapshotsBox.add(ReserveSnapshot(
      reserveId: r.id,
      amount: r.amount,
      date: r.date,
      type: r.type,
    ));
    _notify();
  }

  static Future<void> updateReserve(Reserve r) async {
    await _putById(reservesBox, r.id, r, (item) => item.id);
    await snapshotsBox.add(ReserveSnapshot(
      reserveId: r.id,
      amount: r.amount,
      date: DateTime.now(),
      type: r.type,
    ));
    _notify();
  }

  static Future<void> deleteReserve(Reserve r) async {
    final toDelete =
        snapshotsBox.values.where((s) => s.reserveId == r.id).toList();
    for (final s in toDelete) {
      await s.delete();
    }
    await _deleteById(reservesBox, r.id, (item) => item.id);
    _notify();
  }

  // --- RESERVE SNAPSHOTS ---

  static List<ReserveSnapshot> getAllSnapshots() =>
      snapshotsBox.values.toList();

  // --- REMINDERS ---

  static List<Reminder> getAllReminders() => remindersBox.values.toList();

  static List<Reminder> getRemindersForDay(DateTime day) {
    return remindersBox.values
        .where((r) =>
            r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day)
        .toList()
      ..sort((a, b) {
        final ha = a.hour * 60 + a.minute;
        final hb = b.hour * 60 + b.minute;
        return ha.compareTo(hb);
      });
  }

  static Future<void> addReminder(Reminder r) async {
    await remindersBox.add(r);
    _notify();
  }

  static Future<void> updateReminder(Reminder r) async {
    await _putById(remindersBox, r.id, r, (item) => item.id);
    _notify();
  }

  static Future<void> deleteReminder(Reminder r) async {
    await _deleteById(remindersBox, r.id, (item) => item.id);
    _notify();
  }

  // --- GOALS ---

  static List<Goal> getAllGoals() => goalsBox.values.toList();

  static Future<void> addGoal(Goal g) async {
    await goalsBox.add(g);
    _notify();
  }

  static Future<void> updateGoal(Goal g) async {
    await _putById(goalsBox, g.id, g, (item) => item.id);
    _notify();
  }

  static Future<void> deleteGoal(Goal g) async {
    await _deleteById(goalsBox, g.id, (item) => item.id);
    _notify();
  }

  // --- EXPORT ---

  static String exportToJson() {
    final data = {
      'transactions': getAllTransactions().map((t) => t.toJson()).toList(),
      'incomes': getAllIncomes().map((i) => i.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  // --- IMPORT ---

  static Future<ImportResult> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    int txCount = 0, incomeCount = 0;

    final existingIds = txBox.values.map((t) => t.id).toSet();
    for (final item in (data['transactions'] as List? ?? [])) {
      try {
        final t = Transaction.fromJson(item as Map<String, dynamic>);
        if (!existingIds.contains(t.id)) {
          await txBox.add(t);
          txCount++;
        }
      } catch (_) {}
    }

    final existingIncomeIds = incomeBox.values.map((i) => i.id).toSet();
    for (final item in (data['incomes'] as List? ?? [])) {
      try {
        final inc = Income.fromJson(item as Map<String, dynamic>);
        if (!existingIncomeIds.contains(inc.id)) {
          await incomeBox.add(inc);
          incomeCount++;
        }
      } catch (_) {}
    }

    _notify();
    return ImportResult(transactions: txCount, incomes: incomeCount);
  }

  static Future<void> clearAll() async {
    await txBox.clear();
    await incomeBox.clear();
    await reservesBox.clear();
    await snapshotsBox.clear();
    await remindersBox.clear();
    await goalsBox.clear();
    _notify();
  }
}

class ImportResult {
  final int transactions;
  final int incomes;
  const ImportResult({required this.transactions, required this.incomes});
}

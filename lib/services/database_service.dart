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
import '../models/card_due_date.dart';
import '../models/achievement.dart';
import '../models/streak_data.dart';
import 'gamification_service.dart';

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
  static Box<CardDueDate> get cardDueDateBox => Hive.box<CardDueDate>('card_due_dates');
  static Box<Achievement> get achievementsBox => Hive.box<Achievement>('achievements');
  static Box<StreakData> get streakBox => Hive.box<StreakData>('streak');

  // --- META: Custom Categories ---

  static List<Map<String, dynamic>> getCustomCategories() {
    final json = metaBox.get('custom_categories', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomCategories(
      List<Map<String, dynamic>> cats) async {
    await metaBox.put('custom_categories', jsonEncode(cats));
    _notify();
    GamificationService.evaluateAfterCustomization(isCategory: true).ignore();
  }

  // --- META: Custom Banks ---

  static List<Map<String, dynamic>> getCustomBanks() {
    final json = metaBox.get('custom_banks', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomBanks(List<Map<String, dynamic>> banks) async {
    await metaBox.put('custom_banks', jsonEncode(banks));
    _notify();
    GamificationService.evaluateAfterCustomization(isBank: true).ignore();
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

  // --- META: Category Order ---

  static List<String> getCategoryOrder() {
    final raw = metaBox.get('category_order');
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> saveCategoryOrder(List<String> ids) async {
    await metaBox.put('category_order', jsonEncode(ids));
    _notify();
  }

  // --- META: Category Sort Mode ---

  /// Valores: 'manual', 'alpha', 'usage'
  static String getCategorySortMode() {
    return metaBox.get('category_sort_mode') ?? 'manual';
  }

  static Future<void> saveCategorySortMode(String mode) async {
    await metaBox.put('category_sort_mode', mode);
    _notify();
  }

  // --- META: Category Default ---

  static String? getCategoryDefault() {
    return metaBox.get('category_default');
  }

  static Future<void> saveCategoryDefault(String? id) async {
    if (id == null) {
      await metaBox.delete('category_default');
    } else {
      await metaBox.put('category_default', id);
    }
  }

  // --- META: Transaction Manual Order ---

  static List<String> getTransactionOrder(String tabKey) {
    final raw = metaBox.get('tx_order_$tabKey');
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  static Future<void> saveTransactionOrder(String tabKey, List<String> ids) async {
    await metaBox.put('tx_order_$tabKey', jsonEncode(ids));
    // sem _notify() — UI atualiza via setState direto no onReorder
  }

  // --- META: Backup Config ---

  static String? getRawBackupConfig() => metaBox.get('backup_config');

  static Future<void> saveRawBackupConfig(String json) async {
    await metaBox.put('backup_config', json);
    // sem _notify() — backup config não afeta cálculos financeiros
  }

  // --- META: App version tracking (changelog banner) ---

  static String? getLastSeenVersion() {
    return metaBox.get('last_seen_version');
  }

  static Future<void> saveLastSeenVersion(String version) async {
    await metaBox.put('last_seen_version', version);
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
    GamificationService.evaluateAfterTransaction(t).ignore();
  }

  static Future<void> updateTransaction(Transaction t) async {
    await _putById(txBox, t.id, t, (item) => item.id);
    _notify();
    GamificationService.evaluateAfterTransaction(t, isEdit: true).ignore();
  }

  static Future<void> deleteTransaction(Transaction t) async {
    await _deleteById(txBox, t.id, (item) => item.id);
    _notify();
    GamificationService.evaluateAfterTransaction(t, isDelete: true).ignore();
  }

  // --- INCOMES ---

  static List<Income> getAllIncomes() => incomeBox.values.toList();

  static Future<void> addIncome(Income i) async {
    await incomeBox.add(i);
    _notify();
    GamificationService.evaluateAfterIncome(i).ignore();
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
    GamificationService.evaluateAfterReserveChange().ignore();
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
    GamificationService.evaluateAfterReserveChange().ignore();
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
    GamificationService.evaluateAfterGoalChange().ignore();
  }

  static Future<void> updateGoal(Goal g) async {
    await _putById(goalsBox, g.id, g, (item) => item.id);
    _notify();
    GamificationService.evaluateAfterGoalChange().ignore();
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
      'card_due_dates': getAllCardDueDates().map((c) => c.toJson()).toList(),
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

    int cardDueDateCount = 0;
    for (final item in (data['card_due_dates'] as List? ?? [])) {
      try {
        final cdd = CardDueDate.fromJson(item as Map<String, dynamic>);
        final existing = getCardDueDate(cdd.bankId);
        if (existing != null && existing.isInBox) {
          existing.closureDay = cdd.closureDay;
          existing.paymentDay = cdd.paymentDay;
          existing.overrideClosure = cdd.overrideClosure;
          existing.overridePayment = cdd.overridePayment;
          await existing.save();
        } else {
          await cardDueDateBox.add(cdd);
        }
        cardDueDateCount++;
      } catch (_) {}
    }

    _notify();
    return ImportResult(
      transactions: txCount,
      incomes: incomeCount,
      cardDueDates: cardDueDateCount,
    );
  }

  static Future<void> clearAll() async {
    await txBox.clear();
    await incomeBox.clear();
    await reservesBox.clear();
    await snapshotsBox.clear();
    await remindersBox.clear();
    await goalsBox.clear();
    await cardDueDateBox.clear();
    _notify();
  }

  // --- CARD DUE DATES ---

  static List<CardDueDate> getAllCardDueDates() {
    final keys = cardDueDateBox.keys.cast<int>().toList()..sort();
    return [
      for (final key in keys) cardDueDateBox.get(key)!,
    ];
  }

  static CardDueDate? getCardDueDate(String bankId) {
    for (final cdd in cardDueDateBox.values) {
      if (cdd.bankId == bankId) return cdd;
    }
    return null;
  }

  static Future<void> saveCardDueDate(CardDueDate cdd) async {
    final existing = getCardDueDate(cdd.bankId);
    if (existing != null && existing.isInBox) {
      existing.closureDay = cdd.closureDay;
      existing.paymentDay = cdd.paymentDay;
      existing.overrideClosure = cdd.overrideClosure;
      existing.overridePayment = cdd.overridePayment;
      await existing.save();
    } else {
      await cardDueDateBox.add(cdd);
    }
    _notify();
    GamificationService.evaluateAfterCardChange().ignore();
  }

  static Future<void> setCardClosureOverride(String bankId, DateTime month, int day) async {
    final cdd = getCardDueDate(bankId);
    if (cdd == null || !cdd.isInBox) return;
    cdd.setClosureOverride(month, day);
    await cdd.save();
    _notify();
    GamificationService.evaluateAfterCardOverride().ignore();
  }

  static Future<void> setCardPaymentOverride(String bankId, DateTime month, int day) async {
    final cdd = getCardDueDate(bankId);
    if (cdd == null || !cdd.isInBox) return;
    cdd.setPaymentOverride(month, day);
    await cdd.save();
    _notify();
  }

  static Future<void> deleteCardDueDate(String bankId) async {
    final cdd = getCardDueDate(bankId);
    if (cdd != null && cdd.isInBox) {
      await cdd.delete();
      _notify();
    }
  }

  // --- ACHIEVEMENTS ---

  static List<Achievement> getAllAchievements() => achievementsBox.values.toList();

  static List<Achievement> getUnlockedAchievements() =>
      achievementsBox.values.where((a) => a.unlocked).toList();

  static Future<void> unlockAchievement(String id) async {
    final ach = achievementsBox.values.where((a) => a.id == id).firstOrNull;
    if (ach == null || ach.unlocked) return;
    ach.unlocked = true;
    ach.unlockedAt = DateTime.now();
    await ach.save();
  }

  static Future<void> setAchievementProgress(String id, int value) async {
    final ach = achievementsBox.values.where((a) => a.id == id).firstOrNull;
    if (ach == null || ach.unlocked) return;
    ach.progress = value;
    await ach.save();
  }

  // --- STREAK ---

  static StreakData getStreak() {
    if (streakBox.isEmpty) {
      final s = StreakData();
      streakBox.add(s);
      return s;
    }
    return streakBox.getAt(0)!;
  }

  static Future<void> updateStreak() async {
    final streak = getStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = streak.lastActiveDay;

    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      if (lastDay == today) return; // já registrou hoje
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        streak.currentStreak++;
      } else {
        streak.currentStreak = 1;
      }
    } else {
      streak.currentStreak = 1;
    }

    if (streak.currentStreak > streak.longestStreak) {
      streak.longestStreak = streak.currentStreak;
    }
    streak.lastActiveDay = today;
    await streak.save();
  }
}

class ImportResult {
  final int transactions;
  final int incomes;
  final int cardDueDates;
  const ImportResult({
    required this.transactions,
    required this.incomes,
    this.cardDueDates = 0,
  });
}

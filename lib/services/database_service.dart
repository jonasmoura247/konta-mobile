import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/app_settings.dart';

class DatabaseService {
  static Box<Transaction> get txBox => Hive.box<Transaction>('transactions');
  static Box<Income> get incomeBox => Hive.box<Income>('incomes');
  static Box<AppSettings> get settingsBox => Hive.box<AppSettings>('settings');
  static Box<String> get metaBox => Hive.box<String>('meta');

  // --- META: Custom Categories ---

  static List<Map<String, dynamic>> getCustomCategories() {
    final json = metaBox.get('custom_categories', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomCategories(List<Map<String, dynamic>> cats) async {
    await metaBox.put('custom_categories', jsonEncode(cats));
  }

  // --- META: Custom Banks ---

  static List<Map<String, dynamic>> getCustomBanks() {
    final json = metaBox.get('custom_banks', defaultValue: '[]')!;
    return List<Map<String, dynamic>>.from(jsonDecode(json) as List);
  }

  static Future<void> saveCustomBanks(List<Map<String, dynamic>> banks) async {
    await metaBox.put('custom_banks', jsonEncode(banks));
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
  }

  // --- TRANSACTIONS ---

  static List<Transaction> getAllTransactions() => txBox.values.toList();

  static Future<void> addTransaction(Transaction t) => txBox.add(t);

  static Future<void> updateTransaction(Transaction t) => t.save();

  static Future<void> deleteTransaction(Transaction t) => t.delete();

  // --- INCOMES ---

  static List<Income> getAllIncomes() => incomeBox.values.toList();

  static Future<void> addIncome(Income i) => incomeBox.add(i);

  static Future<void> updateIncome(Income i) => i.save();

  static Future<void> deleteIncome(Income i) => i.delete();

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

    return ImportResult(transactions: txCount, incomes: incomeCount);
  }

  static Future<void> clearAll() async {
    await txBox.clear();
    await incomeBox.clear();
  }
}

class ImportResult {
  final int transactions;
  final int incomes;
  const ImportResult({required this.transactions, required this.incomes});
}

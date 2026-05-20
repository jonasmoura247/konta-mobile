import 'package:flutter/material.dart';
import '../app.dart';
import '../models/achievement.dart';
import '../models/income.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import 'database_service.dart';
import 'finance_calculator.dart';

class GamificationService {
  static Future<void> evaluateAfterTransaction(
    Transaction t, {
    bool isEdit = false,
    bool isDelete = false,
  }) async {
    await DatabaseService.updateStreak();

    final all = DatabaseService.getAllTransactions();
    final txCount = all.length;

    // Contadores auxiliares
    final installments = all.where((x) => x.groupId == 'parcelamento').toList();
    final credits = all.where((x) => _isCredit(x)).toList();
    final activeSubscriptions = all
        .where((x) => x.groupId == 'assinatura' && x.cancelledFrom == null)
        .toList();
    final familyTxs = all.where((x) => x.familyMode).toList();

    final toEval = <String, bool>{
      'first_transaction': txCount >= 1,
      'tx_count_5': txCount >= 5,
      'tx_count_10': txCount >= 10,
      'tx_count_25': txCount >= 25,
      'tx_count_50': txCount >= 50,
      'tx_count_100': txCount >= 100,
      'tx_count_200': txCount >= 200,
      'tx_count_250': txCount >= 250,
      'tx_count_500': txCount >= 500,
      'first_debit': t.groupId == 'debito',
      'first_credit': _isCredit(t),
      'first_subscription': t.groupId == 'assinatura',
      'first_installment_3x':
          t.groupId == 'parcelamento' && t.installments >= 3,
      'pix_payment': t.paymentSubtype == 'pix',
      'cash_payment': t.paymentSubtype == 'dinheiro',
      'debit_direct': t.paymentSubtype == 'debito_direto',
      'tx_amount_1000': t.totalAmount >= 1000,
      'tx_amount_5000': t.totalAmount >= 5000,
      'tx_installment_12x':
          t.groupId == 'parcelamento' && t.installments >= 12,
      'first_closure': t.applyClosureDate,
      'installment_count_5': installments.length >= 5,
      'installment_count_10': installments.length >= 10,
      'subscriptions_active_3': activeSubscriptions.length >= 3,
      'subscriptions_active_5': activeSubscriptions.length >= 5,
      'subscription_premium': activeSubscriptions
          .any((x) => x.totalAmount >= 100),
      'subscription_cancelled': isDelete && t.groupId == 'assinatura',
      'first_family_tx': t.familyMode,
      'family_tx_count_10': familyTxs.length >= 10,
      'family_tx_count_25': familyTxs.length >= 25,
      'family_tx_count_50': familyTxs.length >= 50,
      'credit_count_10': credits.length >= 10,
      'credit_count_25': credits.length >= 25,
      'credit_count_50': credits.length >= 50,
      'credit_count_75': credits.length >= 75,
      'family_tx_count_75': familyTxs.length >= 75,
    };

    if (isEdit) {
      final editCount = _incrementMeta('edit_count');
      toEval['first_edit'] = editCount >= 1;
      toEval['edit_count_10'] = editCount >= 10;
    }

    if (isDelete) {
      final deleteCount = _incrementMeta('delete_count');
      toEval['first_delete'] = deleteCount >= 1;
      toEval['delete_count_5'] = deleteCount >= 5;
      toEval['subscription_cancelled_3'] =
          _getMeta('subscription_cancel_count') >= 3;
    }

    if (isDelete && t.groupId == 'assinatura') {
      _incrementMeta('subscription_cancel_count');
    }

    // Progress updates for count-based achievements
    await _updateProgress('tx_count_5', txCount, 5);
    await _updateProgress('tx_count_10', txCount, 10);
    await _updateProgress('tx_count_25', txCount, 25);
    await _updateProgress('tx_count_50', txCount, 50);
    await _updateProgress('tx_count_100', txCount, 100);
    await _updateProgress('tx_count_200', txCount, 200);
    await _updateProgress('tx_count_250', txCount, 250);
    await _updateProgress('tx_count_500', txCount, 500);
    await _updateProgress('installment_count_5', installments.length, 5);
    await _updateProgress('installment_count_10', installments.length, 10);
    await _updateProgress('family_tx_count_10', familyTxs.length, 10);
    await _updateProgress('family_tx_count_25', familyTxs.length, 25);
    await _updateProgress('family_tx_count_50', familyTxs.length, 50);
    await _updateProgress('credit_count_10', credits.length, 10);
    await _updateProgress('credit_count_25', credits.length, 25);
    await _updateProgress('credit_count_50', credits.length, 50);
    await _updateProgress('credit_count_75', credits.length, 75);
    await _updateProgress('family_tx_count_75', familyTxs.length, 75);
    await _updateProgress('edit_count_10', _getMeta('edit_count'), 10);
    await _updateProgress('delete_count_5', _getMeta('delete_count'), 5);

    await _evaluateAndNotify(toEval);
    await _evaluateStreak();
  }

  static Future<void> evaluateAfterIncome(Income i) async {
    final all = DatabaseService.getAllIncomes();
    final incomeCount = all.length;

    final toEval = <String, bool>{
      'first_income': incomeCount >= 1,
      'income_count_5': incomeCount >= 5,
      'income_count_10': incomeCount >= 10,
      'income_count_15': incomeCount >= 15,
      'income_recurring': i.recurring,
      'income_high_5000': i.amount >= 5000,
      'family_income_5000': i.isFamilyValue && i.amount >= 5000,
      'income_types_3': all.length >= 3,
    };

    await _updateProgress('income_count_5', incomeCount, 5);
    await _updateProgress('income_count_10', incomeCount, 10);
    await _updateProgress('income_count_15', incomeCount, 15);

    await _evaluateAndNotify(toEval);
    await _evaluateSpendingAndBalance();
  }

  static Future<void> evaluateAfterReserveChange() async {
    final all = DatabaseService.getAllReserves();
    final count = all.length;
    final total = all.fold(0.0, (s, r) => s + r.amount);
    final maxAmount = all.isEmpty ? 0.0 : all.map((r) => r.amount).reduce((a, b) => a > b ? a : b);
    final updateCount = _incrementMeta('reserve_update_count');

    final toEval = <String, bool>{
      'first_reserve': count >= 1,
      'reserve_count_3': count >= 3,
      'reserve_count_5': count >= 5,
      'reserve_type_emergency': all.any((r) => r.type == 'emergencia'),
      'reserve_type_investment': all.any((r) => r.type == 'investimento'),
      'reserve_type_savings': all.any((r) => r.type == 'poupanca'),
      'reserve_type_other': all.any((r) => r.type == 'outro'),
      'reserve_first_update': updateCount >= 1,
      'reserve_update_count_5': updateCount >= 5,
      'reserve_update_count_10': updateCount >= 10,
      'reserve_amount_1000': maxAmount >= 1000,
      'reserve_amount_10000': maxAmount >= 10000,
      'reserve_amount_100000': maxAmount >= 100000,
      'reserve_total_10000': total >= 10000,
      'reserve_total_50000': total >= 50000,
      'reserve_total_100000': total >= 100000,
    };

    await _updateProgress('reserve_count_3', count, 3);
    await _updateProgress('reserve_count_5', count, 5);
    await _updateProgress('reserve_update_count_5', updateCount, 5);
    await _updateProgress('reserve_update_count_10', updateCount, 10);

    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateAfterGoalChange() async {
    final all = DatabaseService.getAllGoals();
    final count = all.length;
    final reachedCount = all.where((g) => g.savedAmount >= g.targetAmount).length;

    final toEval = <String, bool>{
      'first_goal': count >= 1,
      'goal_count_3': count >= 3,
      'goal_count_5': count >= 5,
      'goal_count_10': count >= 10,
      'goal_first_deposit': all.any((g) => g.savedAmount > 0),
      'goal_50pct': all.any((g) => g.targetAmount > 0 && g.savedAmount / g.targetAmount >= 0.5),
      'goal_reached': reachedCount >= 1,
      'goal_reached_3': reachedCount >= 3,
      'goal_reached_5': reachedCount >= 5,
      'goal_reached_10': reachedCount >= 10,
      'goal_target_5000': all.any((g) => g.targetAmount >= 5000),
      'goal_target_20000': all.any((g) => g.targetAmount >= 20000),
      'goal_target_100000': all.any((g) => g.targetAmount >= 100000),
      'goal_exceeded': all.any((g) => g.savedAmount > g.targetAmount && g.targetAmount > 0),
    };

    await _updateProgress('goal_count_3', count, 3);
    await _updateProgress('goal_count_5', count, 5);
    await _updateProgress('goal_count_10', count, 10);
    await _updateProgress('goal_reached_3', reachedCount, 3);
    await _updateProgress('goal_reached_5', reachedCount, 5);
    await _updateProgress('goal_reached_10', reachedCount, 10);

    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateAfterCardChange() async {
    final all = DatabaseService.getAllCardDueDates();
    final count = all.length;

    final toEval = <String, bool>{
      'first_card': count >= 1,
      'card_count_2': count >= 2,
      'card_count_3': count >= 3,
      'cards_organized_2': count >= 2,
      'card_override': _getMeta('card_override_count') >= 1,
    };

    await _updateProgress('card_count_2', count, 2);
    await _updateProgress('card_count_3', count, 3);

    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateAfterCardOverride() async {
    _incrementMeta('card_override_count');
    final toEval = <String, bool>{'card_override': true};
    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateAfterSettingsChange() async {
    final s = DatabaseService.getSettings();
    final defaultNames = ['Eu', 'Parceiro(a)'];
    final namesCustomized = s.familyNames.isNotEmpty &&
        s.familyNames.any((n) => !defaultNames.contains(n));

    final toEval = <String, bool>{
      'family_mode': s.familyMode,
      'family_count_4': s.familyMode && s.familyCount >= 4,
      'family_count_6': s.familyMode && s.familyCount >= 6,
      'family_names_set': s.familyMode && namesCustomized,
    };

    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateAfterCustomization({
    bool isCategory = false,
    bool isBank = false,
  }) async {
    final cats = DatabaseService.getCustomCategories();
    final banks = DatabaseService.getCustomBanks();

    final toEval = <String, bool>{
      'custom_category': isCategory && cats.isNotEmpty,
      'custom_category_3': isCategory && cats.length >= 3,
      'custom_bank': isBank && banks.isNotEmpty,
    };

    await _updateProgress('custom_category_3', cats.length, 3);
    await _evaluateAndNotify(toEval);
  }

  static Future<void> evaluateSpendingAndBalance() async {
    await _evaluateSpendingAndBalance();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isCredit(Transaction t) =>
      t.groupId != 'debito' && t.paymentSubtype == null && t.applyClosureDate;

  static Future<void> _evaluateStreak() async {
    final streak = DatabaseService.getStreak();
    final toEval = <String, bool>{
      'streak_7': streak.currentStreak >= 7,
      'streak_30': streak.currentStreak >= 30,
    };
    await _updateProgress('streak_7', streak.currentStreak, 7);
    await _updateProgress('streak_30', streak.currentStreak, 30);
    await _evaluateAndNotify(toEval);
  }

  static Future<void> _evaluateSpendingAndBalance() async {
    final txs = DatabaseService.getAllTransactions();
    final incomes = DatabaseService.getAllIncomes();
    final settings = DatabaseService.getSettings();
    final familyCount = settings.familyMode ? settings.familyCount : 1;

    // Check last 12 months for balance/spending
    final now = DateTime.now();
    int positiveMonths = 0;
    bool under80 = false, under70 = false, under50 = false, under40 = false;

    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final summary = FinanceCalculator.summarize(
        txs,
        incomes,
        month,
        familyCount,
        carryover: 0,
      );
      if (summary.balance >= 0) positiveMonths++;
      if (summary.totalIncome > 0) {
        final ratio = summary.totalExpenses / summary.totalIncome;
        if (ratio < 0.8) under80 = true;
        if (ratio < 0.7) under70 = true;
        if (ratio < 0.5) under50 = true;
        if (ratio < 0.4) under40 = true;
      }
    }

    final toEval = <String, bool>{
      'balance_positive': positiveMonths >= 1,
      'balance_positive_3': positiveMonths >= 3,
      'balance_positive_6': positiveMonths >= 6,
      'balance_positive_12': positiveMonths >= 12,
      'spending_under_80pct': under80,
      'spending_under_70pct': under70,
      'spending_under_50pct': under50,
      'spending_under_40pct': under40,
    };

    await _updateProgress('balance_positive_3', positiveMonths, 3);
    await _updateProgress('balance_positive_6', positiveMonths, 6);
    await _updateProgress('balance_positive_12', positiveMonths, 12);

    await _evaluateAndNotify(toEval);
  }

  static Future<void> _evaluateAndNotify(Map<String, bool> criteria) async {
    final all = DatabaseService.getAllAchievements();
    for (final ach in all) {
      if (ach.unlocked) continue;
      final met = criteria[ach.criteria];
      if (met == true) {
        await DatabaseService.unlockAchievement(ach.id);
        _showToast(ach);
      }
    }
  }

  static Future<void> _updateProgress(
      String criteria, int value, int total) async {
    final ach = DatabaseService.getAllAchievements()
        .where((a) => a.criteria == criteria && !a.unlocked)
        .firstOrNull;
    if (ach != null) {
      await DatabaseService.setAchievementProgress(ach.id, value);
    }
  }

  static int _getMeta(String key) {
    final raw = DatabaseService.metaBox.get('gamif_$key');
    return raw == null ? 0 : int.tryParse(raw) ?? 0;
  }

  static int _incrementMeta(String key) {
    final current = _getMeta(key);
    final next = current + 1;
    DatabaseService.metaBox.put('gamif_$key', next.toString());
    return next;
  }

  static void _showToast(Achievement ach) {
    final messenger = globalScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    final stars = '⭐' * ach.stars;
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🏆 ', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conquista desbloqueada!',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${ach.title}  $stars',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}

// Avaliação de conquistas em categorias específicas
extension GamificationGoalExt on Goal {
  bool get reached => savedAmount >= targetAmount;
}

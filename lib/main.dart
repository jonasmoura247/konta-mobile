import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/transaction.dart';
import 'models/income.dart';
import 'models/app_settings.dart';
import 'models/reserve.dart';
import 'models/reserve_snapshot.dart';
import 'models/reminder.dart';
import 'models/goal.dart';
import 'models/card_due_date.dart';
import 'models/achievement.dart';
import 'models/streak_data.dart';
import 'services/database_service.dart';
import 'services/migration_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';
import 'app.dart';

/// Abre um box Hive de forma segura. Se falhar (dados corrompidos ou schema
/// incompatível), deleta o arquivo do disco e recria vazio.
/// [isSeedOnly]: se true, a perda não é reportada ao usuário (box reconstruído
/// automaticamente por seed ou recálculo).
Future<Box<T>> _openBoxSafe<T>(
  String name,
  List<String> lostBoxes, {
  bool isSeedOnly = false,
}) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    await Hive.deleteBoxFromDisk(name);
    if (!isSeedOnly) lostBoxes.add(name);
    return await Hive.openBox<T>(name);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(ReserveAdapter());
  Hive.registerAdapter(ReserveSnapshotAdapter());
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(GoalAdapter());
  Hive.registerAdapter(CardDueDateAdapter());
  Hive.registerAdapter(AchievementAdapter());
  Hive.registerAdapter(StreakDataAdapter());

  // Abre cada box individualmente para isolar falhas
  final lostBoxes = <String>[];
  await _openBoxSafe<Transaction>('transactions', lostBoxes);
  await _openBoxSafe<Income>('incomes', lostBoxes);
  await _openBoxSafe<AppSettings>('settings', lostBoxes, isSeedOnly: true);
  await _openBoxSafe<String>('meta', lostBoxes, isSeedOnly: true);
  await _openBoxSafe<Reserve>('reserves', lostBoxes);
  await _openBoxSafe<ReserveSnapshot>('reserve_snapshots', lostBoxes);
  await _openBoxSafe<Reminder>('reminders', lostBoxes);
  await _openBoxSafe<Goal>('goals', lostBoxes);
  await _openBoxSafe<CardDueDate>('card_due_dates', lostBoxes);
  await _openBoxSafe<Achievement>('achievements', lostBoxes, isSeedOnly: true);
  await _openBoxSafe<StreakData>('streak', lostBoxes, isSeedOnly: true);

  await MigrationService.runIfNeeded();

  await SeedService.seedIfEmpty();
  await SeedService.loadAchievements();
  await NotificationService.init();
  BackupService.init();

  final settings = DatabaseService.getSettings();
  themeNotifier.value = settings.theme == 'light' ? ThemeMode.light : ThemeMode.dark;

  runApp(const ProviderScope(child: KontaApp()));

  if (lostBoxes.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final names = lostBoxes.join(', ');
      globalScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Alguns dados foram perdidos durante a atualização ($names). '
            'Importe um backup se tiver um salvo.',
          ),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}

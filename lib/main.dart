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
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'services/seed_service.dart';
import 'theme/app_theme.dart';
import 'app.dart';

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

  await Future.wait([
    Hive.openBox<Transaction>('transactions'),
    Hive.openBox<Income>('incomes'),
    Hive.openBox<AppSettings>('settings'),
    Hive.openBox<String>('meta'),
    Hive.openBox<Reserve>('reserves'),
    Hive.openBox<ReserveSnapshot>('reserve_snapshots'),
    Hive.openBox<Reminder>('reminders'),
    Hive.openBox<Goal>('goals'),
    Hive.openBox<CardDueDate>('card_due_dates'),
    Hive.openBox<Achievement>('achievements'),
    Hive.openBox<StreakData>('streak'),
  ]);

  await SeedService.seedIfEmpty();
  await SeedService.loadAchievements();
  await NotificationService.init();
  BackupService.init();

  final settings = DatabaseService.getSettings();
  themeNotifier.value = settings.theme == 'light' ? ThemeMode.light : ThemeMode.dark;

  runApp(const ProviderScope(child: KontaApp()));
}

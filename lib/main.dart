import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/transaction.dart';
import 'models/income.dart';
import 'models/app_settings.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Formatação de datas em pt-BR
  await initializeDateFormatting('pt_BR', null);

  // Inicializar banco de dados Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(IncomeAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  await Future.wait([
    Hive.openBox<Transaction>('transactions'),
    Hive.openBox<Income>('incomes'),
    Hive.openBox<AppSettings>('settings'),
  ]);

  runApp(const ProviderScope(child: FarmasApp()));
}

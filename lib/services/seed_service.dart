import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/income.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import 'database_service.dart';

class SeedService {
  static const _assetPath = 'assets/data/farmas-dados.json';

  /// Roda na inicialização: se o banco está vazio, importa o JSON bundled.
  /// Se já tem dados, apenas carrega as categorias dinâmicas do JSON.
  static Future<void> seedIfEmpty() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_assetPath);
    } catch (_) {
      return; // arquivo não encontrado, ignora
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;

    // Sempre carrega categorias dinâmicas (necessário para exibir nomes corretos)
    final jsonCategories = data['categories'] as List<dynamic>? ?? [];
    loadCategoriesFromJson(jsonCategories);

    // Se já tem transações, não re-importa (evita duplicatas)
    if (DatabaseService.txBox.isNotEmpty) return;

    // --- Importar configurações ---
    final jsonSettings = data['settings'] as Map<String, dynamic>?;
    if (jsonSettings != null) {
      final settings = AppSettings(
        currency: jsonSettings['currency'] as String? ?? 'BRL',
        theme: jsonSettings['theme'] as String? ?? 'dark',
        familyMode: jsonSettings['familyMode'] as bool? ?? false,
        familyCount: (jsonSettings['familyCount'] as num?)?.toInt() ?? 2,
        familyNames: (jsonSettings['familyNames'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            ['Eu', 'Parceiro(a)'],
      );
      await DatabaseService.saveSettings(settings);
    }

    // --- Importar transações ---
    int txCount = 0;
    for (final item in (data['transactions'] as List<dynamic>? ?? [])) {
      try {
        final t = Transaction.fromJson(item as Map<String, dynamic>);
        await DatabaseService.txBox.add(t);
        txCount++;
      } catch (_) {}
    }

    // --- Importar entradas/receitas ---
    int incomeCount = 0;
    for (final item in (data['incomes'] as List<dynamic>? ?? [])) {
      try {
        final i = Income.fromJson(item as Map<String, dynamic>);
        await DatabaseService.incomeBox.add(i);
        incomeCount++;
      } catch (_) {}
    }

    // ignore: avoid_print
    print('Seed: $txCount transações, $incomeCount entradas carregadas.');
  }
}

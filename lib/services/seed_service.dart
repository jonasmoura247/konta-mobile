import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import 'database_service.dart';

class SeedService {
  static const _assetPath = 'assets/data/farmas-dados.json';

  /// Roda na inicialização: sempre carrega categorias dinâmicas do JSON.
  /// Na primeira instalação, inicializa as configurações padrão sem importar dados.
  /// Em atualizações, mantém os dados existentes intactos.
  static Future<void> seedIfEmpty() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_assetPath);
    } catch (_) {
      return;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;

    // Sempre carrega categorias dinâmicas (necessário para exibir nomes corretos)
    final jsonCategories = data['categories'] as List<dynamic>? ?? [];
    loadCategoriesFromJson(jsonCategories);

    // Se as configurações já existem, o banco já foi inicializado — não faz nada
    if (DatabaseService.settingsBox.isNotEmpty) return;

    // Primeira instalação: inicializa apenas as configurações padrão, sem dados
    final jsonSettings = data['settings'] as Map<String, dynamic>?;
    final settings = AppSettings(
      currency: jsonSettings?['currency'] as String? ?? 'BRL',
      theme: jsonSettings?['theme'] as String? ?? 'dark',
      familyMode: jsonSettings?['familyMode'] as bool? ?? false,
      familyCount: (jsonSettings?['familyCount'] as num?)?.toInt() ?? 2,
      familyNames: (jsonSettings?['familyNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Eu', 'Parceiro(a)'],
    );
    await DatabaseService.saveSettings(settings);
  }
}

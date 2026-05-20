import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/achievement.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import 'database_service.dart';

/// Mapeamento de nomes antigos (marca) → novo nome genérico
const _bankNameMigration = {
  'Itaú': 'Banco 1',
  'Itau': 'Banco 1',
  'Bradesco': 'Banco 2',
  'Caixa': 'Banco 3',
  'Banco do Brasil': 'Banco 4',
  'Santander': 'Banco 5',
  'Sicoob': 'Banco 6',
  'Sicredi': 'Banco 7',
  'BTG Pactual': 'Banco 8',
  'BTG': 'Banco 8',
  'Safra': 'Banco 9',
  'Nubank': 'Banco 10',
  'Inter': 'Banco 11',
  'C6 Bank': 'Banco 12',
  'C6': 'Banco 12',
  'Neon': 'Banco 13',
  'Next': 'Banco 14',
  'PicPay': 'Banco 15',
  'PagBank': 'Banco 16',
  'Mercado Pago': 'Banco 17',
  'Stone': 'Banco 18',
  'XP': 'Banco 19',
  'Will Bank': 'Banco 20',
};

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

    // Migração única: renomeia bancos com nomes de marca para nomes genéricos
    await _migrateBankNamesIfNeeded();

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

  /// Carrega achievements do JSON, preservando unlocked/unlockedAt existentes.
  /// Só persiste se o metadado mudou (evita 100 writes a cada startup).
  static Future<void> loadAchievements() async {
    final String raw;
    try {
      raw = await rootBundle.loadString('assets/data/achievements.json');
    } catch (_) {
      return;
    }

    final List<dynamic> list;
    try {
      list = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    final box = DatabaseService.achievementsBox;
    final existing = {for (final a in box.values) a.id: a};

    for (final item in list) {
      try {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as String;
        final title = map['title'] as String;
        final description = map['description'] as String;
        final stars = (map['stars'] as num).toInt();
        final hidden = map['hidden'] as bool? ?? false;
        final criteria = map['criteria'] as String;
        final goal = (map['goal'] as num?)?.toInt();

        final prev = existing[id];
        if (prev != null) {
          // Só salva se algo mudou — evita writes desnecessários a cada startup
          if (prev.title != title ||
              prev.description != description ||
              prev.stars != stars ||
              prev.hidden != hidden ||
              prev.criteria != criteria ||
              prev.goal != goal) {
            prev.title = title;
            prev.description = description;
            prev.stars = stars;
            prev.hidden = hidden;
            prev.criteria = criteria;
            prev.goal = goal;
            await prev.save();
          }
        } else {
          await box.add(Achievement(
            id: id,
            title: title,
            description: description,
            stars: stars,
            hidden: hidden,
            criteria: criteria,
            goal: goal,
          ));
        }
      } catch (_) {
        continue;
      }
    }
  }

  /// Renomeia nomes de bancos antigos (marcas) para genéricos.
  /// Roda apenas uma vez (controlado pela chave 'banks_renamed_v1' no Hive).
  static Future<void> _migrateBankNamesIfNeeded() async {
    const migrationKey = 'banks_renamed_v1';
    if (DatabaseService.metaBox.get(migrationKey) == 'true') return;

    final customBanks = DatabaseService.getCustomBanks();
    bool changed = false;
    final updated = customBanks.map((b) {
      final name = b['name'] as String? ?? '';
      final newName = _bankNameMigration[name];
      if (newName != null && newName != name) {
        changed = true;
        return {...b, 'name': newName};
      }
      return b;
    }).toList();

    if (changed) {
      await DatabaseService.saveCustomBanks(updated);
    }

    await DatabaseService.metaBox.put(migrationKey, 'true');
  }
}

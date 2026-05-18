import 'package:flutter/material.dart';
import '../services/database_service.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });
}

// Categorias padrão (fallback)
const List<Category> kDefaultCategories = [
  Category(id: 'mercado',      name: 'Mercado',      color: Color(0xFF4CAF50), icon: Icons.shopping_cart),
  Category(id: 'farmacia',     name: 'Farmácia',     color: Color(0xFFE91E63), icon: Icons.local_pharmacy),
  Category(id: 'lazer',        name: 'Lazer',        color: Color(0xFF9C27B0), icon: Icons.sports_esports),
  Category(id: 'estudos',      name: 'Estudos',      color: Color(0xFF2196F3), icon: Icons.menu_book),
  Category(id: 'faculdade',    name: 'Faculdade',    color: Color(0xFF3F51B5), icon: Icons.school),
  Category(id: 'roupa',        name: 'Roupa',        color: Color(0xFFFF5722), icon: Icons.checkroom),
  Category(id: 'ifood',        name: 'Alimentação',  color: Color(0xFFFF0000), icon: Icons.delivery_dining),
  Category(id: 'uber',         name: 'Transporte',   color: Color(0xFF607D8B), icon: Icons.local_taxi),
  Category(id: 'gasolina',     name: 'Gasolina',     color: Color(0xFFFF9800), icon: Icons.local_gas_station),
  Category(id: 'saude',        name: 'Saúde',        color: Color(0xFF00BCD4), icon: Icons.favorite),
  Category(id: 'necessidade',  name: 'Necessidade',  color: Color(0xFF607D8B), icon: Icons.home),
  Category(id: 'apartamento',  name: 'Apartamento',  color: Color(0xFF795548), icon: Icons.apartment),
  Category(id: 'manutencao',   name: 'Manutenção',   color: Color(0xFF9E9E9E), icon: Icons.build),
  Category(id: 'presente',     name: 'Presente',     color: Color(0xFFFF4081), icon: Icons.card_giftcard),
  Category(id: 'livraria',     name: 'Livraria',     color: Color(0xFFFF00FF), icon: Icons.menu_book),
  Category(id: 'imposto',      name: 'Imposto',      color: Color(0xFFEEFF00), icon: Icons.receipt),
  Category(id: 'outros',       name: 'Outros',       color: Color(0xFF546E7A), icon: Icons.more_horiz),
];

// Mapa de categorias dinâmicas carregadas do JSON (inclui IDs customizados)
final Map<String, Category> _dynamicCategories = {};

// Converte string hex "#RRGGBB" para Color
Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) {
    return Color(int.parse('FF$h', radix: 16));
  }
  return const Color(0xFF546E7A); // fallback cinza
}

// Mapeia emojis/nomes para ícones Material
IconData _iconForCategory(String name, String emoji) {
  final n = name.toLowerCase();
  if (n.contains('mercado') || n.contains('compra')) return Icons.shopping_cart;
  if (n.contains('farm') || n.contains('remédio') || n.contains('saúde') || n.contains('saude')) return Icons.local_pharmacy;
  if (n.contains('lazer') || n.contains('entret')) return Icons.sports_esports;
  if (n.contains('estud')) return Icons.menu_book;
  if (n.contains('facul') || n.contains('escola')) return Icons.school;
  if (n.contains('roupa') || n.contains('vest')) return Icons.checkroom;
  if (n.contains('ifood') || n.contains('comida') || n.contains('food') || n.contains('alimenta')) return Icons.delivery_dining;
  if (n.contains('uber') || n.contains('táxi') || n.contains('taxi') || n.contains('transport')) return Icons.local_taxi;
  if (n.contains('gasolina') || n.contains('combustível')) return Icons.local_gas_station;
  if (n.contains('apart') || n.contains('aluguel') || n.contains('casa')) return Icons.apartment;
  if (n.contains('manu') || n.contains('repair')) return Icons.build;
  if (n.contains('present') || n.contains('gift')) return Icons.card_giftcard;
  if (n.contains('livr') || n.contains('livro')) return Icons.menu_book;
  if (n.contains('imposto') || n.contains('taxa')) return Icons.receipt;
  if (n.contains('necessid')) return Icons.home;
  return Icons.label;
}

/// Carregado uma vez na inicialização do app a partir do JSON
void loadCategoriesFromJson(List<dynamic> jsonCategories) {
  _dynamicCategories.clear();
  for (final c in jsonCategories) {
    final id = c['id'] as String;
    final name = c['name'] as String;
    final colorHex = (c['color'] as String?) ?? '#546E7A';
    final emoji = (c['icon'] as String?) ?? '';
    _dynamicCategories[id] = Category(
      id: id,
      name: name,
      color: _hexToColor(colorHex),
      icon: _iconForCategory(name, emoji),
    );
  }
}

/// Retorna todas as categorias disponíveis (padrão → dinâmicas → custom do usuário)
List<Category> getAllCategories() {
  final result = <String, Category>{};

  // Passo 1: começa com os padrões
  for (final c in kDefaultCategories) {
    result[c.id] = c;
  }

  // Passo 2: aplica categorias do JSON
  // • Mesmo ID que padrão → atualiza cor/ícone, mas FORÇA o nome do padrão
  // • ID customizado com nome igual a um padrão → IGNORA (evita duplicatas)
  // • ID customizado com nome único → adiciona normalmente
  final defaultNameSet = kDefaultCategories
      .map((d) => d.name.toLowerCase().trim())
      .toSet();
  for (final entry in _dynamicCategories.entries) {
    final id = entry.key;
    final c = entry.value;
    final defaultCat = kDefaultCategories.where((d) => d.id == id).firstOrNull;
    if (defaultCat != null) {
      result[id] = Category(id: id, name: defaultCat.name, color: c.color, icon: c.icon);
    } else if (!defaultNameSet.contains(c.name.toLowerCase().trim())) {
      result[id] = c;
    }
    // ID customizado com nome duplicado de padrão → descarta
  }

  // Passo 3: custom do usuário (maior prioridade — pode sobrescrever cor/ícone)
  for (final c in DatabaseService.getCustomCategories()) {
    final id = c['id'] as String;
    // Para IDs padrão, o nome NUNCA é sobrescrito pelo Hive
    final defaultCat = kDefaultCategories.where((d) => d.id == id).firstOrNull;
    final name = defaultCat?.name ?? (c['name'] as String);
    final colorHex = (c['color'] as String?) ?? '#546E7A';
    final emoji = (c['icon'] as String?) ?? '';
    result[id] = Category(
      id: id,
      name: name,
      color: _hexToColor(colorHex),
      icon: _iconForCategory(name, emoji),
    );
  }

  return result.values.toList();
}

List<Category> getVisibleCategories() {
  final hidden = DatabaseService.getHiddenCategoryIds().toSet();
  return getAllCategories().where((c) => !hidden.contains(c.id)).toList();
}

/// Retorna categorias visíveis já ordenadas conforme o modo salvo.
/// [usageCounts] é necessário apenas para o modo 'usage'.
List<Category> getOrderedVisibleCategories({
  Map<String, int>? usageCounts,
}) {
  final visible = getVisibleCategories();
  final mode = DatabaseService.getCategorySortMode();

  switch (mode) {
    case 'alpha':
      visible.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return visible;

    case 'usage':
      if (usageCounts != null && usageCounts.isNotEmpty) {
        visible.sort((a, b) {
          final ua = usageCounts[a.id] ?? 0;
          final ub = usageCounts[b.id] ?? 0;
          return ub.compareTo(ua); // mais usadas primeiro
        });
      }
      return visible;

    case 'manual':
    default:
      final order = DatabaseService.getCategoryOrder();
      if (order.isEmpty) return visible;
      final idIndex = {for (int i = 0; i < order.length; i++) order[i]: i};
      visible.sort((a, b) {
        final ia = idIndex[a.id] ?? 9999;
        final ib = idIndex[b.id] ?? 9999;
        return ia.compareTo(ib);
      });
      return visible;
  }
}

Category getCategoryById(String id) {
  // Check custom categories first (highest priority)
  final custom = DatabaseService.getCustomCategories();
  final customMatch = custom.where((c) => c['id'] == id).toList();
  if (customMatch.isNotEmpty) {
    final c = customMatch.first;
    final colorHex = (c['color'] as String?) ?? '#546E7A';
    final emoji = (c['icon'] as String?) ?? '';
    return Category(id: id, name: c['name'] as String, color: _hexToColor(colorHex), icon: _iconForCategory(c['name'] as String, emoji));
  }
  if (_dynamicCategories.containsKey(id)) return _dynamicCategories[id]!;
  try {
    return kDefaultCategories.firstWhere((c) => c.id == id);
  } catch (_) {
    return kDefaultCategories.last; // 'outros'
  }
}

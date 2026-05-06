import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show ThemeMode;
import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

// ───────────────────────────────────────────────────────── color palette ──
const List<Color> _kPalette = [
  Color(0xFFEF5350), Color(0xFFEC407A), Color(0xFFAB47BC), Color(0xFF7E57C2),
  Color(0xFF5C6BC0), Color(0xFF42A5F5), Color(0xFF26C6DA), Color(0xFF26A69A),
  Color(0xFF66BB6A), Color(0xFFD4E157), Color(0xFFFFCA28), Color(0xFFFFA726),
  Color(0xFFFF7043), Color(0xFF8D6E63), Color(0xFF78909C), Color(0xFF546E7A),
  Color(0xFF00E5FF), Color(0xFF69FF47), Color(0xFFFF6B35), Color(0xFF820AD1),
];

Future<Color?> _pickColor(BuildContext context, Color initial) {
  Color picked = initial;
  return showDialog<Color>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.kCard,
      title: Text('Escolher cor', style: TextStyle(color: ctx.kTextPrimary)),
      content: StatefulBuilder(
        builder: (ctx2, setSt) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kPalette.map((c) {
                final sel = picked.value == c.value;
                return GestureDetector(
                  onTap: () => setSt(() => picked = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel ? Border.all(color: Colors.white, width: 3) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(color: picked, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('Cor selecionada', style: TextStyle(color: picked.computeLuminance() > 0.4 ? Colors.black : Colors.white, fontSize: 12))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(onPressed: () => Navigator.pop(ctx, picked), child: const Text('OK')),
      ],
    ),
  );
}

// ───────────────────────────────────────────────────────────── screen ──
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late List<Map<String, dynamic>> _customCats;
  late List<Map<String, dynamic>> _customBanks;

  @override
  void initState() {
    super.initState();
    _settings = DatabaseService.getSettings();
    _customCats = DatabaseService.getCustomCategories();
    _customBanks = DatabaseService.getCustomBanks();
  }

  Future<void> _save() async {
    await DatabaseService.saveSettings(_settings);
    setState(() {});
  }

  Future<void> _saveCats() async {
    await DatabaseService.saveCustomCategories(_customCats);
    setState(() {});
  }

  Future<void> _saveBanks() async {
    await DatabaseService.saveCustomBanks(_customBanks);
    setState(() {});
  }

  // ───────────────── Category editing ──────────────────────────────────
  void _editCategoryColor(Category cat) async {
    final currentColor = _overrideColor(cat.id, cat.color, isCat: true);
    final picked = await _pickColor(context, currentColor);
    if (picked == null) return;
    final idx = _customCats.indexWhere((c) => c['id'] == cat.id);
    final entry = {
      'id': cat.id,
      'name': cat.name,
      'color': colorToHex(picked),
      'icon': '',
    };
    if (idx >= 0) {
      _customCats[idx] = entry;
    } else {
      _customCats.add(entry);
    }
    await _saveCats();
  }

  void _addCategory() async {
    final nameCtrl = TextEditingController();
    Color newColor = _kPalette[0];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title: Text('Nova categoria', style: TextStyle(color: ctx.kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: ctx.kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: ctx.kTextSecondary),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final c = await _pickColor(ctx, newColor);
                  if (c != null) setSt(() => newColor = c);
                },
                child: Row(children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Adicionar')),
          ],
        ),
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _customCats.add({'id': id, 'name': nameCtrl.text.trim(), 'color': colorToHex(newColor), 'icon': ''});
      await _saveCats();
    }
  }

  void _deleteCustomCategory(String id) async {
    _customCats.removeWhere((c) => c['id'] == id);
    await _saveCats();
  }

  Color _overrideColor(String id, Color fallback, {required bool isCat}) {
    if (isCat) {
      final found = _customCats.where((c) => c['id'] == id).toList();
      if (found.isNotEmpty) {
        final hex = found.first['color'] as String?;
        if (hex != null && hex.isNotEmpty) {
          final h = hex.replaceAll('#', '');
          if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
        }
      }
    } else {
      final found = _customBanks.where((b) => b['id'] == id).toList();
      if (found.isNotEmpty) {
        final hex = found.first['color'] as String?;
        if (hex != null && hex.isNotEmpty) {
          final h = hex.replaceAll('#', '');
          if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
        }
      }
    }
    return fallback;
  }

  // ───────────────── Bank editing ──────────────────────────────────────
  void _editBank(BankDef bank) async {
    final nameCtrl = TextEditingController(text: bank.name);
    Color newColor = _overrideColor(bank.id, bank.color, isCat: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title: Text('Editar cartão', style: TextStyle(color: ctx.kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: ctx.kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: ctx.kTextSecondary),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final c = await _pickColor(ctx, newColor);
                  if (c != null) setSt(() => newColor = c);
                },
                child: Row(children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final idx = _customBanks.indexWhere((b) => b['id'] == bank.id);
      final entry = {'id': bank.id, 'name': nameCtrl.text.trim().isEmpty ? bank.name : nameCtrl.text.trim(), 'color': colorToHex(newColor)};
      if (idx >= 0) {
        _customBanks[idx] = entry;
      } else {
        _customBanks.add(entry);
      }
      await _saveBanks();
    }
  }

  void _addBank() async {
    final nameCtrl = TextEditingController();
    Color newColor = _kPalette[0];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title: Text('Novo cartão/banco', style: TextStyle(color: ctx.kTextPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: ctx.kTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome (ex: Bradesco)',
                  labelStyle: TextStyle(color: ctx.kTextSecondary),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final c = await _pickColor(ctx, newColor);
                  if (c != null) setSt(() => newColor = c);
                },
                child: Row(children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Adicionar')),
          ],
        ),
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _customBanks.add({'id': id, 'name': nameCtrl.text.trim(), 'color': colorToHex(newColor)});
      await _saveBanks();
    }
  }

  void _deleteCustomBank(String id) async {
    _customBanks.removeWhere((b) => b['id'] == id);
    await _saveBanks();
  }

  // ────────────────────────────────────────────────────── build ──
  @override
  Widget build(BuildContext context) {
    final allCats = getAllCategories();
    final allBanks = getAllBanks();
    final isCustomCat = (String id) => _customCats.any((c) => c['id'] == id && !kDefaultCategories.any((d) => d.id == id));

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Preferências ──────────────────────────────────────────
          _SectionTitle('Preferências'),
          _Card(children: [
            _DropdownTile<String>(
              label: 'Moeda',
              value: _settings.currency,
              items: const {'BRL': 'R\$ Real (BRL)', 'USD': '\$ Dólar (USD)', 'EUR': '€ Euro (EUR)'},
              onChanged: (v) { _settings.currency = v!; _save(); },
            ),
            const Divider(height: 1),
            _SwitchTile(
              label: 'Tema escuro',
              value: _settings.theme == 'dark',
              onChanged: (v) {
                _settings.theme = v ? 'dark' : 'light';
                _save();
                themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            const Divider(height: 1),
            _SwitchTile(
              label: 'Saldo acumulado',
              subtitle: 'Carrega o saldo restante do mês anterior',
              value: _settings.carryoverMode,
              onChanged: (v) { _settings.carryoverMode = v; _save(); },
            ),
          ]),

          // ── Metas ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionTitle('Metas'),
          _Card(children: [
            _SwitchTile(
              label: 'Ativar metas',
              subtitle: 'Gerencie metas na tela de Reservas',
              value: _settings.goalsEnabled,
              onChanged: (v) { _settings.goalsEnabled = v; _save(); },
            ),
          ]),

          // ── Modo Família ──────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionTitle('Modo Família'),
          _Card(children: [
            _SwitchTile(
              label: 'Ativar modo família',
              subtitle: 'Divide gastos entre membros',
              value: _settings.familyMode,
              onChanged: (v) { _settings.familyMode = v; _save(); },
            ),
            if (_settings.familyMode) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Número de membros', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                    Slider(
                      value: _settings.familyCount.toDouble(),
                      min: 2,
                      max: 6,
                      divisions: 4,
                      label: _settings.familyCount.toString(),
                      onChanged: (v) { _settings.familyCount = v.toInt(); _save(); },
                    ),
                    Text('${_settings.familyCount} membros', style: TextStyle(color: context.kTextPrimary)),
                  ],
                ),
              ),
            ],
          ]),

          // ── Categorias ────────────────────────────────────────────
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle('Categorias'),
              TextButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Nova', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
              ),
            ],
          ),
          _Card(children: [
            ...allCats.asMap().entries.map((e) {
              final i = e.key;
              final cat = e.value;
              final displayColor = _overrideColor(cat.id, cat.color, isCat: true);
              final isCustom = isCustomCat(cat.id);
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: GestureDetector(
                      onTap: () => _editCategoryColor(cat),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: displayColor, shape: BoxShape.circle),
                        child: Icon(cat.icon, color: Colors.white, size: 14),
                      ),
                    ),
                    title: Text(cat.name, style: TextStyle(color: context.kTextPrimary, fontSize: 13)),
                    subtitle: Text(isCustom ? 'Customizada' : 'Toque na cor para editar', style: TextStyle(color: context.kTextSecondary, fontSize: 10)),
                    trailing: isCustom
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                            onPressed: () => _deleteCustomCategory(cat.id),
                          )
                        : GestureDetector(
                            onTap: () => _editCategoryColor(cat),
                            child: const Icon(Icons.color_lens_outlined, size: 16, color: AppColors.accent),
                          ),
                  ),
                ],
              );
            }),
          ]),

          // ── Cartões / Bancos ──────────────────────────────────────
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionTitle('Cartões / Bancos'),
              TextButton.icon(
                onPressed: _addBank,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent, padding: EdgeInsets.zero),
              ),
            ],
          ),
          _Card(children: [
            ...allBanks.asMap().entries.map((e) {
              final i = e.key;
              final bank = e.value;
              final displayColor = _overrideColor(bank.id, bank.color, isCat: false);
              final isCustom = _customBanks.any((b) => b['id'] == bank.id && !kDefaultBanks.any((d) => d.id == bank.id));
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(color: displayColor, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.credit_card, color: Colors.white, size: 14),
                    ),
                    title: Text(bank.name, style: TextStyle(color: context.kTextPrimary, fontSize: 13)),
                    subtitle: Text(isCustom ? 'Customizado' : 'Padrão', style: TextStyle(color: context.kTextSecondary, fontSize: 10)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
                          onPressed: () => _editBank(bank),
                        ),
                        if (isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.expense),
                            onPressed: () => _deleteCustomBank(bank.id),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ]),

          // ── Dados ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionTitle('Dados'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.accent),
              title: Text('Importar dados (JSON)', style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Importar farmas-dados.json', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await ImportService.importJsonFromPicker();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(result == null
                      ? 'Importação cancelada'
                      : '${result.transactions} transações e ${result.incomes} entradas importadas'),
                  backgroundColor: result == null ? AppColors.textSecondary : AppColors.income,
                ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.neonCyan),
              title: Text('Exportar dados (JSON)', style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Salvar backup na pasta Downloads', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final path = await ImportService.exportJsonToDownloads();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text('Exportado: $path'),
                  backgroundColor: AppColors.income,
                ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.expense),
              title: const Text('Limpar todos os dados', style: TextStyle(color: AppColors.expense)),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ctx.kCard,
                  title: const Text('Apagar tudo?', style: TextStyle(color: AppColors.expense)),
                  content: Text('Esta ação é irreversível. Todos os lançamentos serão excluídos.', style: TextStyle(color: ctx.kTextSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () async {
                        await DatabaseService.clearAll();
                        if (context.mounted) Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('Apagar', style: TextStyle(color: AppColors.expense)),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          _Card(children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: context.kTextSecondary),
              title: Text('Versão', style: TextStyle(color: context.kTextPrimary)),
              trailing: Text('1.0.0', style: TextStyle(color: context.kTextSecondary, fontFamily: 'JetBrainsMono')),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────── helper widgets ──
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(color: context.kTextSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: context.kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.kCardBorder)),
        child: Column(children: children),
      );
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile({required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label, style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: context.kTextSecondary, fontSize: 12)) : null,
        value: value,
        onChanged: onChanged,
      );
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final void Function(T?) onChanged;
  const _DropdownTile({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
            DropdownButton<T>(
              value: value,
              dropdownColor: context.kCard,
              style: TextStyle(color: context.kTextPrimary),
              underline: const SizedBox.shrink(),
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

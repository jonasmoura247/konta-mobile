import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';
import '../utils/privacy_policy_text.dart';
import 'card_due_dates_screen.dart';
import 'changelog_screen.dart';

// ───────────────────────────────────────────────────────── color palette ──
const List<Color> _kPalette = [
  Color(0xFFEF5350),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF7E57C2),
  Color(0xFF5C6BC0),
  Color(0xFF42A5F5),
  Color(0xFF26C6DA),
  Color(0xFF26A69A),
  Color(0xFF66BB6A),
  Color(0xFFD4E157),
  Color(0xFFFFCA28),
  Color(0xFFFFA726),
  Color(0xFFFF7043),
  Color(0xFF8D6E63),
  Color(0xFF78909C),
  Color(0xFF546E7A),
  Color(0xFF00E5FF),
  Color(0xFF69FF47),
  Color(0xFFFF6B35),
  Color(0xFF820AD1),
];

// ───────────────────────────────────────────────────────── icon picker ──
const List<IconData> _kCatIcons = [
  Icons.shopping_cart,
  Icons.local_pharmacy,
  Icons.restaurant,
  Icons.sports_esports,
  Icons.school,
  Icons.directions_car,
  Icons.local_gas_station,
  Icons.home,
  Icons.beach_access,
  Icons.work,
  Icons.fitness_center,
  Icons.local_hospital,
  Icons.checkroom,
  Icons.devices,
  Icons.movie,
  Icons.flight,
  Icons.pets,
  Icons.card_giftcard,
  Icons.attach_money,
  Icons.receipt_long,
  Icons.build,
  Icons.sports_soccer,
  Icons.music_note,
  Icons.book,
  Icons.local_drink,
  Icons.coffee,
  Icons.power,
  Icons.wifi,
  Icons.child_care,
  Icons.more_horiz,
];

String _iconDataToName(IconData ico) {
  // índice paralelo a _kCatIcons
  const iconNames = [
    'shopping_cart', 'local_pharmacy', 'restaurant', 'sports_esports',
    'school', 'directions_car', 'local_gas_station', 'home',
    'beach_access', 'work', 'fitness_center', 'local_hospital',
    'checkroom', 'devices', 'movie', 'flight', 'pets', 'card_giftcard',
    'attach_money', 'receipt_long', 'build', 'sports_soccer',
    'music_note', 'book', 'local_drink', 'coffee', 'power', 'wifi',
    'child_care', 'more_horiz',
  ];
  for (int i = 0; i < _kCatIcons.length; i++) {
    if (_kCatIcons[i].codePoint == ico.codePoint &&
        _kCatIcons[i].fontFamily == ico.fontFamily) {
      return iconNames[i];
    }
  }
  return 'more_horiz';
}

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
                final sel = picked == c;
                return GestureDetector(
                  onTap: () => setSt(() => picked = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                  color: picked, borderRadius: BorderRadius.circular(8)),
              child: Center(
                  child: Text('Cor selecionada',
                      style: TextStyle(
                          color: picked.computeLuminance() > 0.4
                              ? Colors.black
                              : Colors.white,
                          fontSize: 12))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, picked),
            child: const Text('OK')),
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
  late List<String> _hiddenBankIds;
  late List<String> _hiddenCategoryIds;
  late String _catSortMode; // 'manual', 'alpha', 'usage'
  late List<String> _catOrder; // IDs na ordem manual
  late BackupConfig _backupConfig;
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    _settings = DatabaseService.getSettings();
    _customCats = DatabaseService.getCustomCategories();
    _customBanks = DatabaseService.getCustomBanks();
    _hiddenBankIds = List.from(DatabaseService.getHiddenBankIds());
    _hiddenCategoryIds = List.from(DatabaseService.getHiddenCategoryIds());
    _catSortMode = DatabaseService.getCategorySortMode();
    _catOrder = List.from(DatabaseService.getCategoryOrder());
    _backupConfig = BackupService.getConfig();
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
  void _editCategory(Category cat) async {
    final isCustom = !kDefaultCategories.any((d) => d.id == cat.id);
    final nameCtrl = TextEditingController(text: cat.name);
    Color currentColor = _overrideColor(cat.id, cat.color, isCat: true);
    IconData currentIcon = cat.icon;
    bool isDefault = DatabaseService.getCategoryDefault() == cat.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title: Text('Editar categoria',
              style: TextStyle(color: ctx.kTextPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome (apenas para custom)
                if (isCustom) ...[
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: ctx.kTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      labelStyle: TextStyle(color: ctx.kTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Cor
                Text('Cor', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kPalette.map((c) {
                    final sel = currentColor == c;
                    return GestureDetector(
                      onTap: () => setSt(() => currentColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Ícone
                Text('Ícone', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCatIcons.map((ico) {
                    final sel = currentIcon == ico;
                    return GestureDetector(
                      onTap: () => setSt(() => currentIcon = ico),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: sel
                              ? currentColor.withValues(alpha: 0.25)
                              : ctx.kCardBorder,
                          borderRadius: BorderRadius.circular(8),
                          border: sel ? Border.all(color: currentColor, width: 2) : null,
                        ),
                        child: Icon(ico, size: 18,
                            color: sel ? currentColor : ctx.kTextSecondary),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Categoria padrão
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categoria padrão',
                        style: TextStyle(color: ctx.kTextPrimary, fontSize: 13)),
                    Switch(
                      value: isDefault,
                      onChanged: (v) => setSt(() => isDefault = v),
                      activeThumbColor: AppColors.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    // Salva categoria padrão
    await DatabaseService.saveCategoryDefault(isDefault ? cat.id : null);

    final idx = _customCats.indexWhere((c) => c['id'] == cat.id);
    final newName = (isCustom && nameCtrl.text.trim().isNotEmpty)
        ? nameCtrl.text.trim()
        : cat.name;
    final iconName = _iconDataToName(currentIcon);
    final entry = {
      'id': cat.id,
      'name': newName,
      'color': colorToHex(currentColor),
      'icon': iconName,
    };
    if (idx >= 0) {
      _customCats[idx] = entry;
    } else {
      _customCats.add(entry);
    }
    await _saveCats();
  }

  // (delegado removido — _editCategoryColor não é mais chamado externamente)

  void _addCategory() async {
    final nameCtrl = TextEditingController();
    Color newColor = _kPalette[0];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title:
              Text('Nova categoria', style: TextStyle(color: ctx.kTextPrimary)),
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
                  Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor',
                      style:
                          TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Adicionar')),
          ],
        ),
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _customCats.add({
        'id': id,
        'name': nameCtrl.text.trim(),
        'color': colorToHex(newColor),
        'icon': ''
      });
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
          title:
              Text('Editar cartão', style: TextStyle(color: ctx.kTextPrimary)),
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
                  Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor',
                      style:
                          TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final idx = _customBanks.indexWhere((b) => b['id'] == bank.id);
      final entry = {
        'id': bank.id,
        'name': nameCtrl.text.trim().isEmpty ? bank.name : nameCtrl.text.trim(),
        'color': colorToHex(newColor)
      };
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
          title: Text('Novo cartão/banco',
              style: TextStyle(color: ctx.kTextPrimary)),
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
                  Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: newColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Toque para mudar cor',
                      style:
                          TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Adicionar')),
          ],
        ),
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
      _customBanks.add({
        'id': id,
        'name': nameCtrl.text.trim(),
        'color': colorToHex(newColor)
      });
      await _saveBanks();
    }
  }

  void _deleteCustomBank(String id) async {
    _customBanks.removeWhere((b) => b['id'] == id);
    await _saveBanks();
  }

  // ───────────────── Backup ──────────────────────────────────────────────

  void _reloadBackupConfig() {
    setState(() => _backupConfig = BackupService.getConfig());
  }

  Future<void> _selectBackupFolder() async {
    final path = await BackupService.selectBackupFolder();
    if (path == null) return;
    await BackupService.saveConfig(_backupConfig.copyWith(backupFolderPath: path));
    _reloadBackupConfig();
  }

  Future<void> _toggleBackupRule(String id, bool enabled) async {
    final rules = _backupConfig.rules.map((r) {
      return r.id == id ? r.copyWith(enabled: enabled) : r;
    }).toList();
    await BackupService.saveConfig(_backupConfig.copyWith(rules: rules));
    _reloadBackupConfig();
  }

  Future<void> _deleteBackupRule(String id) async {
    final rules = _backupConfig.rules.where((r) => r.id != id).toList();
    await BackupService.saveConfig(_backupConfig.copyWith(rules: rules));
    _reloadBackupConfig();
  }

  Future<void> _addBackupRule() async {
    BackupRuleType selectedType = BackupRuleType.onSave;
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    int selectedWeekday = DateTime.monday;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSt) => AlertDialog(
          backgroundColor: ctx.kCard,
          title: Text('Nova Regra', style: TextStyle(color: ctx.kTextPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo', style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                ...BackupRuleType.values
                    .where((t) => t != BackupRuleType.manual)
                    .map((t) => RadioListTile<BackupRuleType>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_ruleTypeName(t),
                              style: TextStyle(
                                  color: ctx.kTextPrimary, fontSize: 13)),
                          value: t,
                          groupValue: selectedType,
                          activeColor: AppColors.accent,
                          onChanged: (v) => setSt(() => selectedType = v!),
                        )),
                if (selectedType == BackupRuleType.scheduled ||
                    selectedType == BackupRuleType.weekly) ...[
                  const SizedBox(height: 12),
                  if (selectedType == BackupRuleType.weekly) ...[
                    Text('Dia da semana',
                        style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButton<int>(
                      value: selectedWeekday,
                      dropdownColor: ctx.kCard,
                      style: TextStyle(color: ctx.kTextPrimary),
                      underline: const SizedBox.shrink(),
                      items: [
                        for (int i = 1; i <= 7; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(_weekdayName(i)),
                          ),
                      ],
                      onChanged: (v) => setSt(() => selectedWeekday = v!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text('Horário',
                      style: TextStyle(color: ctx.kTextSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: ctx2,
                        initialTime: selectedTime,
                      );
                      if (t != null) setSt(() => selectedTime = t);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accent, width: 1),
                      ),
                      child: Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            color: ctx.kTextPrimary,
                            fontFamily: 'JetBrainsMono',
                            fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Adicionar')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final newRule = BackupRule(
      id: BackupService.newRuleId(),
      type: selectedType,
      scheduledHour: (selectedType == BackupRuleType.scheduled ||
              selectedType == BackupRuleType.weekly)
          ? selectedTime.hour
          : null,
      scheduledMinute: (selectedType == BackupRuleType.scheduled ||
              selectedType == BackupRuleType.weekly)
          ? selectedTime.minute
          : null,
      weekday:
          selectedType == BackupRuleType.weekly ? selectedWeekday : null,
    );

    await BackupService.saveConfig(
        _backupConfig.copyWith(rules: [..._backupConfig.rules, newRule]));
    _reloadBackupConfig();
  }

  Future<void> _manualBackup() async {
    setState(() => _backingUp = true);
    final messenger = ScaffoldMessenger.of(context);
    final success = await BackupService.performBackup(_backupConfig);
    _reloadBackupConfig();
    setState(() => _backingUp = false);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success ? 'Backup realizado com sucesso!' : 'Erro ao realizar backup. Verifique a pasta configurada.'),
      backgroundColor: success ? AppColors.income : AppColors.expense,
    ));
  }

  String _ruleTypeName(BackupRuleType t) {
    switch (t) {
      case BackupRuleType.manual: return 'Manual';
      case BackupRuleType.onSave: return 'A cada salvamento';
      case BackupRuleType.scheduled: return 'Horário fixo diário';
      case BackupRuleType.weekly: return 'Dia da semana';
    }
  }

  String _weekdayName(int weekday) {
    const names = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return names[weekday - 1];
  }

  String get _backupFolderDisplay {
    final path = _backupConfig.backupFolderPath;
    if (path == null || path.isEmpty) return 'Não configurada (usa pasta padrão do app)';
    if (path.length > 42) return '...${path.substring(path.length - 42)}';
    return path;
  }

  IconData _ruleIcon(BackupRuleType type) {
    switch (type) {
      case BackupRuleType.onSave: return Icons.save_outlined;
      case BackupRuleType.scheduled: return Icons.access_time;
      case BackupRuleType.weekly: return Icons.date_range_outlined;
      case BackupRuleType.manual: return Icons.touch_app_outlined;
    }
  }

  String get _lastBackupDisplay {
    final last = _backupConfig.lastBackupAt;
    if (last == null) return 'Nunca';
    final d = '${last.day.toString().padLeft(2, '0')}/${last.month.toString().padLeft(2, '0')}/${last.year}';
    final t = '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
    return '$d às $t';
  }

  void _toggleBankVisibility(String id) async {
    setState(() {
      if (_hiddenBankIds.contains(id)) {
        _hiddenBankIds.remove(id);
      } else {
        _hiddenBankIds.add(id);
      }
    });
    await DatabaseService.saveHiddenBankIds(_hiddenBankIds);
  }

  void _toggleCategoryVisibility(String id) async {
    setState(() {
      if (_hiddenCategoryIds.contains(id)) {
        _hiddenCategoryIds.remove(id);
      } else {
        _hiddenCategoryIds.add(id);
      }
    });
    await DatabaseService.saveHiddenCategoryIds(_hiddenCategoryIds);
  }

  void _setCatSortMode(String mode) {
    setState(() => _catSortMode = mode);
    DatabaseService.saveCategorySortMode(mode);
  }

  // ────────────────────────────────────────────────────── build ──
  @override
  Widget build(BuildContext context) {
    List<Category> allCats = getAllCategories();
    // Aplica ordenação conforme _catSortMode
    if (_catSortMode == 'alpha') {
      allCats.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_catSortMode == 'manual' && _catOrder.isNotEmpty) {
      final idIndex = {
        for (int i = 0; i < _catOrder.length; i++) _catOrder[i]: i
      };
      allCats.sort((a, b) {
        final ia = idIndex[a.id] ?? 9999;
        final ib = idIndex[b.id] ?? 9999;
        return ia.compareTo(ib);
      });
    }
    // Ocultos sempre ficam no final, independentemente de filtro ou ordenação
    {
      final hiddenSet = _hiddenCategoryIds.toSet();
      final visibleCats = allCats.where((c) => !hiddenSet.contains(c.id)).toList();
      final hiddenCats  = allCats.where((c) =>  hiddenSet.contains(c.id)).toList();
      allCats = [...visibleCats, ...hiddenCats];
    }

    // Bancos: ocultos sempre ficam no final
    final List<BankDef> allBanks = () {
      final raw = getAllBanks();
      final hiddenSet = _hiddenBankIds.toSet();
      final visibleBanks = raw.where((b) => !hiddenSet.contains(b.id)).toList();
      final hiddenBanks  = raw.where((b) =>  hiddenSet.contains(b.id)).toList();
      return [...visibleBanks, ...hiddenBanks];
    }();
    bool isCustomCat(String id) => _customCats.any(
        (c) => c['id'] == id && !kDefaultCategories.any((d) => d.id == id));

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
              items: const {
                'BRL': 'R\$ Real (BRL)',
                'USD': '\$ Dólar (USD)',
                'EUR': '€ Euro (EUR)'
              },
              onChanged: (v) {
                _settings.currency = v!;
                _save();
              },
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
              onChanged: (v) {
                _settings.carryoverMode = v;
                _save();
              },
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
              onChanged: (v) {
                _settings.goalsEnabled = v;
                _save();
              },
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
              onChanged: (v) {
                _settings.familyMode = v;
                _save();
              },
            ),
            if (_settings.familyMode) ...[
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Número de membros',
                        style: TextStyle(
                            color: context.kTextSecondary, fontSize: 12)),
                    Slider(
                      value: _settings.familyCount.toDouble(),
                      min: 2,
                      max: 6,
                      divisions: 4,
                      label: _settings.familyCount.toString(),
                      onChanged: (v) {
                        _settings.familyCount = v.toInt();
                        _save();
                      },
                    ),
                    Text('${_settings.familyCount} membros',
                        style: TextStyle(color: context.kTextPrimary)),
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
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: EdgeInsets.zero),
              ),
            ],
          ),
          // Sort mode selector
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _SortModeBtn(
                  label: 'Manual',
                  selected: _catSortMode == 'manual',
                  onTap: () => _setCatSortMode('manual'),
                ),
                const SizedBox(width: 6),
                _SortModeBtn(
                  label: 'A–Z',
                  selected: _catSortMode == 'alpha',
                  onTap: () => _setCatSortMode('alpha'),
                ),
                const SizedBox(width: 6),
                _SortModeBtn(
                  label: 'Mais usadas',
                  selected: _catSortMode == 'usage',
                  onTap: () => _setCatSortMode('usage'),
                ),
              ],
            ),
          ),
          if (_catSortMode == 'manual')
            Container(
              decoration: BoxDecoration(
                color: context.kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.kCardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: allCats.length,
                onReorder: (oldIdx, newIdx) {
                  if (newIdx > oldIdx) newIdx--;
                  setState(() {
                    final moved = allCats.removeAt(oldIdx);
                    allCats.insert(newIdx, moved);
                    _catOrder = allCats.map((c) => c.id).toList();
                  });
                  DatabaseService.saveCategoryOrder(_catOrder);
                },
                itemBuilder: (ctx, idx) {
                  final cat = allCats[idx];
                  final displayColor =
                      _overrideColor(cat.id, cat.color, isCat: true);
                  final isCustom = isCustomCat(cat.id);
                  final isCatHidden = _hiddenCategoryIds.contains(cat.id);
                  return _CatTile(
                    key: ValueKey(cat.id),
                    cat: cat,
                    displayColor: displayColor,
                    isCustom: isCustom,
                    isCatHidden: isCatHidden,
                    showDragHandle: true,
                    isFirst: idx == 0,
                    onTap: () => _editCategory(cat),
                    onToggleVisibility: () =>
                        _toggleCategoryVisibility(cat.id),
                    onDelete: () => _deleteCustomCategory(cat.id),
                  );
                },
              ),
            )
          else
            _Card(children: [
              ...allCats.asMap().entries.map((e) {
                final cat = e.value;
                final displayColor =
                    _overrideColor(cat.id, cat.color, isCat: true);
                final isCustom = isCustomCat(cat.id);
                final isCatHidden = _hiddenCategoryIds.contains(cat.id);
                return _CatTile(
                  key: ValueKey(cat.id),
                  cat: cat,
                  displayColor: displayColor,
                  isCustom: isCustom,
                  isCatHidden: isCatHidden,
                  showDragHandle: false,
                  isFirst: e.key == 0,
                  onTap: () => _editCategory(cat),
                  onToggleVisibility: () =>
                      _toggleCategoryVisibility(cat.id),
                  onDelete: () => _deleteCustomCategory(cat.id),
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
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: EdgeInsets.zero),
              ),
            ],
          ),
          _Card(children: [
            ...allBanks.asMap().entries.map((e) {
              final i = e.key;
              final bank = e.value;
              final displayColor =
                  _overrideColor(bank.id, bank.color, isCat: false);
              final isCustom = _customBanks.any((b) =>
                  b['id'] == bank.id &&
                  !kDefaultBanks.any((d) => d.id == bank.id));
              final isHidden = _hiddenBankIds.contains(bank.id);
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Opacity(
                      opacity: isHidden ? 0.35 : 1.0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: displayColor,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.credit_card,
                            color: Colors.white, size: 14),
                      ),
                    ),
                    title: Text(bank.name,
                        style: TextStyle(
                            color: isHidden
                                ? context.kTextSecondary
                                : context.kTextPrimary,
                            fontSize: 13)),
                    subtitle: isHidden
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Oculto',
                                    style: TextStyle(
                                        color: AppColors.textSecondary, fontSize: 9)),
                              ),
                              const SizedBox(width: 6),
                              Text(isCustom ? 'Customizado' : 'Padrão',
                                  style: TextStyle(
                                      color: context.kTextSecondary, fontSize: 10)),
                            ],
                          )
                        : Text(isCustom ? 'Customizado' : 'Padrão',
                            style: TextStyle(
                                color: context.kTextSecondary, fontSize: 10)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: isHidden
                                ? context.kTextSecondary
                                : AppColors.accent,
                          ),
                          onPressed: () => _toggleBankVisibility(bank.id),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.accent),
                          onPressed: () => _editBank(bank),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                        if (isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.expense),
                            onPressed: () => _deleteCustomBank(bank.id),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ]),

          // Vencimento de Cartões
          const SizedBox(height: 12),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.credit_score, color: AppColors.accent),
              title: Text('Vencimento de Cartões',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Configurar dia de fechamento e pagamento',
                  style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardDueDatesScreen()),
              ),
            ),
          ]),

          // ── Dados ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionTitle('Dados'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.accent),
              title: Text('Importar dados (JSON)',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Importar farmas-dados.json',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final result = await ImportService.importJsonFromPicker();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(result == null
                      ? 'Importação cancelada'
                      : '${result.transactions} transações, ${result.incomes} entradas e ${result.cardDueDates} vencimentos importados'),
                  backgroundColor: result == null
                      ? AppColors.textSecondary
                      : AppColors.income,
                ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download, color: AppColors.neonCyan),
              title: Text('Exportar dados (JSON)',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Salvar backup como konta.json',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                final path = await ImportService.exportJsonWithPicker();
                if (!mounted) return;
                messenger.showSnackBar(SnackBar(
                  content: Text(path == null
                      ? 'Exportação cancelada'
                      : 'Exportado: $path'),
                  backgroundColor:
                      path == null ? AppColors.textSecondary : AppColors.income,
                ));
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: AppColors.expense),
              title: const Text('Limpar todos os dados',
                  style: TextStyle(color: AppColors.expense)),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ctx.kCard,
                  title: const Text('Apagar tudo?',
                      style: TextStyle(color: AppColors.expense)),
                  content: Text(
                      'Esta ação é irreversível. Todos os lançamentos serão excluídos.',
                      style: TextStyle(color: ctx.kTextSecondary)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await DatabaseService.clearAll();
                        if (!mounted) return;
                        setState(() {});
                      },
                      child: const Text('Apagar',
                          style: TextStyle(color: AppColors.expense)),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          // ── Backup Automático ──────────────────────────────────────────
          const SizedBox(height: 20),
          _SectionTitle('Backup Automático'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: AppColors.accent),
              title: Text('Pasta de backup',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text(_backupFolderDisplay,
                  style: TextStyle(
                      color: context.kTextSecondary, fontSize: 11)),
              trailing: TextButton(
                onPressed: _selectBackupFolder,
                child: const Text('Selecionar'),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.accent),
              title: Text('Último backup',
                  style: TextStyle(color: context.kTextPrimary, fontSize: 13)),
              subtitle: Text(_lastBackupDisplay,
                  style: TextStyle(
                      color: context.kTextSecondary, fontSize: 12)),
            ),
            if (_backupConfig.rules.isNotEmpty) ...[
              const Divider(height: 1),
              ..._backupConfig.rules.asMap().entries.map((e) {
                final rule = e.value;
                return Column(
                  children: [
                    if (e.key > 0) const Divider(height: 1),
                    ListTile(
                      dense: true,
                      leading: Icon(_ruleIcon(rule.type),
                          color: AppColors.accent, size: 20),
                      title: Text(rule.displayLabel,
                          style: TextStyle(
                              color: context.kTextPrimary, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: rule.enabled,
                            activeThumbColor: AppColors.accent,
                            onChanged: (v) => _toggleBackupRule(rule.id, v),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.expense),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _deleteBackupRule(rule.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.add_circle_outline, color: AppColors.accent),
              title: Text('Adicionar Regra',
                  style: TextStyle(color: context.kTextPrimary, fontSize: 13)),
              onTap: _addBackupRule,
            ),
          ]),
          const SizedBox(height: 8),
          _Card(children: [
            ListTile(
              leading: _backingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent))
                  : const Icon(Icons.cloud_done_outlined,
                      color: AppColors.accent),
              title: Text('Fazer Backup Agora',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('Sobrescreve konta_backup.json na pasta escolhida',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              onTap: _backingUp ? null : _manualBackup,
            ),
          ]),

          const SizedBox(height: 20),
          _SectionTitle('Sobre'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.new_releases_outlined, color: AppColors.accent),
              title: Text('Últimas Atualizações',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text('v$kAppVersion — veja o que há de novo',
                  style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.kTextSecondary),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangelogScreen()),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.shield_outlined, color: AppColors.accent),
              title: Text('Política de Privacidade',
                  style: TextStyle(color: context.kTextPrimary)),
              subtitle: Text(
                  'Versão $kPrivacyPolicyVersion — $kPrivacyPolicyDate',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              trailing:
                  Icon(Icons.chevron_right, color: context.kTextSecondary),
              onTap: () => context.push('/privacy-policy?view=true'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.info_outline, color: context.kTextSecondary),
              title:
                  Text('Versão', style: TextStyle(color: context.kTextPrimary)),
              trailing: Text(kAppVersion,
                  style: TextStyle(
                      color: context.kTextSecondary,
                      fontFamily: 'JetBrainsMono')),
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
        child: Text(text,
            style: TextStyle(
                color: context.kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: context.kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.kCardBorder)),
        child: Column(children: children),
      );
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile(
      {required this.label,
      this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        title: Text(label,
            style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: TextStyle(color: context.kTextSecondary, fontSize: 12))
            : null,
        value: value,
        onChanged: onChanged,
      );
}

class _SortModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortModeBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.18)
                : context.kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : context.kCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accent : context.kTextSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      );
}

class _CatTile extends StatelessWidget {
  final Category cat;
  final Color displayColor;
  final bool isCustom;
  final bool isCatHidden;
  final bool showDragHandle;
  final bool isFirst;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  const _CatTile({
    super.key,
    required this.cat,
    required this.displayColor,
    required this.isCustom,
    required this.isCatHidden,
    required this.showDragHandle,
    required this.isFirst,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (!isFirst) const Divider(height: 1),
          ListTile(
            dense: true,
            onTap: onTap,
            leading: Opacity(
              opacity: isCatHidden ? 0.35 : 1.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: displayColor, shape: BoxShape.circle),
                child:
                    Icon(cat.icon, color: Colors.white, size: 14),
              ),
            ),
            title: Text(cat.name,
                style: TextStyle(
                    color: isCatHidden
                        ? context.kTextSecondary
                        : context.kTextPrimary,
                    fontSize: 13)),
            subtitle: isCatHidden
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Oculto',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 9)),
                      ),
                      const SizedBox(width: 6),
                      Text(isCustom ? 'Customizada' : 'Padrão',
                          style: TextStyle(
                              color: context.kTextSecondary, fontSize: 10)),
                    ],
                  )
                : Text(
                    isCustom ? 'Customizada' : 'Toque para editar',
                    style: TextStyle(
                        color: context.kTextSecondary, fontSize: 10)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isCatHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: isCatHidden
                        ? context.kTextSecondary
                        : AppColors.accent,
                  ),
                  onPressed: onToggleVisibility,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                ),
                if (isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.expense),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                if (showDragHandle)
                  const Icon(Icons.drag_handle,
                      size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      );
}

class _DropdownTile<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> items;
  final void Function(T?) onChanged;
  const _DropdownTile(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
            DropdownButton<T>(
              value: value,
              dropdownColor: context.kCard,
              style: TextStyle(color: context.kTextPrimary),
              underline: const SizedBox.shrink(),
              items: items.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = DatabaseService.getSettings();
  }

  Future<void> _save() async {
    await DatabaseService.saveSettings(_settings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
              onChanged: (v) { _settings.theme = v ? 'dark' : 'light'; _save(); },
            ),
          ]),

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
                    const Text('Número de membros', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Slider(
                      value: _settings.familyCount.toDouble(),
                      min: 2,
                      max: 6,
                      divisions: 4,
                      label: _settings.familyCount.toString(),
                      onChanged: (v) { _settings.familyCount = v.toInt(); _save(); },
                    ),
                    Text('${_settings.familyCount} membros', style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ]),

          const SizedBox(height: 20),
          _SectionTitle('Dados'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.accent),
              title: const Text('Importar dados (JSON)', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Importar farmas-dados.json', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () async {
                final result = await ImportService.importJsonFromPicker();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
              title: const Text('Exportar dados (JSON)', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Salvar backup na pasta Downloads', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              onTap: () async {
                final path = await ImportService.exportJsonToDownloads();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.card,
                  title: const Text('Apagar tudo?', style: TextStyle(color: AppColors.expense)),
                  content: const Text('Esta ação é irreversível. Todos os lançamentos serão excluídos.', style: TextStyle(color: AppColors.textSecondary)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
            const ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
              title: Text('Versão', style: TextStyle(color: AppColors.textPrimary)),
              trailing: Text('1.0.0', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'JetBrainsMono')),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
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
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)) : null,
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
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            DropdownButton<T>(
              value: value,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.textPrimary),
              underline: const SizedBox.shrink(),
              items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/income.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/keyboard_restore_mixin.dart';

class AddIncomeForm extends StatefulWidget {
  final Income? editing;
  final DateTime? initialDate;
  final void Function(Income) onSave;
  final VoidCallback? onDelete;

  const AddIncomeForm({
    super.key,
    this.editing,
    this.initialDate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddIncomeForm> createState() => _AddIncomeFormState();
}

class _AddIncomeFormState extends State<AddIncomeForm>
    with WidgetsBindingObserver, KeyboardRestoreMixin {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  late FocusNode _descFocus;
  late FocusNode _amountFocus;
  late DateTime _date;
  bool _recurring = false;
  bool _isFamilyValue = false;

  @override
  void initState() {
    super.initState();
    _descFocus = FocusNode();
    _amountFocus = FocusNode();
    registerFocusNode(_descFocus);
    registerFocusNode(_amountFocus);
    final e = widget.editing;
    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text = e.amount.toStringAsFixed(2).replaceAll('.', ',');
      _date = e.date;
      _recurring = e.recurring;
      _isFamilyValue = e.isFamilyValue;
    } else {
      _date = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _descFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(raw) ?? 0;

    final income = Income(
      id: widget.editing?.id ?? const Uuid().v4(),
      description: _descCtrl.text.trim(),
      amount: amount,
      date: _date,
      recurring: _recurring,
      isFamilyValue: _isFamilyValue,
    );
    widget.onSave(income);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.kCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: context.kCardBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Título + botão excluir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.editing == null ? 'Nova Entrada' : 'Editar Entrada',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.kTextPrimary),
                  ),
                  if (widget.editing != null && widget.onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDelete!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Descrição
              TextFormField(
                controller: _descCtrl,
                focusNode: _descFocus,
                style: TextStyle(color: context.kTextPrimary),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Descrição', hintText: 'Ex: Salário, Freelance...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Valor
              TextFormField(
                controller: _amountCtrl,
                focusNode: _amountFocus,
                style: const TextStyle(color: AppColors.income, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Data', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                subtitle: Text(formatDate(_date), style: TextStyle(color: context.kTextPrimary, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.calendar_today, color: AppColors.accent, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 4),

              // Recorrente
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Entrada recorrente (mensal)', style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
                subtitle: Text('Aparece em todos os meses', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v),
              ),

              // Valor de Família
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Marcar como valor de família', style: TextStyle(color: context.kTextPrimary, fontSize: 14)),
                subtitle: Text('Não soma no saldo pessoal', style: TextStyle(color: context.kTextSecondary, fontSize: 12)),
                value: _isFamilyValue,
                onChanged: (v) => setState(() => _isFamilyValue = v),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.income),
                child: const Text('Salvar Entrada'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

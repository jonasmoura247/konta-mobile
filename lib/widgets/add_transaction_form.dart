import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/bank.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum SubscriptionEditScope { fromStart, fromMonth }

class TransactionFormResult {
  final Transaction transaction;
  final SubscriptionEditScope subscriptionEditScope;

  const TransactionFormResult({
    required this.transaction,
    this.subscriptionEditScope = SubscriptionEditScope.fromStart,
  });
}

class AddTransactionForm extends StatefulWidget {
  final Transaction? editing;
  final FutureOr<void> Function(Transaction) onSave;
  final bool isDebit;
  final DateTime? initialDate;
  final bool returnTransaction;
  final DateTime? subscriptionEditMonth;

  const AddTransactionForm(
      {super.key,
      this.editing,
      required this.onSave,
      this.isDebit = false,
      this.initialDate,
      this.returnTransaction = false,
      this.subscriptionEditMonth});

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _installCtrl = TextEditingController(text: '1');

  late String _groupId;
  String _categoryId = 'outros';
  String? _bankId;
  DateTime _date = DateTime.now();
  bool _familyMode = false;
  SubscriptionEditScope _subscriptionEditScope =
      SubscriptionEditScope.fromMonth;

  bool get _isDebitMode => _groupId == 'debito';

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _descCtrl.text = e.description;
      _amountCtrl.text = e.totalAmount.toStringAsFixed(2).replaceAll('.', ',');
      _installCtrl.text = e.installments.toString();
      _groupId = e.groupId;
      _categoryId = e.categoryId;
      _bankId = e.bankId;
      _date = e.startDate;
      _familyMode = e.familyMode;
    } else {
      _groupId = widget.isDebit ? 'debito' : 'avista';
      _date = widget.initialDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    _installCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rawAmount = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(rawAmount) ?? 0;
    final id = widget.editing?.id ?? const Uuid().v4();

    final t = Transaction(
      id: id,
      groupId: _groupId,
      categoryId: _categoryId,
      description: _descCtrl.text.trim(),
      totalAmount: amount,
      installments: _groupId == 'parcelamento'
          ? (int.tryParse(_installCtrl.text) ?? 1)
          : 1,
      startDate: (_groupId == 'assinatura' && widget.editing != null)
          ? widget.editing!.startDate
          : _date,
      isSubscription: _groupId == 'assinatura',
      bankId: _bankId,
      familyMode: _familyMode,
      cancelledFrom:
          _groupId == 'assinatura' ? widget.editing?.cancelledFrom : null,
      createdAt: widget.editing?.createdAt ?? DateTime.now(),
      subscriptionSeriesId: _groupId == 'assinatura'
          ? (widget.editing?.subscriptionSeriesId ?? id)
          : null,
    );
    final navigator = Navigator.of(context);
    if (widget.returnTransaction) {
      navigator.pop(TransactionFormResult(
        transaction: t,
        subscriptionEditScope: _subscriptionEditScope,
      ));
      return;
    }
    await widget.onSave(t);
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: context.kCardBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.editing == null
                    ? (_isDebitMode ? 'Novo Débito' : 'Novo Lançamento')
                    : (_isDebitMode ? 'Editar Débito' : 'Editar Lançamento'),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.kTextPrimary),
              ),
              const SizedBox(height: 20),

              // Tipo (oculto no modo débito — groupId fica fixo em 'debito')
              if (!_isDebitMode) ...[
                Text('Tipo',
                    style:
                        TextStyle(color: context.kTextSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _GroupChip('À Vista', 'avista', _groupId,
                        (v) => setState(() => _groupId = v)),
                    const SizedBox(width: 8),
                    _GroupChip('Parcelado', 'parcelamento', _groupId,
                        (v) => setState(() => _groupId = v)),
                    const SizedBox(width: 8),
                    _GroupChip('Assinatura', 'assinatura', _groupId,
                        (v) => setState(() => _groupId = v)),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Descrição
              TextFormField(
                controller: _descCtrl,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // Valor
              TextFormField(
                controller: _amountCtrl,
                style: TextStyle(
                    color: context.kTextPrimary, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(
                    labelText: 'Valor (R\$)', prefixText: 'R\$ '),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  final parsed = double.tryParse(
                      v.replaceAll('.', '').replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Parcelas (só para parcelamento)
              if (_groupId == 'parcelamento') ...[
                TextFormField(
                  controller: _installCtrl,
                  style: TextStyle(color: context.kTextPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Número de parcelas'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
              ],

              // Data (oculta ao editar assinatura — a data de início é imutável)
              if (!(_groupId == 'assinatura' && widget.editing != null))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Data',
                      style: TextStyle(
                          color: context.kTextSecondary, fontSize: 12)),
                  subtitle: Text(formatDate(_date),
                      style: TextStyle(color: context.kTextPrimary)),
                  trailing: const Icon(Icons.calendar_today,
                      color: AppColors.accent, size: 18),
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
              const SizedBox(height: 12),

              // Categoria
              Text('Categoria',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                dropdownColor: context.kCard,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(),
                items: getVisibleCategories()
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Icon(c.icon, color: c.color, size: 18),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v!),
              ),
              const SizedBox(height: 12),

              // Banco
              Text('Banco',
                  style:
                      TextStyle(color: context.kTextSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: _bankId,
                dropdownColor: context.kCard,
                style: TextStyle(color: context.kTextPrimary),
                decoration: const InputDecoration(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sem banco')),
                  ...getVisibleBanks().map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: b.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(b.name),
                        ]),
                      )),
                ],
                onChanged: (v) => setState(() => _bankId = v),
              ),
              const SizedBox(height: 12),

              // Modo família
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Modo família (dividir valor)',
                    style:
                        TextStyle(color: context.kTextPrimary, fontSize: 14)),
                value: _familyMode,
                onChanged: (v) => setState(() => _familyMode = v),
              ),
              if (_groupId == 'assinatura' &&
                  widget.editing != null &&
                  widget.subscriptionEditMonth != null) ...[
                const SizedBox(height: 12),
                Text('Aplicar alteração',
                    style:
                        TextStyle(color: context.kTextSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                _ScopeOption(
                  title:
                      'A partir de ${formatMonth(widget.subscriptionEditMonth!)}',
                  subtitle:
                      'Preserva os meses anteriores e cria uma nova versão.',
                  selected:
                      _subscriptionEditScope == SubscriptionEditScope.fromMonth,
                  onTap: () => setState(() =>
                      _subscriptionEditScope = SubscriptionEditScope.fromMonth),
                ),
                const SizedBox(height: 8),
                _ScopeOption(
                  title: 'Desde o início',
                  subtitle: 'Altera todo o período desta assinatura.',
                  selected:
                      _subscriptionEditScope == SubscriptionEditScope.fromStart,
                  onTap: () => setState(() =>
                      _subscriptionEditScope = SubscriptionEditScope.fromStart),
                ),
              ],
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Salvar'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _GroupChip(this.label, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : context.kCardBorder,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : context.kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : context.kCardBorder.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : context.kCardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.accent : context.kTextSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppColors.accent : context.kTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style:
                        TextStyle(color: context.kTextSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

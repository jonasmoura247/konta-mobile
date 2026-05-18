import 'package:flutter/material.dart';
import '../services/database_service.dart';

class BankDef {
  final String id;
  final String name;
  final Color color;
  const BankDef({required this.id, required this.name, required this.color});
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
  return const Color(0xFF546E7A);
}

String colorToHex(Color c) {
  int channel(double value) => (value * 255).round().clamp(0, 255);
  return '#${channel(c.r).toRadixString(16).padLeft(2, '0')}'
          '${channel(c.g).toRadixString(16).padLeft(2, '0')}'
          '${channel(c.b).toRadixString(16).padLeft(2, '0')}'
      .toUpperCase();
}

const List<BankDef> kDefaultBanks = [
  BankDef(id: 'itau',        name: 'Banco 1',  color: Color(0xFF006CA7)),
  BankDef(id: 'bradesco',    name: 'Banco 2',  color: Color(0xFFCC092F)),
  BankDef(id: 'caixa',       name: 'Banco 3',  color: Color(0xFF005CA9)),
  BankDef(id: 'bb',          name: 'Banco 4',  color: Color(0xFFF7C302)),
  BankDef(id: 'santander',   name: 'Banco 5',  color: Color(0xFFEC0000)),
  BankDef(id: 'sicoob',      name: 'Banco 6',  color: Color(0xFF008542)),
  BankDef(id: 'sicredi',     name: 'Banco 7',  color: Color(0xFF04A85B)),
  BankDef(id: 'btg',         name: 'Banco 8',  color: Color(0xFF004C97)),
  BankDef(id: 'safra',       name: 'Banco 9',  color: Color(0xFF01358C)),
  BankDef(id: 'nubank',      name: 'Banco 10', color: Color(0xFF820AD1)),
  BankDef(id: 'inter',       name: 'Banco 11', color: Color(0xFFFF6B00)),
  BankDef(id: 'c6',          name: 'Banco 12', color: Color(0xFF505050)),
  BankDef(id: 'neon',        name: 'Banco 13', color: Color(0xFF2B47FC)),
  BankDef(id: 'next',        name: 'Banco 14', color: Color(0xFF00C06C)),
  BankDef(id: 'picpay',      name: 'Banco 15', color: Color(0xFF11C76F)),
  BankDef(id: 'pagbank',     name: 'Banco 16', color: Color(0xFF03A64A)),
  BankDef(id: 'mercadopago', name: 'Banco 17', color: Color(0xFF00B4E6)),
  BankDef(id: 'stone',       name: 'Banco 18', color: Color(0xFF00A868)),
  BankDef(id: 'xp',          name: 'Banco 19', color: Color(0xFF00CC66)),
  BankDef(id: 'will',        name: 'Banco 20', color: Color(0xFFF9C01D)),
];

List<BankDef> getAllBanks() {
  final result = {for (final b in kDefaultBanks) b.id: b};
  for (final b in DatabaseService.getCustomBanks()) {
    final id = b['id'] as String;
    result[id] = BankDef(
      id: id,
      name: b['name'] as String,
      color: _hexToColor(b['color'] as String? ?? '#546E7A'),
    );
  }
  return result.values.toList();
}

BankDef? getBankById(String? id) {
  if (id == null) return null;
  return getAllBanks().firstWhere((b) => b.id == id,
      orElse: () => BankDef(id: id, name: id, color: Colors.grey));
}

List<BankDef> getVisibleBanks() {
  final hidden = DatabaseService.getHiddenBankIds().toSet();
  return getAllBanks().where((b) => !hidden.contains(b.id)).toList();
}

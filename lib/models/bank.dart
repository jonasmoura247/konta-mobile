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

String colorToHex(Color c) =>
    '#${c.red.toRadixString(16).padLeft(2, '0')}${c.green.toRadixString(16).padLeft(2, '0')}${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

const List<BankDef> kDefaultBanks = [
  BankDef(id: 'itau',   name: 'Itaú',   color: Color(0xFF006CA7)),
  BankDef(id: 'nubank', name: 'Nubank', color: Color(0xFF820AD1)),
  BankDef(id: 'inter',  name: 'Inter',  color: Color(0xFFFF6B00)),
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
  return getAllBanks().firstWhere((b) => b.id == id, orElse: () => BankDef(id: id, name: id, color: Colors.grey));
}

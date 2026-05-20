import 'package:flutter/services.dart';

/// Garante programaticamente que o primeiro caractere seja maiúsculo.
/// Complementa textCapitalization, que é apenas dica ao teclado virtual.
class CapitalizeFirstFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text;
    final capitalized = text[0].toUpperCase() + text.substring(1);
    if (capitalized == text) return newValue;
    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
    );
  }
}

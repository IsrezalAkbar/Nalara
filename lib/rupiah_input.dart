import 'package:flutter/services.dart';

import 'products.dart' show productRupiah;

String formatRupiahInput(int amount) => productRupiah(amount).substring(2);
int? parseRupiahInput(String text) => int.tryParse(text.replaceAll('.', ''));

// Use after digitsOnly so both typing and pasted amounts share the same format.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final amount = int.tryParse(newValue.text);
    if (amount == null) return oldValue;
    final formatted = formatRupiahInput(amount);
    final digitsAfterCursor =
        newValue.text.length -
        newValue.selection.extentOffset.clamp(0, newValue.text.length);
    var offset = formatted.length;
    var digits = 0;
    while (offset > 0 && digits < digitsAfterCursor) {
      offset--;
      if (formatted[offset] != '.') digits++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

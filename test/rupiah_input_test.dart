import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalara/rupiah_input.dart';

void main() {
  TextEditingValue edit(String input, {int? cursor}) {
    const previous = TextEditingValue.empty;
    var value = TextEditingValue(
      text: input,
      selection: TextSelection.collapsed(offset: cursor ?? input.length),
    );
    for (final formatter in [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(12),
      RupiahInputFormatter(),
    ]) {
      value = formatter.formatEditUpdate(previous, value);
    }
    return value;
  }

  test(
    'Cash uses Indonesian thousands separators and parses stored integers',
    () {
      for (final pair in {
        '0': '0',
        '1000': '1.000',
        '50000': '50.000',
        '100000': '100.000',
        '1234567': '1.234.567',
        '0001000': '1.000',
        'Rp 250.000': '250.000',
      }.entries) {
        final value = edit(pair.key);
        expect(value.text, pair.value);
        expect(
          parseRupiahInput(value.text),
          int.parse(pair.value.replaceAll('.', '')),
        );
      }
      expect(edit('').text, '');
      expect(parseRupiahInput(''), isNull);
      expect(edit('1234567890123').text, '123.456.789.012');
    },
  );

  test(
    'Formatting keeps the cursor near an insertion in the middle of cash',
    () {
      final result = edit('1250000', cursor: 3);
      expect(result.text, '1.250.000');
      expect(result.selection.extentOffset, 4);
    },
  );
}

import 'package:flutter/services.dart';

/// Formats input with TR locale: dot thousand separators, comma decimal separator
/// e.g. 12345678 -> 12.345.678 | 12345,67 -> 12.345,67
class ThousandsInputFormatter extends TextInputFormatter {
  String _formatWithThousands(String text) {
    if (text.isEmpty) return '';

    // Separate integer and decimal parts
    String integerPart = text;
    String decimalPart = '';

    if (text.contains(',')) {
      final parts = text.split(',');
      integerPart = parts[0];
      decimalPart = parts.length > 1 ? parts[1] : '';
    }

    // Handle integer part
    if (integerPart.isEmpty) {
      integerPart = '0';
    } else {
      // Remove leading zeros from integer part
      integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (integerPart.isEmpty) integerPart = '0';
    }

    // Add dots every 3 digits from the right for integer part
    final rev = integerPart.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(rev[i]);
    }
    final formattedInteger = buffer.toString().split('').reversed.join();

    // Combine integer and decimal parts
    if (decimalPart.isNotEmpty) {
      return '$formattedInteger,$decimalPart';
    }
    return formattedInteger;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Keep only digits, comma, and dots
    text = text.replaceAll(RegExp(r'[^0-9,.]'), '');

    // Handle multiple commas - keep only the first one
    if (text.contains(',')) {
      final commaIndex = text.indexOf(',');
      final beforeComma = text.substring(0, commaIndex);
      final afterComma = text.substring(commaIndex + 1);

      // Remove all dots from integer part and dots from decimal part
      final intPart = beforeComma.replaceAll('.', '');
      final decPart = afterComma.replaceAll('.', '');

      text = '$intPart,$decPart';
    } else {
      // No comma, just remove all dots
      text = text.replaceAll('.', '');
    }

    // Format with thousand separators
    final formatted = _formatWithThousands(text);

    // Calculate cursor position - place it before the automatically added dots
    // Calculate cursor position
    int originalLength = newValue.text.length;
    int newLength = formatted.length;
    int diff = newLength - originalLength;

    int oldCursorPos = newValue.selection.base.offset;
    int newCursorPos = oldCursorPos + diff;

    if (newCursorPos > formatted.length) {
      newCursorPos = formatted.length;
    }
    if (newCursorPos < 0) {
      newCursorPos = 0;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}

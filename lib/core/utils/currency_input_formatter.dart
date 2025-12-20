import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  String _groupThousands(String digits) {
    if (digits.isEmpty) return '';
    final rev = digits.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(rev[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Replace dot with comma if user enters it for decimals
    String newText = newValue.text.replaceAll('.', ',');

    // Keep only digits and comma.
    newText = newText.replaceAll(RegExp(r'[^0-9,]'), '');

    // Check for multiple commas
    if (newText.indexOf(',') != newText.lastIndexOf(',')) {
      return oldValue;
    }

    // Split integer and decimal parts
    final parts = newText.split(',');
    var integerDigits = parts[0];
    
    // Remove leading zeros from integer part
    if (integerDigits.length > 1 && integerDigits.startsWith('0')) {
      integerDigits = int.parse(integerDigits).toString();
    }
    
    // Format integer part
    final integerFormatted = _groupThousands(integerDigits);

    // Initial formatted text
    var formattedText = integerFormatted;

    // Handle decimal part
    if (parts.length > 1 || newText.endsWith(',')) {
      formattedText += ',';
      if (parts.length > 1) {
        var decimalDigits = parts[1];
        // Limit to 3 decimal places as requested (e.g. 12.345,678)
        if (decimalDigits.length > 3) {
          decimalDigits = decimalDigits.substring(0, 3);
        }
        formattedText += decimalDigits;
      }
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue;

    // Remove leading zeros
    if (newText.length > 1 && newText.startsWith('0')) {
      newText = int.parse(newText).toString();
    }

    final rev = newText.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < rev.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(rev[i]);
    }
    
    final formattedText = buffer.toString().split('').reversed.join();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

import 'package:flutter/material.dart';

/// Ortak divider widget'ı - Uygulamada tutarlı görünüm için
/// height: 1, color: Colors.grey.shade400
/// Padding: EdgeInsets.fromLTRB(5, 10, 5, 0)
class CommonDivider extends StatelessWidget {
  const CommonDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 20, 5, 0),
      child: Divider(height: 1, color: Colors.grey.shade400),
    );
  }
}

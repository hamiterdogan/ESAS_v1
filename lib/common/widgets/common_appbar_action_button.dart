import 'package:flutter/material.dart';

/// Uygulamada yaygın kullanılan AppBar action button (Filtrele, Sırala vs.)
/// Tutarlı stil ve davranış sağlar
class CommonAppBarActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final double iconSize;
  final double fontSize;

  const CommonAppBarActionButton({
    super.key,
    required this.onTap,
    required this.label,
    this.icon = Icons.filter_alt_outlined,
    this.iconSize = 30,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: kToolbarHeight,
          width: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

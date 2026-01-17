import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// Araç talep formlarında kullanılan "Yer Ekle" butonu widget'ı.
///
/// Yiyecek İçecek İstek ekranındaki "İkram Ekle" butonu ile aynı tasarıma sahiptir.
class YerEkleButton extends StatelessWidget {
  const YerEkleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yer Ekle',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.normal,
                fontSize: 16,
              ),
            ),
            Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

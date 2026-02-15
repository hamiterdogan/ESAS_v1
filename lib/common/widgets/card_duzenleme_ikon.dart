import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class CardDuzenlemeIkon extends StatelessWidget {
  const CardDuzenlemeIkon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.keyboard_double_arrow_left,
        color: AppColors.primary,
        size: 18,
      ),
    );
  }
}

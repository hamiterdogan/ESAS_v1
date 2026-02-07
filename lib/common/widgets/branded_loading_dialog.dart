import 'package:flutter/material.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class BrandedLoadingDialog {
  static void show(BuildContext context) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.6),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textOnPrimary.withValues(alpha: 0.05),
              ),
              alignment: Alignment.center,
              child: const BrandedLoadingIndicator(size: 153),
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}

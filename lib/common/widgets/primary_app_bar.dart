import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/theme/app_typography.dart';

class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const PrimaryAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTypography.headlineMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
      ),
      leading: leading ??
          (Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textOnPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                )
              : null),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
      ),
      elevation: 0,
      centerTitle: false,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

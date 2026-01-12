import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// Standart gradient AppBar widget'ı
/// Tüm ekranlarda tutarlı AppBar görünümü sağlar
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;
  final double? titleSpacing;
  final bool centerTitle;

  const GradientAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.leading,
    this.titleSpacing,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textOnPrimary),
      ),
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      ),
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textOnPrimary,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                )
              : null),
      automaticallyImplyLeading: showBackButton && leading == null,
      actions: actions,
      elevation: 0,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Seçim tetikleyici tile widget'ı.
///
/// Dropdown benzeri seçim alanları için kullanılır.
/// Sağ tarafta chevron ikonu gösterir.
class SelectionTriggerTile extends StatelessWidget {
  const SelectionTriggerTile({
    super.key,
    required this.text,
    required this.onTap,
    this.hintText,
    this.prefixIcon,
    this.isLoading = false,
    this.enabled = true,
    this.hasValue = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
  });

  final String text;
  final VoidCallback onTap;
  final String? hintText;
  final IconData? prefixIcon;
  final bool isLoading;
  final bool enabled;
  final bool hasValue;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final displayText = text.isEmpty ? (hintText ?? 'Seçiniz') : text;
    final hasContent = text.isNotEmpty || hasValue;

    return InkWell(
      onTap: enabled && !isLoading ? onTap : null,
      borderRadius: AppRadius.inputRadius,
      child: Container(
        padding:
            padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg + 2,
            ),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          border: Border.all(color: borderColor ?? AppColors.border),
          borderRadius: AppRadius.inputRadius,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(
                prefixIcon,
                color: hasContent ? AppColors.primary : AppColors.iconSecondary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: hasContent
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: hasContent ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconSecondary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// Basit add/location buton stili tile.
class AddItemTile extends StatelessWidget {
  const AddItemTile({
    super.key,
    required this.text,
    required this.onTap,
    this.icon = Icons.add,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.inputRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.inputRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(width: AppSpacing.lg),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

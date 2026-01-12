import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Arama text field widget'ı.
///
/// Bottom sheet'lerde ve listeli ekranlarda kullanılır.
/// Clear butonu ve tutarlı stil sağlar.
class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Ara...',
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final String hintText;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.iconSecondary,
        ),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.iconSecondary,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(
            color: AppColors.borderFocused,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        isDense: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Standart uygulama dropdown field widget'ı.
///
/// Tüm dropdown form field'ları için bu widget kullanılmalıdır.
/// Otomatik olarak tutarlı stil ve davranış sağlar.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.labelWidget,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
    this.fillColor,
    this.borderRadius,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final void Function(T?)? onChanged;
  final String? label;
  final Widget? labelWidget;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final bool isRequired;
  final bool enabled;
  final String? Function(T?)? validator;
  final Color? fillColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (label != null || labelWidget != null) ...[
          labelWidget ??
              Row(
                children: [
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelColor,
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Dropdown
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? AppColors.iconSecondary : AppColors.textDisabled,
          ),
          style: TextStyle(
            fontSize: 15,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor:
                fillColor ??
                (enabled ? AppColors.surface : AppColors.scaffoldBackground),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            border: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(
                color: AppColors.borderFocused,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(color: AppColors.borderError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(
                color: AppColors.borderError,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? AppRadius.inputRadius,
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ],
    );
  }
}

/// Basit string listesi için dropdown field.
class AppSimpleDropdown extends StatelessWidget {
  const AppSimpleDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.enabled = true,
    this.validator,
  });

  final List<String> items;
  final String? value;
  final void Function(String?)? onChanged;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final bool enabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<String>(
      value: value,
      onChanged: onChanged,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
    );
  }
}

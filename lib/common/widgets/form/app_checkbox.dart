import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Standart uygulama checkbox widget'ı.
///
/// Tek checkbox veya labelli checkbox için kullanılır.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelWidget,
    this.subtitle,
    this.enabled = true,
    this.tristate = false,
  });

  final bool? value;
  final void Function(bool?)? onChanged;
  final String? label;
  final Widget? labelWidget;
  final String? subtitle;
  final bool enabled;
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    if (label == null && labelWidget == null) {
      return Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        tristate: tristate,
        activeColor: AppColors.primary,
        checkColor: AppColors.surface,
        side: BorderSide(
          color: enabled ? AppColors.border : AppColors.borderLight,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.checkboxRadius),
      );
    }

    return InkWell(
      onTap: enabled
          ? () {
              if (tristate) {
                onChanged?.call(value == null ? true : (value! ? false : null));
              } else {
                onChanged?.call(!(value ?? false));
              }
            }
          : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                tristate: tristate,
                activeColor: AppColors.primary,
                checkColor: AppColors.surface,
                side: BorderSide(
                  color: enabled ? AppColors.border : AppColors.borderLight,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.checkboxRadius,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelWidget ??
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch/toggle widget.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelWidget,
    this.subtitle,
    this.enabled = true,
  });

  final bool value;
  final void Function(bool)? onChanged;
  final String? label;
  final Widget? labelWidget;
  final String? subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (label == null && labelWidget == null) {
      return Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: AppColors.iconSecondary,
        inactiveTrackColor: AppColors.borderLight,
      );
    }

    return InkWell(
      onTap: enabled ? () => onChanged?.call(!value) : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  labelWidget ??
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                      ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: AppColors.iconSecondary,
              inactiveTrackColor: AppColors.borderLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio button listesi için widget.
class AppRadioGroup<T> extends StatelessWidget {
  const AppRadioGroup({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.isRequired = false,
    this.enabled = true,
    this.direction = Axis.vertical,
  });

  final List<RadioItem<T>> items;
  final T? value;
  final void Function(T?)? onChanged;
  final String? label;
  final bool isRequired;
  final bool enabled;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
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
          const SizedBox(height: AppSpacing.sm),
        ],
        direction == Axis.vertical
            ? Column(
                children: items.map((item) => _buildRadioItem(item)).toList(),
              )
            : Wrap(
                spacing: AppSpacing.lg,
                children: items.map((item) => _buildRadioItem(item)).toList(),
              ),
      ],
    );
  }

  Widget _buildRadioItem(RadioItem<T> item) {
    final isSelected = value == item.value;

    return InkWell(
      onTap: enabled ? () => onChanged?.call(item.value) : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisSize: direction == Axis.horizontal
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            Radio<T>(
              value: item.value,
              // ignore: deprecated_member_use
              groupValue: value,
              // ignore: deprecated_member_use
              onChanged: enabled ? onChanged : null,
              fillColor: WidgetStateProperty.all(AppColors.primary),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                color: enabled
                    ? (isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)
                    : AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio item modeli.
class RadioItem<T> {
  const RadioItem({required this.value, required this.label});

  final T value;
  final String label;
}

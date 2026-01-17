import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class CustomSwitchWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final double spacing;
  final bool compact;

  const CustomSwitchWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.spacing = 8,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: const TextStyle(fontSize: 14, color: AppColors.inputLabelColor),
    );

    final fittedLabel = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: labelText,
    );

    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.gradientStart.withValues(alpha: 0.5),
          activeThumbColor: AppColors.gradientEnd,
          inactiveTrackColor: AppColors.textOnPrimary,
        ),
        SizedBox(width: spacing),
        if (compact) fittedLabel else Expanded(child: fittedLabel),
      ],
    );
  }
}

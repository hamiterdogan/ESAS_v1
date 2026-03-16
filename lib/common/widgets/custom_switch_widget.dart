import 'package:flutter/material.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class CustomSwitchWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final double spacing;
  final bool compact;
  final EdgeInsets padding;

  const CustomSwitchWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.spacing = 8,
    this.compact = false,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      maxLines: 2,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 14, color: AppColors.inputLabelColor),
    );

    return Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          padding: padding,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.gradientStart.withValues(alpha: 0.5),
            activeThumbColor: AppColors.gradientEnd,
            inactiveTrackColor: AppColors.textOnPrimary,
          ),
        ),
        SizedBox(width: spacing),
        if (compact) labelText else Expanded(child: labelText),
      ],
    );
  }
}

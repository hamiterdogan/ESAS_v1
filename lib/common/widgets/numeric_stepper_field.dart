import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';

/// Sayısal stepper widget'ı.
///
/// Artı/eksi butonları ve text input ile sayı girişi sağlar.
class NumericStepperField extends StatelessWidget {
  const NumericStepperField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelWidget,
    this.infoIcon,
    this.onInfoTap,
    this.minValue = 1,
    this.maxValue = 9999,
    this.step = 1,
    this.width = 64,
    this.height = 46,
    this.buttonWidth = 50,
    this.enabled = true,
    this.showLabel = true,
  });

  final int value;
  final void Function(int) onChanged;
  final String? label;
  final Widget? labelWidget;
  final IconData? infoIcon;
  final VoidCallback? onInfoTap;
  final int minValue;
  final int maxValue;
  final int step;
  final double width;
  final double height;
  final double buttonWidth;
  final bool enabled;
  final bool showLabel;

  void _updateValue(int newValue) {
    if (newValue < minValue || newValue > maxValue) return;
    onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (showLabel && (label != null || labelWidget != null)) ...[
          Row(
            children: [
              labelWidget ??
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.labelColor,
                    ),
                  ),
              if (infoIcon != null && onInfoTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: onInfoTap,
                  child: Icon(infoIcon, color: AppColors.primary, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Stepper
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minus button
            _StepperButton(
              icon: Icons.remove,
              onTap: value > minValue && enabled
                  ? () {
                      FocusScope.of(context).unfocus();
                      _updateValue(value - step);
                    }
                  : null,
              isEnabled: value > minValue && enabled,
              isLeft: true,
              height: height,
              width: buttonWidth,
            ),
            const SizedBox(width: AppSpacing.lg),

            // Value input
            _ValueInput(
              value: value,
              onChanged: _updateValue,
              minValue: minValue,
              maxValue: maxValue,
              width: width,
              height: height,
              enabled: enabled,
            ),
            const SizedBox(width: AppSpacing.lg),

            // Plus button
            _StepperButton(
              icon: Icons.add,
              onTap: value < maxValue && enabled
                  ? () {
                      FocusScope.of(context).unfocus();
                      _updateValue(value + step);
                    }
                  : null,
              isEnabled: value < maxValue && enabled,
              isLeft: false,
              height: height,
              width: buttonWidth,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
    required this.isLeft,
    required this.height,
    required this.width,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLeft;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.only(
            topLeft: isLeft ? const Radius.circular(AppRadius.md) : Radius.zero,
            bottomLeft: isLeft
                ? const Radius.circular(AppRadius.md)
                : Radius.zero,
            topRight: isLeft
                ? Radius.zero
                : const Radius.circular(AppRadius.md),
            bottomRight: isLeft
                ? Radius.zero
                : const Radius.circular(AppRadius.md),
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.textPrimary : AppColors.textDisabled,
          size: 24,
        ),
      ),
    );
  }
}

class _ValueInput extends StatefulWidget {
  const _ValueInput({
    required this.value,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    required this.width,
    required this.height,
    required this.enabled,
  });

  final int value;
  final void Function(int) onChanged;
  final int minValue;
  final int maxValue;
  final double width;
  final double height;
  final bool enabled;

  @override
  State<_ValueInput> createState() => _ValueInputState();
}

class _ValueInputState extends State<_ValueInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_ValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.maxValue.toString().length),
        ],
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 8),
        ),
        onChanged: (text) {
          if (text.isEmpty) return;
          final intValue = int.tryParse(text);
          if (intValue == null) return;
          if (intValue < widget.minValue) {
            widget.onChanged(widget.minValue);
          } else if (intValue > widget.maxValue) {
            widget.onChanged(widget.maxValue);
          } else {
            widget.onChanged(intValue);
          }
        },
      ),
    );
  }
}

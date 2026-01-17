import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class NumericSpinnerWidget extends ConsumerStatefulWidget {
  final Function(int) onValueChanged;
  final int initialValue;
  final int minValue;
  final int maxValue;
  final String label;
  final Widget? labelSuffix;
  final bool compact;

  const NumericSpinnerWidget({
    super.key,
    required this.onValueChanged,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue = 99,
    this.label = 'Girilmeyen Toplam Ders Saati',
    this.labelSuffix,
    this.compact = false,
  });

  @override
  ConsumerState<NumericSpinnerWidget> createState() =>
      _NumericSpinnerWidgetState();
}

class _NumericSpinnerWidgetState extends ConsumerState<NumericSpinnerWidget> {
  late int _value;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    if (newValue >= widget.minValue && newValue <= widget.maxValue) {
      setState(() {
        _value = newValue;
        _controller.text = _value.toString();
        widget.onValueChanged(_value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = widget.compact ? 40 : 50;
    final double inputWidth = widget.compact ? 56 : 80;
    final double fieldHeight = widget.compact ? 40 : 46;
    final double rowGap = widget.compact ? 6 : 12;
    final double valueFontSize = widget.compact ? 16 : 18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
                color: AppColors.primaryDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
            if (widget.labelSuffix != null) ...[
              const SizedBox(width: 8),
              widget.labelSuffix!,
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minus Button
            GestureDetector(
              onTap: _value > widget.minValue
                  ? () {
                      FocusScope.of(context).unfocus();
                      _updateValue(_value - 1);
                    }
                  : null,
              child: Container(
                width: buttonSize,
                height: fieldHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  color: AppColors.textOnPrimary,
                ),
                child: Icon(
                  Icons.remove,
                  color: _value > widget.minValue
                      ? AppColors.primaryDark
                      : AppColors.border,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: rowGap),
            // Value Input
            SizedBox(
              width: inputWidth,
              height: fieldHeight,
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: valueFontSize,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(1),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(1),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(1),
                    borderSide: const BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.textOnPrimary,
                ),
                onChanged: (value) {
                  if (value.isEmpty) return;
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    // maxValue'den fazla girilirse otomatik maxValue yap
                    if (intValue > widget.maxValue) {
                      setState(() {
                        _value = widget.maxValue;
                        _controller.text = widget.maxValue.toString();
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        widget.onValueChanged(_value);
                      });
                    } else if (intValue < widget.minValue) {
                      setState(() {
                        _value = widget.minValue;
                        _controller.text = widget.minValue.toString();
                        _controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: _controller.text.length),
                        );
                        widget.onValueChanged(_value);
                      });
                    } else {
                      _updateValue(intValue);
                    }
                  }
                },
              ),
            ),
            SizedBox(width: rowGap),
            // Plus Button
            GestureDetector(
              onTap: _value < widget.maxValue
                  ? () {
                      FocusScope.of(context).unfocus();
                      _updateValue(_value + 1);
                    }
                  : null,
              child: Container(
                width: buttonSize,
                height: fieldHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  color: AppColors.textOnPrimary,
                ),
                child: Icon(
                  Icons.add,
                  color: _value < widget.maxValue
                      ? AppColors.primaryDark
                      : AppColors.border,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

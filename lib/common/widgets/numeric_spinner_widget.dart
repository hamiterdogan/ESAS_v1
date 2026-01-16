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

  const NumericSpinnerWidget({
    super.key,
    required this.onValueChanged,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue = 99,
    this.label = 'Girilmeyen Toplam Ders Saati',
    this.labelSuffix,
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
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
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
                  width: 50,
                  height: 46,
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
                        ? AppColors.textPrimary
                        : AppColors.border,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Value Input
              SizedBox(
                width: 80,
                height: 46,
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
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
              const SizedBox(width: 12),
              // Plus Button
              GestureDetector(
                onTap: _value < widget.maxValue
                    ? () {
                        FocusScope.of(context).unfocus();
                        _updateValue(_value + 1);
                      }
                    : null,
                child: Container(
                  width: 50,
                  height: 46,
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
                        ? AppColors.textPrimary
                        : AppColors.border,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class AciklamaFieldWidget extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final int minLines;
  final int maxLines;
  final int minCharacters;
  final FocusNode? focusNode;
  final String labelText;
  final String hintText;

  const AciklamaFieldWidget({
    super.key,
    required this.controller,
    this.validator,
    this.minLines = 4,
    this.maxLines = 10,
    this.minCharacters = 15,
    this.focusNode,
    this.labelText = 'Açıklama',
    this.hintText = 'Lütfen detaylı bir açıklama giriniz.',
  });

  @override
  ConsumerState<AciklamaFieldWidget> createState() =>
      _AciklamaFieldWidgetState();
}

class _AciklamaFieldWidgetState extends ConsumerState<AciklamaFieldWidget> {
  late int _characterCount;

  @override
  void initState() {
    super.initState();
    _characterCount = widget.controller.text.length;
    widget.controller.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {
      _characterCount = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMinCharactersMet = _characterCount >= widget.minCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize:
                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: widget.focusNode,
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderStandartColor, width: 0.75),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderStandartColor, width: 0.75),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gradientStart, width: 0.75),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          minLines: widget.minLines,
          maxLines: widget.maxLines,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Karakter sayısı: $_characterCount',
              style: TextStyle(
                fontSize: 14,
                color: isMinCharactersMet
                    ? AppColors.textTertiary
                    : AppColors.error,
              ),
            ),
            Text(
              'Minimum: ${widget.minCharacters}',
              style: TextStyle(
                fontSize: 14,
                color: isMinCharactersMet ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateCharacterCount);
    super.dispose();
  }
}

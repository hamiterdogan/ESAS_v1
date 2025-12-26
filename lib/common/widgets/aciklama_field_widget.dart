import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          focusNode: widget.focusNode,
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isMinCharactersMet
                    ? Colors.grey.shade300
                    : const Color(0xFFB57070),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isMinCharactersMet
                    ? Colors.grey.shade300
                    : const Color(0xFFB57070),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isMinCharactersMet
                    ? const Color(0xFF014B92)
                    : const Color(0xFFB57070),
              ),
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
                    ? Colors.grey
                    : const Color(0xFFB57070),
              ),
            ),
            Text(
              'Minimum: ${widget.minCharacters}',
              style: TextStyle(
                fontSize: 14,
                color: isMinCharactersMet
                    ? Colors.green
                    : const Color(0xFFB57070),
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

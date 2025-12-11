import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

class OnayToggleWidget extends ConsumerStatefulWidget {
  final Function(bool) onChanged;
  final bool initialValue;
  final String label;

  const OnayToggleWidget({
    super.key,
    required this.onChanged,
    this.initialValue = false,
    this.label = 'Okudum, anladım, onaylıyorum',
  });

  @override
  ConsumerState<OnayToggleWidget> createState() => _OnayToggleWidgetState();
}

class _OnayToggleWidgetState extends ConsumerState<OnayToggleWidget> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(
          value: _value,
          onChanged: (value) {
            setState(() {
              _value = value;
            });
            widget.onChanged(value);
          },
          activeTrackColor: AppColors.gradientStart.withValues(alpha: 0.5),
          activeColor: AppColors.gradientEnd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(widget.label, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/common/widgets/custom_switch_widget.dart';

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
    return CustomSwitchWidget(
      value: _value,
      label: widget.label,
      onChanged: (value) {
        FocusScope.of(context).unfocus();
        setState(() {
          _value = value;
        });
        widget.onChanged(value);
      },
    );
  }
}

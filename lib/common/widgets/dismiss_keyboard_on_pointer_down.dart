import 'package:flutter/material.dart';

/// Dismisses keyboard focus without competing with tap gestures.
class DismissKeyboardOnPointerDown extends StatelessWidget {
  const DismissKeyboardOnPointerDown({
    super.key,
    required this.child,
    this.behavior = HitTestBehavior.translucent,
  });

  final Widget child;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behavior,
      onPointerDown: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: child,
    );
  }
}
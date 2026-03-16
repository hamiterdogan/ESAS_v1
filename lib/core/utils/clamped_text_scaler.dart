import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Global font-scaling guard.
///
/// Clamps the system's [TextScaler] between [_minScale] and [_maxScale]
/// so the app remains stable even when the user sets extreme font sizes
/// in the device's accessibility settings.
///
/// Usage – drop into any `MaterialApp.builder`:
/// ```dart
/// MaterialApp(
///   builder: ClampedTextScaler.builder,
/// );
/// ```
class ClampedTextScaler {
  ClampedTextScaler._();

  /// Minimum allowed text scale factor.
  static const double _minScale = 0.9;

  /// Maximum allowed text scale factor.
  static const double _maxScale = 1.20;

  /// A [TransitionBuilder] that overrides [MediaQueryData.textScaler]
  /// with a clamped value.
  static Widget builder(BuildContext context, Widget? child) {
    final mediaQuery = MediaQuery.of(context);
    final systemScale = mediaQuery.textScaler.scale(1.0);
    final clampedScale = math.min(math.max(systemScale, _minScale), _maxScale);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.linear(clampedScale)),
      child: child ?? const SizedBox.shrink(),
    );
  }
}

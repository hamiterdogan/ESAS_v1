import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'time_range_picker_widget.dart';

/// Deprecated: Use TimeRangePickerWidget instead.
/// This widget is kept for backward compatibility.
class TimePickerSpinnerWidget extends ConsumerWidget {
  final int initialHour;
  final int initialMinute;
  final Function(int hour, int minute) onTimeChanged;

  const TimePickerSpinnerWidget({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TimeRangePickerWidget(
      initialHour: initialHour,
      initialMinute: initialMinute,
      minHour: 8,
      maxHour: 18,
      allowedMinutes: const [0, 30],
      onTimeChanged: onTimeChanged,
    );
  }
}

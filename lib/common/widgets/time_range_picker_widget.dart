import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// A configurable time range picker widget for selecting hours and minutes
/// with customizable hour and minute ranges.
class TimeRangePickerWidget extends ConsumerStatefulWidget {
  final int initialHour;
  final int initialMinute;
  final int minHour;
  final int maxHour;
  final int minMinute;
  final List<int> allowedMinutes;
  final Function(int hour, int minute) onTimeChanged;
  final double width;
  final double height;
  final double itemExtent;

  const TimeRangePickerWidget({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    this.minHour = 0,
    this.maxHour = 23,
    this.minMinute = 0,
    this.allowedMinutes = const [0, 15, 30, 45],
    required this.onTimeChanged,
    this.width = 200,
    this.height = 55,
    this.itemExtent = 22,
  });

  @override
  ConsumerState<TimeRangePickerWidget> createState() =>
      _TimeRangePickerWidgetState();
}

class _TimeRangePickerWidgetState extends ConsumerState<TimeRangePickerWidget> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour.clamp(widget.minHour, widget.maxHour);
    _selectedMinute = widget.allowedMinutes.contains(widget.initialMinute)
        ? widget.initialMinute
        : widget.allowedMinutes[0];

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour - widget.minHour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: widget.allowedMinutes.indexOf(_selectedMinute),
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  List<int> _getAvailableMinutes() {
    // If current hour is minHour, filter out minutes that are less than minMinute
    if (_selectedHour == widget.minHour) {
      return widget.allowedMinutes
          .where((minute) => minute >= widget.minMinute)
          .toList();
    }
    return widget.allowedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.textOnPrimary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hour Spinner
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: widget.itemExtent,
                physics: const FixedExtentScrollPhysics(),
                controller: _hourController,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedHour = widget.minHour + index;
                  });
                  widget.onTimeChanged(_selectedHour, _selectedMinute);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final hour = widget.minHour + index;
                    final isSelected = hour == _selectedHour;
                    return Center(
                      child: Text(
                        hour.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: isSelected ? 16 : 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  },
                  childCount: widget.maxHour - widget.minHour + 1,
                ),
              ),
            ),

            // Colon separator
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Minute Spinner
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: widget.itemExtent,
                physics: const FixedExtentScrollPhysics(),
                controller: _minuteController,
                onSelectedItemChanged: (index) {
                  setState(() {
                    final filteredMinutes = _getAvailableMinutes();
                    _selectedMinute = filteredMinutes[index];
                  });
                  widget.onTimeChanged(_selectedHour, _selectedMinute);
                },
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) {
                    final filteredMinutes = _getAvailableMinutes();
                    final minute = filteredMinutes[index];
                    final isSelected = minute == _selectedMinute;
                    return Center(
                      child: Text(
                        minute.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: isSelected ? 16 : 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  },
                  childCount: _getAvailableMinutes().length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

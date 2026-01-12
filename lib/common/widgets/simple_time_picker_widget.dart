import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// A simple time picker widget with fixed width and height
/// Displays hour and minute selection with top/bottom borders only
class SimpleTimePickerWidget extends ConsumerStatefulWidget {
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
  final String? label;

  const SimpleTimePickerWidget({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    this.minHour = 0,
    this.maxHour = 23,
    this.minMinute = 0,
    this.allowedMinutes = const [0, 15, 30, 45],
    required this.onTimeChanged,
    this.width = 320,
    this.height = 80,
    this.itemExtent = 21,
    this.label,
  });

  @override
  ConsumerState<SimpleTimePickerWidget> createState() =>
      _SimpleTimePickerWidgetState();
}

class _SimpleTimePickerWidgetState
    extends ConsumerState<SimpleTimePickerWidget> {
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
    if (_selectedHour == widget.minHour) {
      return widget.allowedMinutes
          .where((minute) => minute >= widget.minMinute)
          .toList();
    }
    return widget.allowedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        SizedBox(
          width: widget.width,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Selection Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                              fontSize: isSelected ? 17 : 9,
                              fontWeight: isSelected
                                  ? FontWeight.w500
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
              ),

              // Colon Separator
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Minute Selection Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary,
                    border: Border(
                      top: BorderSide(color: AppColors.border, width: 1),
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                              fontSize: isSelected ? 17 : 9,
                              fontWeight: isSelected
                                  ? FontWeight.w500
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// YEDEK: Tam kenarlı kutucuklu versiyon - gerekirse bu versiyona dönülebilir
/// Original boxed time picker widget with full borders and rounded corners
class SimpleTimePickerWidgetFullBorder extends ConsumerStatefulWidget {
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
  final String? label;

  const SimpleTimePickerWidgetFullBorder({
    super.key,
    this.initialHour = 0,
    this.initialMinute = 0,
    this.minHour = 0,
    this.maxHour = 23,
    this.minMinute = 0,
    this.allowedMinutes = const [0, 15, 30, 45],
    required this.onTimeChanged,
    this.width = 320,
    this.height = 80,
    this.itemExtent = 21,
    this.label,
  });

  @override
  ConsumerState<SimpleTimePickerWidgetFullBorder> createState() =>
      _SimpleTimePickerWidgetFullBorderState();
}

class _SimpleTimePickerWidgetFullBorderState
    extends ConsumerState<SimpleTimePickerWidgetFullBorder> {
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
    if (_selectedHour == widget.minHour) {
      return widget.allowedMinutes
          .where((minute) => minute >= widget.minMinute)
          .toList();
    }
    return widget.allowedMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        SizedBox(
          width: widget.width,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hour Selection Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textDisabled, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardBackground,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                              fontSize: isSelected ? 17 : 9,
                              fontWeight: isSelected
                                  ? FontWeight.w500
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
              ),

              // Colon Separator
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // Minute Selection Box
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textDisabled, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardBackground,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                              fontSize: isSelected ? 17 : 9,
                              fontWeight: isSelected
                                  ? FontWeight.w500
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A date picker widget that displays selected date as text
/// and opens a bottom sheet with separate day, month, year spinners.
/// Sundays are disabled and cannot be selected.
class DatePickerBottomSheetWidget extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final Function(DateTime date) onDateChanged;
  final String? label;
  final String? placeholder;

  const DatePickerBottomSheetWidget({
    super.key,
    this.initialDate,
    this.minDate,
    this.maxDate,
    required this.onDateChanged,
    this.label,
    this.placeholder,
  });

  @override
  ConsumerState<DatePickerBottomSheetWidget> createState() =>
      _DatePickerBottomSheetWidgetState();
}

class _DatePickerBottomSheetWidgetState
    extends ConsumerState<DatePickerBottomSheetWidget> {
  DateTime? _selectedDate;
  late DateTime _minDate;
  late DateTime _maxDate;

  @override
  void initState() {
    super.initState();
    _minDate = widget.minDate ?? DateTime.now();
    _maxDate = widget.maxDate ?? DateTime(2026, 8, 1);
    _selectedDate = widget.initialDate;
  }

  @override
  void didUpdateWidget(DatePickerBottomSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool minChanged = oldWidget.minDate != widget.minDate;
    final bool maxChanged = oldWidget.maxDate != widget.maxDate;
    final bool initialChanged = oldWidget.initialDate != widget.initialDate;

    if (minChanged || maxChanged || initialChanged) {
      setState(() {
        _minDate = widget.minDate ?? DateTime.now();
        _maxDate = widget.maxDate ?? DateTime(2026, 8, 1);

        _selectedDate = widget.initialDate ?? _selectedDate;

        // Clamp selected date into new bounds
        if (_selectedDate != null) {
          if (_selectedDate!.isBefore(_minDate)) {
            _selectedDate = _minDate;
          }
          if (_selectedDate!.isAfter(_maxDate)) {
            _selectedDate = _maxDate;
          }

          // Skip Sundays if clamping landed on Sunday
          while (_selectedDate!.weekday == DateTime.sunday) {
            final candidate = _selectedDate!.add(const Duration(days: 1));
            if (candidate.isAfter(_maxDate)) {
              break;
            }
            _selectedDate = candidate;
          }
        }
      });
    }
  }

  String _formatDate() {
    if (_selectedDate == null) {
      return widget.placeholder ?? 'gg.aa.yyyy';
    }
    return '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }

  String _getDayName(int year, int month, int day) {
    const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final weekday = DateTime(year, month, day).weekday;
    return dayNames[weekday - 1];
  }

  /// Get available years between min and max date
  List<int> _getAvailableYears() {
    final List<int> years = [];
    for (int year = _minDate.year; year <= _maxDate.year; year++) {
      years.add(year);
    }
    return years;
  }

  /// Get available months for a given year
  List<int> _getAvailableMonths(int year) {
    int startMonth = 1;
    int endMonth = 12;

    if (year == _minDate.year) {
      startMonth = _minDate.month;
    }
    if (year == _maxDate.year) {
      endMonth = _maxDate.month;
    }

    final List<int> months = [];
    for (int month = startMonth; month <= endMonth; month++) {
      months.add(month);
    }
    return months;
  }

  /// Get all days for a given year and month (including Sundays)
  List<int> _getAvailableDays(int year, int month) {
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    int startDay = 1;
    int endDay = daysInMonth;

    if (year == _minDate.year && month == _minDate.month) {
      startDay = _minDate.day;
    }
    if (year == _maxDate.year && month == _maxDate.month) {
      endDay = _maxDate.day;
    }

    final List<int> days = [];
    for (int day = startDay; day <= endDay; day++) {
      days.add(day);
    }
    return days;
  }

  /// Check if a given date is Sunday
  bool _isSunday(int year, int month, int day) {
    return DateTime(year, month, day).weekday == DateTime.sunday;
  }

  /// Get first non-Sunday day from the list
  int _getFirstSelectableDay(List<int> days, int year, int month) {
    for (int day in days) {
      if (!_isSunday(year, month, day)) {
        return day;
      }
    }
    return days.first;
  }

  void _showDatePickerBottomSheet() {
    // Initialize with selected date or first available
    int tempYear = _selectedDate?.year ?? _minDate.year;
    int tempMonth = _selectedDate?.month ?? _minDate.month;
    int tempDay = _selectedDate?.day ?? _minDate.day;

    // Ensure values are within bounds
    final years = _getAvailableYears();
    if (!years.contains(tempYear)) {
      tempYear = years.first;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final months = _getAvailableMonths(tempYear);
            if (!months.contains(tempMonth)) {
              tempMonth = months.first;
            }

            final days = _getAvailableDays(tempYear, tempMonth);
            if (!days.contains(tempDay) ||
                _isSunday(tempYear, tempMonth, tempDay)) {
              tempDay = _getFirstSelectableDay(days, tempYear, tempMonth);
            }

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    widget.label ?? 'Tarih Seçin',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Date Picker Spinners (Day - Month - Year - Day Name)
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 16),
                        // Day Spinner
                        SizedBox(
                          width: 45,
                          child: _DaySpinner(
                            key: ValueKey('day-$tempYear-$tempMonth'),
                            days: days,
                            year: tempYear,
                            month: tempMonth,
                            initialDay: tempDay,
                            onDayChanged: (day) {
                              setModalState(() {
                                tempDay = day;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Month Spinner
                        SizedBox(
                          width: 110,
                          child: _DateSpinner(
                            key: ValueKey('month-$tempYear'),
                            itemCount: months.length,
                            initialItem: months.indexOf(tempMonth) >= 0
                                ? months.indexOf(tempMonth)
                                : 0,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempMonth = months[index];
                                // Recalculate days for new month
                                final newDays = _getAvailableDays(
                                  tempYear,
                                  tempMonth,
                                );
                                if (!newDays.contains(tempDay) ||
                                    _isSunday(tempYear, tempMonth, tempDay)) {
                                  tempDay = _getFirstSelectableDay(
                                    newDays,
                                    tempYear,
                                    tempMonth,
                                  );
                                }
                              });
                            },
                            itemBuilder: (index) =>
                                _getMonthName(months[index]),
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Year Spinner
                        SizedBox(
                          width: 65,
                          child: _DateSpinner(
                            itemCount: years.length,
                            initialItem: years.indexOf(tempYear) >= 0
                                ? years.indexOf(tempYear)
                                : 0,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempYear = years[index];
                                // Recalculate months and days for new year
                                final newMonths = _getAvailableMonths(tempYear);
                                if (!newMonths.contains(tempMonth)) {
                                  tempMonth = newMonths.first;
                                }
                                final newDays = _getAvailableDays(
                                  tempYear,
                                  tempMonth,
                                );
                                if (!newDays.contains(tempDay) ||
                                    _isSunday(tempYear, tempMonth, tempDay)) {
                                  tempDay = _getFirstSelectableDay(
                                    newDays,
                                    tempYear,
                                    tempMonth,
                                  );
                                }
                              });
                            },
                            itemBuilder: (index) => years[index].toString(),
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Day Name Display
                        SizedBox(
                          width: 45,
                          height: 40,
                          child: Center(
                            child: Text(
                              _getDayName(tempYear, tempMonth, tempDay),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedDate = DateTime(
                          tempYear,
                          tempMonth,
                          tempDay,
                        );
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                        widget.onDateChanged(_selectedDate!);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014B92),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        );
      },
    );
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        GestureDetector(
          onTap: _showDatePickerBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.calendar_today, size: 24, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDate(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Scroll pozisyonunu dinleyen date spinner widget'ı
class _DateSpinner extends StatefulWidget {
  final int itemCount;
  final int initialItem;
  final Function(int) onSelectedItemChanged;
  final String Function(int) itemBuilder;
  final double fontSize;

  const _DateSpinner({
    super.key,
    required this.itemCount,
    required this.initialItem,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
    required this.fontSize,
  });

  @override
  State<_DateSpinner> createState() => _DateSpinnerState();
}

class _DateSpinnerState extends State<_DateSpinner> {
  late FixedExtentScrollController _scrollController;
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialItem.toDouble();
    _scrollController = FixedExtentScrollController(
      initialItem: widget.initialItem,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() {
        _currentPosition = _scrollController.offset / 48;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 48,
        diameterRatio: 1.5,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        controller: _scrollController,
        onSelectedItemChanged: widget.onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final distance = (index - _currentPosition).abs();
            final normalizedDistance = distance.clamp(0.0, 1.5) / 1.5;

            return _DateFadeSpinnerItem(
              text: widget.itemBuilder(index),
              normalizedDistance: normalizedDistance,
              baseFontSize: widget.fontSize,
            );
          },
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}

/// Fade efektli date spinner item widget'ı
class _DateFadeSpinnerItem extends StatelessWidget {
  final String text;
  final double normalizedDistance;
  final double baseFontSize;

  const _DateFadeSpinnerItem({
    required this.text,
    required this.normalizedDistance,
    this.baseFontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = _lerpDouble(
      baseFontSize,
      baseFontSize * 0.636,
      normalizedDistance,
    );
    final scale = _lerpDouble(1.0, 0.75, normalizedDistance);
    final opacity = _lerpDouble(1.0, 0.4, normalizedDistance);
    final color = Color.lerp(
      Colors.black,
      Colors.grey[600],
      normalizedDistance,
    )!;
    final fontWeight = normalizedDistance < 0.3
        ? FontWeight.bold
        : FontWeight.w500;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Day Spinner that shows Sundays but makes them non-selectable and faded
class _DaySpinner extends StatefulWidget {
  final List<int> days;
  final int year;
  final int month;
  final int initialDay;
  final Function(int) onDayChanged;

  const _DaySpinner({
    super.key,
    required this.days,
    required this.year,
    required this.month,
    required this.initialDay,
    required this.onDayChanged,
  });

  @override
  State<_DaySpinner> createState() => _DaySpinnerState();
}

class _DaySpinnerState extends State<_DaySpinner> {
  late FixedExtentScrollController _scrollController;
  double _currentPosition = 0;
  int _lastValidDay = 0;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.days.indexOf(widget.initialDay);
    _lastValidDay = widget.initialDay;
    _currentPosition = initialIndex >= 0 ? initialIndex.toDouble() : 0;
    _scrollController = FixedExtentScrollController(
      initialItem: initialIndex >= 0 ? initialIndex : 0,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      setState(() {
        _currentPosition = _scrollController.offset / 48;
      });
    }
  }

  bool _isSunday(int day) {
    return DateTime(widget.year, widget.month, day).weekday == DateTime.sunday;
  }

  void _handleItemChanged(int index) {
    final day = widget.days[index];
    if (_isSunday(day)) {
      // Skip to next or previous non-Sunday
      int targetIndex = index;

      // Try to go to the direction of scroll
      if (index > widget.days.indexOf(_lastValidDay)) {
        // Scrolling down, find next non-Sunday
        for (int i = index + 1; i < widget.days.length; i++) {
          if (!_isSunday(widget.days[i])) {
            targetIndex = i;
            break;
          }
        }
        // If no non-Sunday found after, go back
        if (targetIndex == index) {
          for (int i = index - 1; i >= 0; i--) {
            if (!_isSunday(widget.days[i])) {
              targetIndex = i;
              break;
            }
          }
        }
      } else {
        // Scrolling up, find previous non-Sunday
        for (int i = index - 1; i >= 0; i--) {
          if (!_isSunday(widget.days[i])) {
            targetIndex = i;
            break;
          }
        }
        // If no non-Sunday found before, go forward
        if (targetIndex == index) {
          for (int i = index + 1; i < widget.days.length; i++) {
            if (!_isSunday(widget.days[i])) {
              targetIndex = i;
              break;
            }
          }
        }
      }

      // Animate to the valid day
      Future.delayed(const Duration(milliseconds: 50), () {
        if (_scrollController.hasClients) {
          _scrollController.animateToItem(
            targetIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _lastValidDay = day;
      widget.onDayChanged(day);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListWheelScrollView.useDelegate(
        itemExtent: 48,
        diameterRatio: 1.5,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        controller: _scrollController,
        onSelectedItemChanged: _handleItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final day = widget.days[index];
            final isSunday = _isSunday(day);
            final distance = (index - _currentPosition).abs();
            final normalizedDistance = distance.clamp(0.0, 1.5) / 1.5;

            return _DayFadeSpinnerItem(
              text: day.toString().padLeft(2, '0'),
              normalizedDistance: normalizedDistance,
              isSunday: isSunday,
            );
          },
          childCount: widget.days.length,
        ),
      ),
    );
  }
}

/// Fade efektli day spinner item widget'ı (Pazar günleri için özel stil)
class _DayFadeSpinnerItem extends StatelessWidget {
  final String text;
  final double normalizedDistance;
  final bool isSunday;

  const _DayFadeSpinnerItem({
    required this.text,
    required this.normalizedDistance,
    required this.isSunday,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = _lerpDouble(22, 14, normalizedDistance);
    final scale = _lerpDouble(1.0, 0.75, normalizedDistance);
    final opacity = _lerpDouble(1.0, 0.4, normalizedDistance);
    final color = Color.lerp(
      Colors.black,
      Colors.grey[600],
      normalizedDistance,
    )!;
    final fontWeight = normalizedDistance < 0.3
        ? FontWeight.bold
        : FontWeight.w500;

    // Pazar günleri aynı formatta ama üstü çizili
    if (isSunday) {
      return Center(
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
                decoration: TextDecoration.lineThrough,
                decorationColor: color,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

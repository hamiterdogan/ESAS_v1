import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// A time picker widget that displays selected time as text
/// and opens a bottom sheet with spinner for time selection when tapped.
class TimePickerBottomSheetWidget extends ConsumerStatefulWidget {
  final int initialHour;
  final int initialMinute;
  final int minHour;
  final int maxHour;
  final int minMinute;
  final int minGapMinutes;
  final List<int> allowedMinutes;
  final Function(int hour, int minute) onTimeChanged;
  final String? label;
  final bool allowAllMinutesAtMaxHour;
  final TextStyle? labelStyle;

  const TimePickerBottomSheetWidget({
    super.key,
    this.initialHour = 8,
    this.initialMinute = 0,
    this.minHour = 8,
    this.maxHour = 18,
    this.minMinute = 0,
    this.minGapMinutes = 0,
    this.allowedMinutes = const [0, 30],
    required this.onTimeChanged,
    this.label,
    this.allowAllMinutesAtMaxHour = false,
    this.labelStyle,
  });

  @override
  ConsumerState<TimePickerBottomSheetWidget> createState() =>
      _TimePickerBottomSheetWidgetState();
}

class _TimePickerBottomSheetWidgetState
    extends ConsumerState<TimePickerBottomSheetWidget> {
  late int _selectedHour;
  late int _selectedMinute;

  List<int> _sortedAllowedMinutes() {
    if (widget.allowedMinutes.isEmpty) {
      return const [0];
    }
    final minutes = List<int>.from(widget.allowedMinutes)..sort();
    return minutes;
  }

  (int, int) _effectiveMinTime() {
    if (widget.minGapMinutes <= 0) {
      return (widget.minHour, widget.minMinute);
    }

    final allowed = _sortedAllowedMinutes();
    final baseTotal = widget.minHour * 60 + widget.minMinute;
    final targetTotal = baseTotal + widget.minGapMinutes;
    int hour = targetTotal ~/ 60;
    int minute = targetTotal % 60;

    int? nextMinute;
    for (final m in allowed) {
      if (m >= minute) {
        nextMinute = m;
        break;
      }
    }

    if (nextMinute == null) {
      hour += 1;
      minute = allowed.first;
    } else {
      minute = nextMinute;
    }

    if (hour > widget.maxHour) {
      hour = widget.maxHour;
      minute = allowed.last;
    }

    return (hour, minute);
  }

  int _normalizeMinute(int hour, int minute) {
    final minutes = _getAvailableMinutes(hour);
    if (minutes.contains(minute)) {
      return minute;
    }
    return minutes.first;
  }

  @override
  void initState() {
    super.initState();
    final minTime = _effectiveMinTime();
    _selectedHour = widget.initialHour.clamp(minTime.$1, widget.maxHour);
    _selectedMinute = _normalizeMinute(_selectedHour, widget.initialMinute);

    // Widget oluşturulduğunda gösterilen değeri parent'a bildir
    // Bu sayede ekranda gösterilen değer ile state her zaman senkron olur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedHour != widget.initialHour ||
          _selectedMinute != widget.initialMinute) {
        widget.onTimeChanged(_selectedHour, _selectedMinute);
      }
    });
  }

  @override
  void didUpdateWidget(TimePickerBottomSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Her zaman yeni değerleri uygula
    setState(() {
      final minTime = _effectiveMinTime();
      _selectedHour = widget.initialHour.clamp(minTime.$1, widget.maxHour);
      _selectedMinute = _normalizeMinute(_selectedHour, widget.initialMinute);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedHour != widget.initialHour ||
          _selectedMinute != widget.initialMinute) {
        widget.onTimeChanged(_selectedHour, _selectedMinute);
      }
    });
  }

  String _formatTime() {
    return '${_selectedHour.toString().padLeft(2, '0')} : ${_selectedMinute.toString().padLeft(2, '0')}';
  }

  void _showTimePickerBottomSheet() async {
    // 🔴 KRİTİK: BottomSheet açmadan önce tüm focus'ları kapat
    FocusScope.of(context).unfocus();

    int tempHour = _selectedHour;
    int tempMinute = _normalizeMinute(tempHour, _selectedMinute);
    final minTime = _effectiveMinTime();
    final minHour = minTime.$1;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    widget.label ?? 'Saat Seçin',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Time Picker Spinner
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hour Spinner
                        SizedBox(
                          width: 80,
                          child: _buildSpinner(
                            itemCount: widget.maxHour - minHour + 1,
                            initialItem: tempHour - minHour,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempHour = minHour + index;
                                tempMinute = _normalizeMinute(
                                  tempHour,
                                  tempMinute,
                                );
                              });
                            },
                            itemBuilder: (index) {
                              final hour = minHour + index;
                              return hour.toString().padLeft(2, '0');
                            },
                            selectedIndex: tempHour - minHour,
                          ),
                        ),
                        // Colon
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Minute Spinner
                        SizedBox(
                          width: 80,
                          child: _buildSpinner(
                            itemCount: _getAvailableMinutes(tempHour).length,
                            initialItem:
                                _getAvailableMinutes(
                                  tempHour,
                                ).contains(tempMinute)
                                ? _getAvailableMinutes(
                                    tempHour,
                                  ).indexOf(tempMinute)
                                : 0,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                final minutes = _getAvailableMinutes(tempHour);
                                if (index < minutes.length) {
                                  tempMinute = minutes[index];
                                }
                              });
                            },
                            itemBuilder: (index) {
                              final minutes = _getAvailableMinutes(tempHour);
                              if (index < minutes.length) {
                                return minutes[index].toString().padLeft(
                                  2,
                                  '0',
                                );
                              }
                              return '00';
                            },
                            selectedIndex:
                                _getAvailableMinutes(
                                  tempHour,
                                ).contains(tempMinute)
                                ? _getAvailableMinutes(
                                    tempHour,
                                  ).indexOf(tempMinute)
                                : 0,
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
                        setState(() {
                          _selectedHour = tempHour;
                          _selectedMinute = tempMinute;
                        });
                        widget.onTimeChanged(_selectedHour, _selectedMinute);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                          color: AppColors.textOnPrimary,
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

    // 🔒 BottomSheet kapandıktan sonra garanti için tekrar unfocus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  List<int> _getAvailableMinutes(int hour) {
    final minTime = _effectiveMinTime();
    final minHour = minTime.$1;
    final minMinute = minTime.$2;

    // maxHour'da sadece 00 dakikası göster (allowAllMinutesAtMaxHour true değilse)
    if (hour == widget.maxHour && !widget.allowAllMinutesAtMaxHour) {
      return [0];
    }
    if (hour == minHour && minMinute > 0) {
      // When same hour as effective min time, only show minutes >= minMinute
      final filtered = widget.allowedMinutes
          .where((minute) => minute >= minMinute)
          .toList();
      // Eğer filtrelenmiş liste boşsa, en azından son dakikayı göster
      if (filtered.isEmpty) {
        return [widget.allowedMinutes.last];
      }
      return filtered;
    }
    return widget.allowedMinutes;
  }

  Widget _buildSpinner({
    required int itemCount,
    required int initialItem,
    required Function(int) onSelectedItemChanged,
    required String Function(int) itemBuilder,
    required int selectedIndex,
  }) {
    return _ScrollAwareSpinner(
      itemCount: itemCount,
      initialItem: initialItem,
      onSelectedItemChanged: onSelectedItemChanged,
      itemBuilder: itemBuilder,
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
              style:
                  (widget.labelStyle ??
                          const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ))
                      .copyWith(color: AppColors.primaryDark),
            ),
          ),
        GestureDetector(
          onTap: _showTimePickerBottomSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.access_time, size: 24, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Text(
                  _formatTime(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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

/// Scroll pozisyonunu dinleyen spinner widget'ı
class _ScrollAwareSpinner extends StatefulWidget {
  final int itemCount;
  final int initialItem;
  final Function(int) onSelectedItemChanged;
  final String Function(int) itemBuilder;

  const _ScrollAwareSpinner({
    required this.itemCount,
    required this.initialItem,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
  });

  @override
  State<_ScrollAwareSpinner> createState() => _ScrollAwareSpinnerState();
}

class _ScrollAwareSpinnerState extends State<_ScrollAwareSpinner> {
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
        // Scroll offset'i item pozisyonuna çevir
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
          top: BorderSide(color: AppColors.border, width: 1),
          bottom: BorderSide(color: AppColors.border, width: 1),
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
            // Merkeze olan uzaklığı hesapla (0 = merkezde, 1 = bir item uzaklıkta)
            final distance = (index - _currentPosition).abs();
            // 0-1 arası normalize edilmiş değer (0 = seçili, 1 = uzak)
            final normalizedDistance = distance.clamp(0.0, 1.5) / 1.5;

            return _FadeSpinnerItem(
              text: widget.itemBuilder(index),
              normalizedDistance: normalizedDistance,
            );
          },
          childCount: widget.itemCount,
        ),
      ),
    );
  }
}

/// Fade efektli spinner item widget'ı
class _FadeSpinnerItem extends StatelessWidget {
  final String text;
  final double normalizedDistance; // 0 = seçili (merkezde), 1 = en uzak

  const _FadeSpinnerItem({
    required this.text,
    required this.normalizedDistance,
  });

  @override
  Widget build(BuildContext context) {
    // Boyut: Merkezde büyük, uzaklaştıkça küçülür
    final fontSize = lerpDouble(28, 18, normalizedDistance)!;
    final scale = lerpDouble(1.0, 0.75, normalizedDistance)!;

    // Opacity: Merkezde tam görünür, uzaklaştıkça soluklaşır
    final opacity = lerpDouble(1.0, 0.4, normalizedDistance)!;

    // Renk: Merkezde siyah, uzaklaştıkça koyu gri
    final color = Color.lerp(
      AppColors.textPrimary,
      AppColors.textSecondary,
      normalizedDistance,
    )!;

    // Font ağırlığı
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

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

/// A duration picker widget that displays selected duration as text
/// and opens a bottom sheet with spinner for day and hour selection when tapped.
class DurationPickerBottomSheetWidget extends ConsumerStatefulWidget {
  final int initialDay;
  final int initialHour;
  final int minDay;
  final int maxDay;
  final int minHour;
  final int maxHour;
  final Function(int day, int hour) onDurationChanged;
  final String? label;
  final TextStyle? labelStyle;

  const DurationPickerBottomSheetWidget({
    super.key,
    this.initialDay = 0,
    this.initialHour = 1,
    this.minDay = 0,
    this.maxDay = 999,
    this.minHour = 1,
    this.maxHour = 24,
    required this.onDurationChanged,
    this.label,
    this.labelStyle,
  });

  @override
  ConsumerState<DurationPickerBottomSheetWidget> createState() =>
      _DurationPickerBottomSheetWidgetState();
}

class _DurationPickerBottomSheetWidgetState
    extends ConsumerState<DurationPickerBottomSheetWidget> {
  late int _selectedDay;
  late int _selectedHour;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay.clamp(widget.minDay, widget.maxDay);
    _selectedHour = widget.initialHour.clamp(widget.minHour, widget.maxHour);

    // Widget oluşturulduğunda gösterilen değeri parent'a bildir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedDay != widget.initialDay ||
          _selectedHour != widget.initialHour) {
        widget.onDurationChanged(_selectedDay, _selectedHour);
      }
    });
  }

  @override
  void didUpdateWidget(DurationPickerBottomSheetWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _selectedDay = widget.initialDay.clamp(widget.minDay, widget.maxDay);
      _selectedHour = widget.initialHour.clamp(widget.minHour, widget.maxHour);
    });
  }

  String _formatDuration() {
    return '${_selectedDay.toString().padLeft(2, '0')} Gün ${_selectedHour.toString().padLeft(2, '0')} Saat';
  }

  Future<void> _showDurationPickerBottomSheet() async {
    int tempDay = _selectedDay;
    int tempHour = _selectedHour;

    final pageFocusScope = FocusScope.of(context);
    pageFocusScope.canRequestFocus = false;
    pageFocusScope.unfocus();
    await Future.delayed(Duration.zero);

    if (!mounted) return;

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
                    widget.label ?? 'Süre Seçin',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Duration Picker Spinner
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day Spinner
                        SizedBox(
                          width: 80,
                          child: _buildSpinner(
                            itemCount: widget.maxDay - widget.minDay + 1,
                            initialItem: tempDay - widget.minDay,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempDay = widget.minDay + index;
                              });
                            },
                            itemBuilder: (index) {
                              final day = widget.minDay + index;
                              return day.toString().padLeft(2, '0');
                            },
                          ),
                        ),
                        // Label
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Gün',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Hour Spinner
                        SizedBox(
                          width: 80,
                          child: _buildSpinner(
                            itemCount: widget.maxHour - widget.minHour + 1,
                            initialItem: tempHour - widget.minHour,
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempHour = widget.minHour + index;
                              });
                            },
                            itemBuilder: (index) {
                              final hour = widget.minHour + index;
                              return hour.toString().padLeft(2, '0');
                            },
                          ),
                        ),
                        // Label
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Saat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
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
                        setState(() {
                          _selectedDay = tempDay;
                          _selectedHour = tempHour;
                        });
                        widget.onDurationChanged(_selectedDay, _selectedHour);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = FocusScope.of(context);
      scope.unfocus();
      scope.canRequestFocus = true;
    });
  }

  Widget _buildSpinner({
    required int itemCount,
    required int initialItem,
    required Function(int) onSelectedItemChanged,
    required String Function(int) itemBuilder,
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
                  widget.labelStyle ??
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        GestureDetector(
          onTapDown: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          onTap: () async {
            await _showDurationPickerBottomSheet();
          },
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
                Icon(Icons.schedule, size: 24, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(),
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

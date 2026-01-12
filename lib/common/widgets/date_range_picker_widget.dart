import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:intl/intl.dart';

class DateRangePickerWidget extends ConsumerStatefulWidget {
  final Function(DateTime?, DateTime?) onDatesChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool hideEndDate;
  final String? startDateLabel;
  final String? endDateLabel;

  const DateRangePickerWidget({
    super.key,
    required this.onDatesChanged,
    this.initialStartDate,
    this.initialEndDate,
    this.hideEndDate = false,
    this.startDateLabel,
    this.endDateLabel,
  });

  @override
  ConsumerState<DateRangePickerWidget> createState() =>
      _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends ConsumerState<DateRangePickerWidget> {
  late DateTime? _baslangicTarihi;
  late DateTime? _bitisTarihi;

  @override
  void initState() {
    super.initState();
    _baslangicTarihi = widget.initialStartDate;
    _bitisTarihi = widget.initialEndDate;
  }

  void _selectDate(BuildContext context, bool isBaslangic) async {
    final DateTime? picked = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026, 12, 31),
      dateFormat: "dd.MM.yyyy",
      locale: DateTimePickerLocale.tr,
    );

    if (picked != null) {
      setState(() {
        if (isBaslangic) {
          _baslangicTarihi = picked;
        } else {
          _bitisTarihi = picked;
        }
      });
      widget.onDatesChanged(_baslangicTarihi, _bitisTarihi);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideEndDate) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.startDateLabel != null &&
                  widget.startDateLabel!.isNotEmpty)
                Text(
                  widget.startDateLabel!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              if (widget.startDateLabel != null &&
                  widget.startDateLabel!.isNotEmpty)
                const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.textOnPrimary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _baslangicTarihi == null
                            ? 'gg.aa.yyyy'
                            : _formatDate(_baslangicTarihi),
                        style: TextStyle(
                          color: _baslangicTarihi == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // İki widget modu - esnek boyut
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.startDateLabel ?? 'Başlangıç Tarihi',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.textOnPrimary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _baslangicTarihi == null
                              ? 'gg.aa.yyyy'
                              : _formatDate(_baslangicTarihi),
                          style: TextStyle(
                            color: _baslangicTarihi == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.endDateLabel ?? 'Bitiş Tarihi',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.textOnPrimary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _bitisTarihi == null
                              ? 'gg.aa.yyyy'
                              : _formatDate(_bitisTarihi),
                          style: TextStyle(
                            color: _bitisTarihi == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ],
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
}

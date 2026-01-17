import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart';
import 'package:esas_v1/common/widgets/generic_summary_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/core/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart';
import 'package:esas_v1/core/models/result.dart'; // Ensure Result import

class A4KagidiIstekScreen extends ConsumerStatefulWidget {
  const A4KagidiIstekScreen({super.key});

  @override
  ConsumerState<A4KagidiIstekScreen> createState() =>
      _A4KagidiIstekScreenState();
}

class _A4KagidiIstekScreenState extends ConsumerState<A4KagidiIstekScreen> {
  late DateTime _initialTeslimTarihi;
  late DateTime _teslimTarihi;
  int _paketAdedi = 1;
  late final TextEditingController _aciklamaController;

  @override
  void initState() {
    super.initState();
    _initialTeslimTarihi = DateTime.now().add(const Duration(days: 2));
    _teslimTarihi = _initialTeslimTarihi;
    _aciklamaController = TextEditingController();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    super.dispose();
  }

  bool _hasFormData() {
    if (_paketAdedi != 1) return true;
    if (!_isSameDate(_teslimTarihi, _initialTeslimTarihi)) return true;
    if (_aciklamaController.text.trim().isNotEmpty) return true;
    return false;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return AppDialogs.showFormExitConfirm(context);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    // Açıklama validation
    if (_aciklamaController.text.length < 30) {
      _showStatusBottomSheet(
        'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
        isError: true,
      );
      return;
    }

    final requestData = {
      'teslimTarihi': _teslimTarihi.toIso8601String(),
      'paketAdedi': _paketAdedi,
      'aciklama': _aciklamaController.text,
    };

    final summaryItems = [
      GenericSummaryItem(
        label: 'Teslim Tarihi',
        value:
            '${_teslimTarihi.day.toString().padLeft(2, '0')}.${_teslimTarihi.month.toString().padLeft(2, '0')}.${_teslimTarihi.year}',
        multiLine: false,
      ),
      GenericSummaryItem(
        label: 'Paket Adedi',
        value: '$_paketAdedi Paket',
        multiLine: false,
      ),
      GenericSummaryItem(
        label: 'Açıklama',
        value: _aciklamaController.text.isEmpty
            ? '-'
            : _aciklamaController.text,
        multiLine: true,
      ),
    ];

    showGenericSummaryBottomSheet(
      context: context,
      requestData: requestData,
      title: 'A4 Kağıdı İstek',
      summaryItems: summaryItems,
      showRequestData: false,
      onConfirm: () async {
        // API Call
        final repo = ref.read(dokumantasyonIstekRepositoryProvider);
        final result = await repo.dokumantasyonIstekEkle(
          paket: _paketAdedi,
          aciklama: _aciklamaController.text,
          teslimTarihi: _teslimTarihi,
          isA4Talebi: true,
          formFile:
              null, // A4 request usually has no file, but API might require param presence
        );

        if (result is Failure) {
          throw Exception(result.message);
        }
      },
      onSuccess: () {
        ref.invalidate(dokumantasyonDevamEdenTaleplerProvider);
        _showStatusBottomSheet('A4 kağıdı isteği başarıyla gönderildi');
      },
      onError: (error) {
        _showStatusBottomSheet(error, isError: true);
      },
    );
  }

  void _showDateInfo() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 40, color: AppColors.gradientEnd),
            const SizedBox(height: 16),
            const Text(
              'Teslim Edilecek Tarih',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'En erken 2 iş günü sonrasını seçebilirsiniz.',
              style: TextStyle(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientEnd,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tamam',
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        if (_hasFormData()) {
          final shouldPop = await _showExitConfirmationDialog();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        } else {
          if (context.mounted) {
            context.pop();
          }
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            title: const Text(
              'A4 Kağıdı İstek',
              style: TextStyle(color: AppColors.textOnPrimary),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textOnPrimary,
              ),
              onPressed: () async {
                if (_hasFormData()) {
                  final shouldPop = await _showExitConfirmationDialog();
                  if (shouldPop && context.mounted) {
                    context.pop();
                  }
                } else {
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
            elevation: 0,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Gönder',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Teslim edilecek tarih',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.fontSize ??
                                  14) +
                              1,
                          color: AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showDateInfo,
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          // Label is handled externally for alignment purposes
                          label: null,
                          initialDate: _teslimTarihi,
                          minDate: DateTime.now().add(const Duration(days: 2)),
                          maxDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          onDateChanged: (date) {
                            setState(() {
                              _teslimTarihi = date;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  NumericSpinnerWidget(
                    initialValue: _paketAdedi,
                    minValue: 1,
                    maxValue: 9999,
                    label: 'Paket Adedi',
                    onValueChanged: (value) {
                      setState(() {
                        _paketAdedi = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  AciklamaFieldWidget(controller: _aciklamaController),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext statusContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: AppColors.textOnPrimary,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 64,
                color: isError ? AppColors.error : AppColors.success,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(statusContext);
                  if (!isError) {
                    context.go('/dokumantasyon_istek');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientEnd,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tamam',
                  style: TextStyle(color: AppColors.textOnPrimary),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }
}

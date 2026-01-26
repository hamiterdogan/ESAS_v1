import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/time_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/personel_selector_widget.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class EgitimSonrasiPaylasimsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool shouldFocusInput;
  final String? initialValidationErrorType;

  const EgitimSonrasiPaylasimsScreen({
    super.key,
    this.initialData,
    this.shouldFocusInput = false,
    this.initialValidationErrorType,
  });

  @override
  ConsumerState<EgitimSonrasiPaylasimsScreen> createState() =>
      _EgitimSonrasiPaylasimsScreenState();
}

class _EgitimSonrasiPaylasimsScreenState
    extends ConsumerState<EgitimSonrasiPaylasimsScreen> {
  static const List<int> _allowedMinutes = [
    0,
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    50,
    55,
  ];
  late DateTime _baslangicTarihi;
  late DateTime _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  final TextEditingController _egitimYeriController = TextEditingController();
  final FocusNode _egitimYeriFocusNode = FocusNode();
  final Set<int> _selectedPersonelIds = {};
  final Set<int> _selectedGorevYeriIds = {};
  final Set<int> _selectedGorevIds = {};
  // ignore: unused_field - may be used in future
  List<PersonelItem> _personeller = [];
  // ignore: unused_field - may be used in future
  List<GorevItem> _gorevler = [];
  // ignore: unused_field - may be used in future
  List<GorevYeriItem> _gorevYerleri = [];

  void _syncBitisWithBaslangic({
    required int startHour,
    required int startMinute,
  }) {
    final minBitis = _computeBitisMin(startHour, startMinute);
    if (_isBefore(_bitisSaat, _bitisDakika, minBitis.$1, minBitis.$2)) {
      _bitisSaat = minBitis.$1;
      _bitisDakika = minBitis.$2;
    }
  }

  (int, int) _computeBitisMin(int startHour, int startMinute) {
    if (startMinute >= _allowedMinutes.last) {
      if (startHour >= 17) {
        return (17, _allowedMinutes.last);
      }
      final nextHour = (startHour + 1).clamp(0, 17);
      return (nextHour, _allowedMinutes.first);
    }

    final nextMinute = _allowedMinutes.firstWhere(
      (m) => m > startMinute,
      orElse: () => _allowedMinutes.last,
    );
    return (startHour, nextMinute);
  }

  bool _isBefore(int h1, int m1, int h2, int m2) {
    return h1 < h2 || (h1 == h2 && m1 < m2);
  }

  @override
  void initState() {
    super.initState();
    _baslangicTarihi = DateTime.now();
    _bitisTarihi = DateTime.now().add(const Duration(days: 7));
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future(() async {
        if (!mounted) return;

        if (widget.initialValidationErrorType != null) {
          await _showValidationError(
            errorType: widget.initialValidationErrorType!,
          );
        }

        // Eğer shouldFocusInput true ise inputa focus ayarla
        if (widget.shouldFocusInput && mounted) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            FocusScope.of(context).requestFocus(_egitimYeriFocusNode);
          }
        }
      });
    });
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['baslangicTarihi'] != null) {
        _baslangicTarihi = data['baslangicTarihi'] as DateTime;
      }
      if (data['bitisTarihi'] != null) {
        _bitisTarihi = data['bitisTarihi'] as DateTime;
      }
      _baslangicSaat = data['baslangicSaat'] ?? 8;
      _baslangicDakika = data['baslangicDakika'] ?? 0;
      _bitisSaat = data['bitisSaat'] ?? 17;
      _bitisDakika = data['bitisDakika'] ?? 30;
      _egitimYeriController.text = data['egitimYeri'] ?? '';
      if (data['selectedPersonelIds'] != null) {
        final ids = data['selectedPersonelIds'] as List<int>;
        _selectedPersonelIds.clear();
        _selectedPersonelIds.addAll(ids);
      }
      if (data['selectedGorevYeriIds'] != null) {
        final gorevYeriIds = data['selectedGorevYeriIds'] as List<int>;
        _selectedGorevYeriIds.clear();
        _selectedGorevYeriIds.addAll(gorevYeriIds);
      }
      if (data['selectedGorevIds'] != null) {
        final gorevIds = data['selectedGorevIds'] as List<int>;
        _selectedGorevIds.clear();
        _selectedGorevIds.addAll(gorevIds);
      }
    }
  }

  @override
  void dispose() {
    _egitimYeriController.dispose();
    _egitimYeriFocusNode.dispose();
    super.dispose();
  }

  bool _validateForm() {
    // Eğitimin yapılacağı yer kontrol et
    if (_egitimYeriController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  bool _validatePersonelSelection() {
    // En az 1 personel seçilmiş olması kontrol et
    if (_selectedPersonelIds.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _showValidationError({String errorType = 'location'}) async {
    String errorMessage = '';

    if (errorType == 'location') {
      errorMessage = 'Lütfen eğitimin yapılacağı yeri belirtiniz';
    } else if (errorType == 'personel') {
      errorMessage =
          'Lütfen eğitimi paylaşacağınız kişiler veya departmanı belirtiniz';
    }

    // 🔒 1. FocusNode'u disabled et
    _egitimYeriFocusNode.canRequestFocus = false;

    // 🔒 2. Tüm focus'u temizle
    FocusScope.of(context).unfocus();

    // 🔒 3. 1 frame bekle
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // 🔒 4. BottomSheet aç
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Uyarı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
              const SizedBox(height: 60),
            ],
          ),
        );
      },
    );

    // 🔓 5. Sheet kapandıktan sonra focus izni geri ver ve ekstra unfocus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        _egitimYeriFocusNode.canRequestFocus = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Pop işlemi zaten gerçekleşti, ek işlem yapılmasına gerek yok
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textOnPrimary,
                    ),
                    onPressed: () {
                      final data = {
                        'baslangicTarihi': _baslangicTarihi,
                        'bitisTarihi': _bitisTarihi,
                        'baslangicSaat': _baslangicSaat,
                        'baslangicDakika': _baslangicDakika,
                        'bitisSaat': _bitisSaat,
                        'bitisDakika': _bitisDakika,
                        'egitimYeri': _egitimYeriController.text,
                        'selectedPersonelIds': _selectedPersonelIds.toList(),
                        'selectedGorevYeriIds': _selectedGorevYeriIds.toList(),
                        'selectedGorevIds': _selectedGorevIds.toList(),
                      };
                      Navigator.pop(context, data);
                    },
                  ),
                  const Text(
                    'Eğitim Sonrası Kurum İçi Paylaşım',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Başlangıç Tarihi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.fontSize ??
                                                  14) +
                                              1,
                                          color: AppColors.inputLabelColor,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  DatePickerBottomSheetWidget(
                                    label: null,
                                    initialDate: _baslangicTarihi,
                                    minDate: DateTime.now(),
                                    maxDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    onDateChanged: (date) {
                                      setState(() => _baslangicTarihi = date);
                                    },
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
                                    'Bitiş Tarihi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.fontSize ??
                                                  14) +
                                              1,
                                          color: AppColors.inputLabelColor,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  DatePickerBottomSheetWidget(
                                    label: null,
                                    initialDate: _bitisTarihi,
                                    minDate: _baslangicTarihi,
                                    maxDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                    onDateChanged: (date) {
                                      setState(() => _bitisTarihi = date);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TimePickerBottomSheetWidget(
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                      color: AppColors.inputLabelColor,
                                    ),
                                initialHour: _baslangicSaat,
                                initialMinute: _baslangicDakika,
                                minHour: 8,
                                maxHour: 17,
                                allowedMinutes: _allowedMinutes,
                                label: 'Başlangıç Saati',
                                allowAllMinutesAtMaxHour: true,
                                onTimeChanged: (hour, minute) {
                                  setState(() {
                                    _baslangicSaat = hour;
                                    _baslangicDakika = minute;
                                    _syncBitisWithBaslangic(
                                      startHour: hour,
                                      startMinute: minute,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final minBitis = _computeBitisMin(
                                    _baslangicSaat,
                                    _baslangicDakika,
                                  );
                                  return TimePickerBottomSheetWidget(
                                    key: ValueKey(
                                      'bitis-$_baslangicSaat-$_baslangicDakika-$_bitisSaat-$_bitisDakika',
                                    ),
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.fontSize ??
                                                  14) +
                                              1,
                                          color: AppColors.inputLabelColor,
                                        ),
                                    initialHour: _bitisSaat,
                                    initialMinute: _bitisDakika,
                                    minHour: minBitis.$1,
                                    minMinute: minBitis.$2,
                                    maxHour: 17,
                                    allowAllMinutesAtMaxHour: true,
                                    allowedMinutes: _allowedMinutes,
                                    label: 'Bitiş Saati',
                                    onTimeChanged: (hour, minute) {
                                      setState(() {
                                        _bitisSaat = hour;
                                        _bitisDakika = minute;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eğitimin Yapılacağı Yer',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.fontSize ??
                                            14) +
                                        1,
                                    color: AppColors.inputLabelColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _egitimYeriController,
                              focusNode: _egitimYeriFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Eğitimin yapılacağı yeri giriniz',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                                filled: true,
                                fillColor: AppColors.textOnPrimary,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.borderStandartColor,
                                    width: 0.75,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.borderStandartColor,
                                    width: 0.75,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Eğitimi paylaşacağınız kişileri veya departmanı belirtiniz.',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                                color: AppColors.inputLabelColor,
                              ),
                        ),
                        const SizedBox(height: 12),
                        PersonelSelectorWidget(
                          initialSelection: _selectedPersonelIds,
                          initialSelectedGorevYeriIds: _selectedGorevYeriIds,
                          initialSelectedGorevIds: _selectedGorevIds,
                          fetchFunction: () => ref
                              .read(aracTalepRepositoryProvider)
                              .personelSecimVerisiGetir(),
                          onSelectionChanged: (ids) {
                            setState(() {
                              _selectedPersonelIds.clear();
                              _selectedPersonelIds.addAll(ids);
                            });
                          },
                          onFilterChanged: (gorevYeriIds, gorevIds) {
                            setState(() {
                              _selectedGorevYeriIds.clear();
                              _selectedGorevYeriIds.addAll(gorevYeriIds);
                              _selectedGorevIds.clear();
                              _selectedGorevIds.addAll(gorevIds);
                            });
                          },
                          onDataLoaded: (data) {
                            setState(() {
                              _personeller = data.personeller;
                              _gorevler = data.gorevler;
                              _gorevYerleri = data.gorevYerleri;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Form validasyonlarını kontrol et
                        if (!_validateForm()) {
                          await _showValidationError(errorType: 'location');
                          return;
                        }

                        if (!_validatePersonelSelection()) {
                          await _showValidationError(errorType: 'personel');
                          return;
                        }

                        final data = {
                          'baslangicTarihi': _baslangicTarihi,
                          'bitisTarihi': _bitisTarihi,
                          'baslangicSaat': _baslangicSaat,
                          'baslangicDakika': _baslangicDakika,
                          'bitisSaat': _bitisSaat,
                          'bitisDakika': _bitisDakika,
                          'egitimYeri': _egitimYeriController.text,
                          'selectedPersonelIds': _selectedPersonelIds.toList(),
                          'selectedGorevYeriIds': _selectedGorevYeriIds
                              .toList(),
                          'selectedGorevIds': _selectedGorevIds.toList(),
                        };
                        Navigator.pop(context, data);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/time_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/duration_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/index.dart';

import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class EgitimTalepScreen extends ConsumerStatefulWidget {
  const EgitimTalepScreen({super.key});

  @override
  ConsumerState<EgitimTalepScreen> createState() => _EgitimTalepScreenState();
}

class _EgitimTalepScreenState extends ConsumerState<EgitimTalepScreen> {
  late DateTime _baslangicTarihi;
  late DateTime _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  int _egitimGun = 0;
  int _egitimSaat = 1;
  int _girileymeyenDersSaati = 0;
  bool _topluIstekte = false;

  final Set<int> _selectedPersonelIds = {};
  List<PersonelItem> _personeller = [];
  List<GorevItem> _gorevler = [];
  List<GorevYeriItem> _gorevYerleri = [];

  @override
  void initState() {
    super.initState();
    _baslangicTarihi = DateTime.now();
    _bitisTarihi = DateTime.now().add(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
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
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Eğitim Talebi',
                    style: TextStyle(
                      color: Colors.white,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başlangıç Tarihi',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.fontSize ??
                                            14) +
                                        1,
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
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.fontSize ??
                                            14) +
                                        1,
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
                          labelStyle: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                              ),
                          initialHour: _baslangicSaat,
                          initialMinute: _baslangicDakika,
                          minHour: 8,
                          maxHour: 17,
                          allowedMinutes: const [0, 30],
                          label: 'Başlangıç Saati',
                          onTimeChanged: (hour, minute) {
                            setState(() {
                              _baslangicSaat = hour;
                              _baslangicDakika = minute;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TimePickerBottomSheetWidget(
                          labelStyle: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                              ),
                          initialHour: _bitisSaat,
                          initialMinute: _bitisDakika,
                          minHour: _baslangicSaat,
                          minMinute: 0,
                          maxHour: 17,
                          allowAllMinutesAtMaxHour: true,
                          allowedMinutes: const [0, 30],
                          label: 'Bitiş Saati',
                          onTimeChanged: (hour, minute) {
                            setState(() {
                              _bitisSaat = hour;
                              _bitisDakika = minute;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Eğitimin Süresi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.fontSize ??
                                  14) +
                              1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            builder: (BuildContext sheetContext) {
                              return Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.gradientStart
                                            .withValues(alpha: 0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: AppColors.gradientStart,
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Eğitimin kaç gün süreceğini ve 1 günlük eğitim saatini giriniz.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF2D3748),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            60,
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(sheetContext);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.gradientEnd,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Tamam',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.info_outlined,
                          size: 20,
                          color: AppColors.gradientStart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DurationPickerBottomSheetWidget(
                    label: null,
                    initialDay: _egitimGun,
                    initialHour: _egitimSaat,
                    minDay: 0,
                    maxDay: 999,
                    minHour: 1,
                    maxHour: 24,
                    onDurationChanged: (day, hour) {
                      setState(() {
                        _egitimGun = day;
                        _egitimSaat = hour;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  DersSaatiSpinnerWidget(
                    initialValue: _girileymeyenDersSaati,
                    onValueChanged: (value) {
                      setState(() {
                        _girileymeyenDersSaati = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  OnayToggleWidget(
                    initialValue: _topluIstekte,
                    label: 'Toplu istekte bulunmak istiyorum',
                    onChanged: (value) {
                      setState(() {
                        _topluIstekte = value;
                        if (!value) {
                          _selectedPersonelIds.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_topluIstekte)
                    PersonelSelectorWidget(
                      initialSelection: _selectedPersonelIds,
                      fetchFunction: () => ref
                          .read(aracTalepRepositoryProvider)
                          .personelSecimVerisiGetir(),
                      onSelectionChanged: (ids) {
                        setState(() {
                          _selectedPersonelIds.clear();
                          _selectedPersonelIds.addAll(ids);
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
                  if (_topluIstekte) const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

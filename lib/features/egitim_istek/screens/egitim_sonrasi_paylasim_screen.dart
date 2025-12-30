import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/time_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/personel_selector_widget.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class EgitimSonrasiPaylasimsScreen extends ConsumerStatefulWidget {
  const EgitimSonrasiPaylasimsScreen({super.key});

  @override
  ConsumerState<EgitimSonrasiPaylasimsScreen> createState() =>
      _EgitimSonrasiPaylasimsScreenState();
}

class _EgitimSonrasiPaylasimsScreenState
    extends ConsumerState<EgitimSonrasiPaylasimsScreen> {
  late DateTime _baslangicTarihi;
  late DateTime _bitisTarihi;
  int _baslangicSaat = 8;
  int _baslangicDakika = 0;
  int _bitisSaat = 17;
  int _bitisDakika = 30;
  final TextEditingController _egitimYeriController = TextEditingController();
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
  void dispose() {
    _egitimYeriController.dispose();
    super.dispose();
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
                    'Eğitim Sonrası Kurum İçi Paylaşım',
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
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _egitimYeriController,
                              decoration: InputDecoration(
                                hintText: 'Eğitimin yapılacağı yeri giriniz',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
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
                              ),
                        ),
                        const SizedBox(height: 12),
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                          color: Colors.white,
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

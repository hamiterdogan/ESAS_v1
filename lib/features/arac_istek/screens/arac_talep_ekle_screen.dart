import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/constants/app_spacing.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/custom_switch_widget.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/common/widgets/common_divider.dart';
import 'package:esas_v1/common/widgets/ogrenci/ogrenci_filter_sheet_full.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_ekle_req.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/arac_istek/widgets/yer_ekle_button.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

class AracTalepEkleScreen extends ConsumerStatefulWidget {
  final int tuId;

  const AracTalepEkleScreen({super.key, required this.tuId});

  @override
  ConsumerState<AracTalepEkleScreen> createState() =>
      _AracTalepEkleScreenState();
}

class _AracTalepEkleScreenState extends ConsumerState<AracTalepEkleScreen> {
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
  final List<_YerEntry> _entries = [];
  late TextEditingController _mesafeController;
  late TextEditingController _customAracIstekNedeniController;
  late TextEditingController _aciklamaController;
  int _tahminiMesafe = 1;
  DateTime? _gidilecekTarih;
  int _gidisSaat = 8;
  int _gidisDakika = 0;
  int _donusSaat = 9;
  int _donusDakika = 0;
  // Araç istek nedeni seçimi için durum
  int? _selectedAracIstekNedeniId;
  // ignore: unused_field - used to store custom reason text
  String? _customAracIstekNedeni;
  List<AracIstekNedeniItem> _aracIstekNedenleri = [];
  // Yolcu (personel) seçimi için durum
  final Set<int> _selectedPersonelIds = {};
  List<PersonelItem> _personeller = [];
  List<GorevItem> _gorevler = [];
  List<GorevYeriItem> _gorevYerleri = [];

  String _currentFilterPage = '';
  // Öğrenci seçimi için durum
  final Set<String> _selectedOgrenciIds = {};
  final Set<String> _selectedOkulKodu = {};
  final Set<String> _selectedSeviye = {};
  final Set<String> _selectedSinif = {};
  final Set<String> _selectedKulup = {};
  final Set<String> _selectedTakim = {};
  List<String> _okulKoduList = [];
  List<String> _seviyeList = [];
  List<String> _sinifList = [];
  // Okul/Seviye/Sınıf listeleri ilk çağrıda gelen haliyle sabit kalsın.
  // Seçimler bu üç listenin içeriğini filtrelemesin.
  List<String> _initialOkulKoduList = [];
  List<String> _initialSeviyeList = [];
  List<String> _initialSinifList = [];
  List<FilterOgrenciItem> _initialOgrenciList = [];
  List<String> _kulupList = [];
  List<String> _takimList = [];
  List<FilterOgrenciItem> _ogrenciList = [];
  bool _ogrenciSheetLoading = false;
  // ignore: unused_field - used to track error state
  String? _ogrenciSheetError;
  bool _isMEB = false;

  late final int _initialTahminiMesafe;
  late final DateTime _initialGidilecekTarih;
  late final int _initialGidisSaat;
  late final int _initialGidisDakika;
  late final int _initialDonusSaat;
  late final int _initialDonusDakika;

  // Lock mechanism for multi-tap prevention
  bool _isActionInProgress = false;

  final FocusNode _customAracIstekNedeniFocusNode = FocusNode();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final FocusNode _gidilecekYerButtonFocusNode = FocusNode();
  final GlobalKey _gidilecekYerSectionKey = GlobalKey();
  late final ScrollController _scrollController;

  bool get _hasOgrenciBaseCache {
    return _initialOkulKoduList.isNotEmpty &&
        _initialSeviyeList.isNotEmpty &&
        _initialSinifList.isNotEmpty;
  }

  @override
  void dispose() {
    _mesafeController.dispose();
    _customAracIstekNedeniController.dispose();
    _aciklamaController.dispose();
    for (final entry in _entries) {
      entry.adresController.dispose();
      entry.focusNode.dispose();
    }
    _customAracIstekNedeniFocusNode.dispose();
    _aciklamaFocusNode.dispose();
    _gidilecekYerButtonFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mesafeController = TextEditingController(text: _tahminiMesafe.toString());
    _customAracIstekNedeniController = TextEditingController();
    _aciklamaController = TextEditingController();
    _gidilecekTarih = DateTime.now();
    _syncDonusWithGidis(startHour: _gidisSaat, startMinute: _gidisDakika);

    _initialTahminiMesafe = _tahminiMesafe;
    _initialGidilecekTarih = _gidilecekTarih!;
    _initialGidisSaat = _gidisSaat;
    _initialGidisDakika = _gidisDakika;
    _initialDonusSaat = _donusSaat;
    _initialDonusDakika = _donusDakika;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasFormData() {
    if (_entries.isNotEmpty) return true;
    if (_tahminiMesafe != _initialTahminiMesafe) return true;
    if (_gidilecekTarih != null &&
        !_isSameDate(_gidilecekTarih!, _initialGidilecekTarih)) {
      return true;
    }
    if (_gidisSaat != _initialGidisSaat ||
        _gidisDakika != _initialGidisDakika) {
      return true;
    }
    if (_donusSaat != _initialDonusSaat ||
        _donusDakika != _initialDonusDakika) {
      return true;
    }

    if (_selectedAracIstekNedeniId != null) return true;
    if (_customAracIstekNedeniController.text.trim().isNotEmpty) return true;
    if (_aciklamaController.text.trim().isNotEmpty) return true;
    if (_selectedPersonelIds.isNotEmpty) return true;
    if (_selectedOgrenciIds.isNotEmpty) return true;
    if (_selectedOkulKodu.isNotEmpty) return true;
    if (_selectedSeviye.isNotEmpty) return true;
    if (_selectedSinif.isNotEmpty) return true;
    if (_selectedKulup.isNotEmpty) return true;
    if (_selectedTakim.isNotEmpty) return true;

    return false;
  }

  Future<bool> _confirmExitIfNeeded() async {
    if (!_hasFormData()) return true;
    return AppDialogs.showFormExitConfirm(context);
  }

  Future<bool> _onWillPop() async {
    return _confirmExitIfNeeded();
  }

  /// Klavye odağını kilitle ve tüm inputların odağını kapat
  void _lockAndUnfocusInputs() {
    _customAracIstekNedeniFocusNode.canRequestFocus = false;
    _aciklamaFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();
  }

  /// Klavye odağını aç (BottomSheet kapandıktan sonra)
  void _unlockInputsAfterSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _customAracIstekNedeniFocusNode.canRequestFocus = true;
      _aciklamaFocusNode.canRequestFocus = true;
    });
  }

  void _syncDonusWithGidis({required int startHour, required int startMinute}) {
    int targetHour = startHour + 1;
    int targetMinute = startMinute;

    if (targetHour > 23) {
      targetHour = 23;
      targetMinute = _allowedMinutes.last;
    }

    final nextConstraint = _computeDonusMin(startHour, startMinute);

    if (_isBeforeOrEqual(targetHour, targetMinute, startHour, startMinute)) {
      targetHour = nextConstraint.$1;
      targetMinute = nextConstraint.$2;
    }

    if (_isBefore(
      targetHour,
      targetMinute,
      nextConstraint.$1,
      nextConstraint.$2,
    )) {
      targetHour = nextConstraint.$1;
      targetMinute = nextConstraint.$2;
    }

    _donusSaat = targetHour;
    _donusDakika = targetMinute;
  }

  (int, int) _computeDonusMin(int startHour, int startMinute) {
    if (startMinute >= _allowedMinutes.last) {
      if (startHour >= 23) {
        return (23, _allowedMinutes.last);
      }
      final nextHour = (startHour + 1).clamp(0, 23);
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

  bool _isBeforeOrEqual(int h1, int m1, int h2, int m2) {
    return h1 < h2 || (h1 == h2 && m1 <= m2);
  }

  void _updateMesafe(int value) {
    if (value < 1 || value > 9999) return;
    setState(() {
      _tahminiMesafe = value;
      _mesafeController.text = value.toString();
      _mesafeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _mesafeController.text.length),
      );
    });
  }

  void _showMesafeInfo() {
    _lockAndUnfocusInputs();
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    InfoBottomSheet.show(
      context,
      title: 'Tahmini Mesafe',
      message:
          'Gidilecek yere navigasyondan bakarak tahmini kaç kilometre mesafe olduğunu yazınız.',
    ).whenComplete(() {
      _unlockInputsAfterSheet();
      if (mounted) setState(() => _isActionInProgress = false);
    });
  }

  String _getAracTuruName() {
    final aracTurleriAsync = ref.watch(aracTurleriProvider);
    return aracTurleriAsync.when(
      data: (list) {
        try {
          final selected = list.firstWhere((item) => item.id == widget.tuId);
          return selected.tur;
        } catch (_) {
          return 'Araç Talebi';
        }
      },
      loading: () => 'Araç Talebi',
      error: (_, __) => 'Araç Talebi',
    );
  }

  String _getFormattedTitle(String aracTuru) {
    if (aracTuru == 'Yük') {
      return 'Yük Aracı İstek';
    } else if (aracTuru == 'Minibüs') {
      return 'Minibüs İstek';
    } else if (aracTuru == 'Otobüs') {
      return 'Otobüs İstek';
    }
    return '$aracTuru Araç İstek';
  }

  @override
  Widget build(BuildContext context) {
    final aracTuru = _getAracTuruName();

    // Eğer araç türü "Yük" ise, yük ekranına yönlendir
    if (aracTuru == 'Yük') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.replace('/arac/yuk/ekle/${widget.tuId}');
      });
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            _getFormattedTitle(aracTuru),
            style: const TextStyle(color: AppColors.textOnPrimary),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () async {
              if (await _confirmExitIfNeeded()) {
                if (context.mounted) context.pop();
              }
            },
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          ),
          elevation: 0,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Klavyeyi kapat
            FocusScope.of(context).unfocus();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(
                    key: _gidilecekYerSectionKey,
                    child: Text(
                      'Gidilecek Yer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            1,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_entries.isEmpty)
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Henüz yer eklenmedi.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      color: AppColors.surface,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _entries.length,
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.yer.yerAdi,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.textTertiary,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _entries[index].adresController
                                                  .dispose();
                                              _entries[index].focusNode
                                                  .dispose();
                                              _entries.removeAt(index);
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          iconSize: 22,
                                        ),
                                      ],
                                    ),
                                    if (!entry.yer.yerAdi.contains('Eyüboğlu'))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          bottom: 12,
                                        ),
                                        child: TextField(
                                          focusNode: entry.focusNode,
                                          controller: entry.adresController,
                                          decoration: InputDecoration(
                                            hintText: 'Semt ve adres giriniz',
                                            prefixIcon: const Icon(
                                              Icons.location_on_outlined,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AppColors
                                                    .borderStandartColor,
                                                width: 0.75,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: AppColors
                                                    .borderStandartColor,
                                                width: 0.75,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: AppColors.gradientStart,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const Divider(height: 16, thickness: 0.8),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Focus(
                    focusNode: _gidilecekYerButtonFocusNode,
                    child: YerEkleButton(onTap: _openYerSecimiBottomSheet),
                  ),
                  const CommonDivider(),
                  const SizedBox(height: 24),
                  NumericSpinnerWidget(
                    initialValue: _tahminiMesafe,
                    minValue: 1,
                    maxValue: 9999,
                    label: 'Tahmini Mesafe (km)',
                    labelSuffix: GestureDetector(
                      onTap: _showMesafeInfo,
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.gradientStart,
                        size: 20,
                      ),
                    ),
                    onValueChanged: (value) {
                      _updateMesafe(value);
                    },
                  ),
                  const SizedBox(height: 24),
                  // MEB Toggle
                  CustomSwitchWidget(
                    value: _isMEB,
                    label: 'MEB',
                    onChanged: (value) {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _isMEB = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          label: 'Gidilecek Tarih',
                          labelStyle: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                                color: AppColors.primaryDark,
                              ),
                          initialDate: _gidilecekTarih,
                          minDate: DateTime.now(),
                          maxDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          onDateChanged: (date) {
                            setState(() {
                              _gidilecekTarih = date;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                                color: AppColors.primaryDark,
                              ),
                          initialHour: _gidisSaat,
                          initialMinute: _gidisDakika,
                          minHour: 0,
                          maxHour: 23,
                          allowedMinutes: _allowedMinutes,
                          label: 'Gidiş Saati',
                          allowAllMinutesAtMaxHour: true,
                          onTimeChanged: (hour, minute) {
                            setState(() {
                              _gidisSaat = hour;
                              _gidisDakika = minute;
                              _syncDonusWithGidis(
                                startHour: hour,
                                startMinute: minute,
                              );
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final minDonus = _computeDonusMin(
                              _gidisSaat,
                              _gidisDakika,
                            );
                            return TimePickerBottomSheetWidget(
                              key: ValueKey(
                                'donus-$_gidisSaat-$_gidisDakika-$_donusSaat-$_donusDakika',
                              ),
                              labelStyle: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize:
                                        (Theme.of(
                                              context,
                                            ).textTheme.titleSmall?.fontSize ??
                                            14) +
                                        1,
                                    color: AppColors.primaryDark,
                                  ),
                              initialHour: _donusSaat,
                              initialMinute: _donusDakika,
                              minHour: minDonus.$1,
                              minMinute: minDonus.$2,
                              maxHour: 23,
                              allowedMinutes: _allowedMinutes,
                              allowAllMinutesAtMaxHour: true,
                              label: 'Dönüş Saati',
                              onTimeChanged: (hour, minute) {
                                setState(() {
                                  _donusSaat = hour;
                                  _donusDakika = minute;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const CommonDivider(),
                  const SizedBox(height: 32),
                  Text(
                    'Araç İstek Nedeni',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _openAracIstekNedeniBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _buildAracIstekNedeniSummary(),
                              style: TextStyle(
                                color: _selectedAracIstekNedeniId != null
                                    ? AppColors.textPrimary
                                    : Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedAracIstekNedeniId == -1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextField(
                          focusNode: _customAracIstekNedeniFocusNode,
                          controller: _customAracIstekNedeniController,
                          onChanged: (value) {
                            setState(() {
                              _customAracIstekNedeni = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Araç istek nedenini giriniz',
                            filled: true,
                            fillColor: AppColors.textOnPrimary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.gradientStart,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  AciklamaFieldWidget(
                    controller: _aciklamaController,
                    focusNode: _aciklamaFocusNode,
                  ),

                  const CommonDivider(),
                  const SizedBox(height: 32),
                  Text(
                    'Yolcu Seçimi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      color: AppColors.primaryDark,
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _ogrenciSheetLoading
                        ? null
                        : _openOgrenciSecimBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        border: Border.all(
                          color: AppColors.borderStandartColor,
                          width: 0.75,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _buildOgrenciSummary(),
                              style: TextStyle(
                                color: _selectedOgrenciIds.isNotEmpty
                                    ? AppColors.textPrimary
                                    : Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: _selectedOgrenciIds.isNotEmpty
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_ogrenciSheetLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedOgrenciIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _openSecilenOgrenciListesiBottomSheet,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.list,
                                color: AppColors.gradientStart,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Seçilen öğrencileri listele',
                                style: TextStyle(
                                  color: AppColors.gradientStart,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${_selectedOgrenciIds.length})',
                                style: TextStyle(
                                  color: AppColors.gradientStart,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Text(
                    'Toplam yolcu sayısı: ${_getYolcuSayisi()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GonderButtonWidget(
                    onPressed: _submitForm,
                    padding: 14.0,
                    borderRadius: 8.0,
                    textStyle: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToGidilecekYerSection() async {
    final context = _gidilecekYerSectionKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  Future<void> _submitForm() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      // Basit validasyonlar
      if (_entries.isEmpty) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen en az 1 gidilecek yer ekleyiniz',
        );
        if (!mounted) return;
        await _scrollToGidilecekYerSection();
        _gidilecekYerButtonFocusNode.requestFocus();
        setState(() => _isActionInProgress = false);
        return;
      }
      if (_gidilecekTarih == null) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen gidilecek tarihi seçiniz',
        );
        return;
      }
      if (_selectedAracIstekNedeniId == null) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen araç istek nedenini seçiniz',
        );
        return;
      }
      if (_selectedAracIstekNedeniId == -1 &&
          (_customAracIstekNedeniController.text.trim().isEmpty)) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen diğer istek nedenini giriniz',
        );
        _customAracIstekNedeniFocusNode.requestFocus();
        return;
      }

      // Açıklama minimum 15 karakter kontrolü
      if (_aciklamaController.text.length < 15) {
        await ValidationUyariWidget.goster(
          context: context,
          message: 'Lütfen en az 15 karakter olacak şekilde açıklama giriniz',
        );
        _aciklamaFocusNode.requestFocus();
        return;
      }

      for (final entry in _entries) {
        if (!entry.yer.yerAdi.contains('Eyüboğlu') &&
            entry.adresController.text.trim().isEmpty) {
          await ValidationUyariWidget.goster(
            context: context,
            message: 'Lütfen yer için semt/adres giriniz',
          );
          entry.focusNode.requestFocus();
          return;
        }
      }

      final request = _buildAracIstekEkleReq();
      final ozetItems = _buildAracIstekOzetItems(request);

      showAracIstekOzetBottomSheet(
        context: context,
        request: request,
        talepTipi: 'Binek',
        ozetItems: ozetItems,
        onGonder: () async {
          await _sendAracIstek(request);
        },
        onSuccess: () async {
          if (!mounted) return;
          await IstekBasariliWidget.goster(
            context: context,
            message: 'Araç isteğiniz oluşturulmuştur.',
            onConfirm: () async {
              ref.invalidate(aracDevamEdenTaleplerProvider);
              ref.invalidate(aracTamamlananTaleplerProvider);
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
              if (!context.mounted) return;
              context.go('/arac_istek');
            },
          );
        },
        onError: (error) {
          if (!mounted) return;
          _showStatusBottomSheet(
            error.isEmpty ? 'Hata oluştu' : error,
            isError: true,
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    _lockAndUnfocusInputs();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (BuildContext statusContext) {
        return StatusBottomSheet(
          message: message,
          isError: isError,
          onButtonPressed: () {
            Navigator.pop(statusContext);

            // Başarı durumunda Araç Taleplerini Yönet ekranına git
            if (!isError) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  // Provider'ları yenile
                  ref.invalidate(aracDevamEdenTaleplerProvider);
                  ref.invalidate(aracTamamlananTaleplerProvider);

                  // Tüm önceki ekranları temizleyip doğrudan Araç Taleplerini Yönet'e git
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      context.go('/arac_istek');
                    }
                  });
                }
              });
            }
          },
        );
      },
    ).whenComplete(() {
      _unlockInputsAfterSheet();
    });
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _deriveSeviyeFromSinif(String sinif, {String fallback = '0'}) {
    final normalized = sinif.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return fallback;
    if (normalized.length == 1) return normalized;
    return normalized.substring(0, 2);
  }

  String _buildGidilecekYerSummary() {
    if (_entries.isEmpty) return '-';

    final lines = <String>[];
    for (final e in _entries) {
      final yer = e.yer.yerAdi.trim();
      final semt = e.yer.yerAdi.contains('Eyüboğlu')
          ? ''
          : e.adresController.text.trim();
      if (semt.isEmpty) {
        lines.add('• $yer');
      } else {
        lines.add('• $yer - $semt');
      }
    }
    return lines.join('\n');
  }

  int _getYolcuSayisi() {
    final count = _selectedPersonelIds.length + _selectedOgrenciIds.length;
    return count == 0 ? 1 : count;
  }

  String _buildSelectedPersonelSummaryForOzet() {
    if (_selectedPersonelIds.isEmpty) {
      // Hiç personel seçilmemişse, dolduran personeli göster
      try {
        final personelAsync = ref.read(personelBilgiProvider);
        if (personelAsync.hasValue && personelAsync.value != null) {
          final personel = personelAsync.value!;
          final name = personel.adSoyad.trim();
          return name.isEmpty ? '-' : name;
        }
      } catch (_) {
        // Provider'dan alınamazsa _personeller'den almayı dene
      }

      // Fallback: _personeller'den current personeli al
      final currentPersonelId = ref.read(currentPersonelIdProvider);
      final current = _personeller.firstWhere(
        (p) => p.personelId == currentPersonelId,
        orElse: () => PersonelItem(
          personelId: currentPersonelId,
          adi: '',
          soyadi: '',
          gorevId: null,
          gorevYeriId: null,
        ),
      );
      final name = '${current.adi} ${current.soyadi}'.trim();
      return name.isEmpty ? '-' : name;
    }
    if (_selectedPersonelIds.length > 2) {
      return '${_selectedPersonelIds.length} personel';
    }

    final names = _personeller
        .where((p) => _selectedPersonelIds.contains(p.personelId))
        .map((p) => '${p.adi} ${p.soyadi}'.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) return '${_selectedPersonelIds.length} personel';
    return names.join(', ');
  }

  String _buildSelectedOgrenciSummaryForOzet() {
    if (_selectedOgrenciIds.isEmpty) return '-';
    if (_selectedOgrenciIds.length > 2) {
      return '${_selectedOgrenciIds.length} öğrenci';
    }

    final Map<String, String> numaraToName = {};
    for (final o in _ogrenciList) {
      final numara = '${o.numara}';
      if (!_selectedOgrenciIds.contains(numara)) continue;
      final name = '${o.adi} ${o.soyadi}'.trim();
      if (name.isEmpty) continue;
      numaraToName.putIfAbsent(numara, () => name);
    }
    final names = numaraToName.values.toList();
    if (names.length == _selectedOgrenciIds.length && names.isNotEmpty) {
      return names.join(', ');
    }
    return '${_selectedOgrenciIds.length} öğrenci';
  }

  String _resolveIstekNedeni() {
    if (_selectedAracIstekNedeniId == null) return '';
    if (_selectedAracIstekNedeniId == -1) return 'DİĞER';
    final selected = _aracIstekNedenleri.firstWhere(
      (i) => i.id == _selectedAracIstekNedeniId,
      orElse: () => AracIstekNedeniItem(id: -1, ad: ''),
    );
    return selected.ad;
  }

  AracIstekEkleReq _buildAracIstekEkleReq() {
    final currentPersonelId = ref.read(currentPersonelIdProvider);
    final gidilecekTarih = _gidilecekTarih ?? DateTime.now();

    final gorevIdToName = {for (final g in _gorevler) g.id: g.gorevAdi};
    final gorevYeriIdToName = {
      for (final gy in _gorevYerleri) gy.id: gy.gorevYeriAdi,
    };

    final hasSelectedYolcu =
        _selectedPersonelIds.isNotEmpty || _selectedOgrenciIds.isNotEmpty;
    final selectedPersonel = _personeller
        .where((p) => _selectedPersonelIds.contains(p.personelId))
        .toList();
    if (!hasSelectedYolcu) {
      final fallback = _personeller.firstWhere(
        (p) => p.personelId == currentPersonelId,
        orElse: () => PersonelItem(
          personelId: currentPersonelId,
          adi: '',
          soyadi: '',
          gorevId: null,
          gorevYeriId: null,
        ),
      );
      selectedPersonel.add(fallback);
    }
    final yolcuPersonelSatir = selectedPersonel
        .map(
          (p) => AracIstekYolcuPersonelSatir(
            personelId: p.personelId,
            perAdi: '${p.adi} ${p.soyadi}'.trim(),
            gorevi: (p.gorevId != null) ? (gorevIdToName[p.gorevId] ?? '') : '',
            gorevYeri: (p.gorevYeriId != null)
                ? (gorevYeriIdToName[p.gorevYeriId] ?? '')
                : '',
          ),
        )
        .toList();

    final yolcuDepartmanId = selectedPersonel
        .map((p) => p.gorevYeriId)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList();

    // Öğrenci listesi duplicate gelebiliyor: numara bazında tekilleştir.
    final Map<int, FilterOgrenciItem> numaraToOgr = {};
    for (final o in _ogrenciList) {
      numaraToOgr.putIfAbsent(o.numara, () => o);
    }

    final okullarSatir = <AracIstekOkulSatir>[];
    for (final numaraStr in _selectedOgrenciIds) {
      final numara = int.tryParse(numaraStr);
      if (numara == null) continue;
      final o = numaraToOgr[numara];
      if (o == null) continue;
      okullarSatir.add(
        AracIstekOkulSatir(
          okulKodu: o.okulKodu,
          sinif: o.sinif,
          seviye: _deriveSeviyeFromSinif(
            o.sinif,
            fallback: o.seviye.trim().isEmpty ? '0' : o.seviye.trim(),
          ),
          numara: o.numara,
          adi: o.adi,
          soyadi: o.soyadi,
        ),
      );
    }

    final gidilecekYerSatir = _entries
        .map(
          (e) => AracIstekGidilecekYerSatir(
            gidilecekYer: e.yer.yerAdi,
            semt: e.yer.yerAdi.contains('Eyüboğlu')
                ? ''
                : e.adresController.text.trim(),
          ),
        )
        .toList();

    final istekNedeni = _resolveIstekNedeni();
    final istekNedeniDiger = (_selectedAracIstekNedeniId == -1)
        ? _customAracIstekNedeniController.text.trim()
        : '';
    final aracTuru = _getAracTuruName();

    return AracIstekEkleReq(
      personelId: currentPersonelId,
      gidilecekTarih: gidilecekTarih,
      gidisSaat: _gidisSaat.toString().padLeft(2, '0'),
      gidisDakika: _gidisDakika.toString().padLeft(2, '0'),
      donusSaat: _donusSaat.toString().padLeft(2, '0'),
      donusDakika: _donusDakika.toString().padLeft(2, '0'),
      aracTuru: aracTuru,
      yolcuPersonelSatir: yolcuPersonelSatir,
      yolcuDepartmanId: yolcuDepartmanId,
      okullarSatir: okullarSatir,
      gidilecekYerSatir: gidilecekYerSatir,
      yolcuSayisi: _getYolcuSayisi(),
      mesafe: _tahminiMesafe,
      istekNedeni: istekNedeni,
      istekNedeniDiger: istekNedeniDiger,
      aciklama: _aciklamaController.text,
      tasinacakYuk: '',
      meb: _isMEB,
    );
  }

  List<AracIstekOzetItem> _buildAracIstekOzetItems(AracIstekEkleReq req) {
    final aracTuru = _getAracTuruName();
    final items = <AracIstekOzetItem>[
      AracIstekOzetItem(label: 'Araç Türü', value: aracTuru, multiLine: false),
      AracIstekOzetItem(
        label: 'Gidilecek Tarih',
        value: _formatDateShort(req.gidilecekTarih),
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'Gidiş Saati',
        value: _formatTime(_gidisSaat, _gidisDakika),
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'Dönüş Saati',
        value: _formatTime(_donusSaat, _donusDakika),
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'Tahmini Mesafe (km)',
        value: _tahminiMesafe.toString(),
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'MEB',
        value: _isMEB ? 'Evet' : 'Hayır',
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'İstek Nedeni',
        value: _selectedAracIstekNedeniId == -1
            ? 'DİĞER'
            : _buildAracIstekNedeniSummary(),
        multiLine: true,
      ),
      AracIstekOzetItem(
        label: 'Açıklama',
        value: req.aciklama.isEmpty ? '-' : req.aciklama,
        multiLine: true,
      ),
    ];

    if (_selectedAracIstekNedeniId == -1) {
      items.add(
        AracIstekOzetItem(
          label: 'İstek Nedeni (Diğer)',
          value: _customAracIstekNedeniController.text.trim(),
        ),
      );
    }

    items.addAll([
      AracIstekOzetItem(
        label: 'Yolcu Sayısı',
        value: req.yolcuSayisi.toString(),
        multiLine: false,
      ),
      AracIstekOzetItem(
        label: 'Seçilen Personel',
        value: _buildSelectedPersonelSummaryForOzet(),
      ),
      AracIstekOzetItem(
        label: 'Seçilen Öğrenci',
        value: _buildSelectedOgrenciSummaryForOzet(),
      ),
      AracIstekOzetItem(
        label: 'Gidilecek Yer(ler)',
        value: _buildGidilecekYerSummary(),
      ),
    ]);

    return items;
  }

  Future<void> _sendAracIstek(AracIstekEkleReq req) async {
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.aracIstekEkle(req);

    switch (result) {
      case Success():
        return;
      case Failure(:final message):
        throw Exception('Araç isteği gönderilemedi: $message');
      case Loading():
        throw Exception('Yükleniyor');
    }
  }

  String _buildOgrenciSummary() {
    if (_selectedOgrenciIds.isEmpty) {
      return 'Öğrenci seçiniz';
    }

    return 'Öğrenci ekle';
  }

  String _buildAracIstekNedeniSummary() {
    if (_selectedAracIstekNedeniId == null) {
      return 'Araç istek nedenini seçiniz';
    }

    if (_selectedAracIstekNedeniId == -1) {
      return 'DİĞER';
    }

    final selected = _aracIstekNedenleri.firstWhere(
      (item) => item.id == _selectedAracIstekNedeniId,
      orElse: () => AracIstekNedeniItem(id: -1, ad: ''),
    );

    return selected.ad.isNotEmpty ? selected.ad : 'Araç istek nedenini seçiniz';
  }

  Widget _buildSelectActions({
    required VoidCallback onClear,
    required VoidCallback onSelectAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Temizle', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Tümü', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMainItem({
    required String title,
    required String selectedValue,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (selectedValue != 'Seçiniz') ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _openAracIstekNedeniBottomSheet() async {
    final searchController = TextEditingController();
    String query = '';

    if (_isActionInProgress) return;
    _lockAndUnfocusInputs();
    setState(() => _isActionInProgress = true);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.66,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: FutureBuilder<List<AracIstekNedeniItem>>(
                future: _fetchAracIstekNedenleri(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Nedeler yüklenemedi: ${snapshot.error}'),
                    );
                  }

                  final nedelerList = snapshot.data ?? [];
                  _aracIstekNedenleri = nedelerList;

                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      final filtered = nedelerList
                          .where(
                            (n) => n.ad.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();

                      return SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  setModalState(() {
                                    query = value.trim().toLowerCase();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Ara...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: query.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            searchController.clear();
                                            setModalState(() {
                                              query = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.gradientStart,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Sonuç bulunamadı',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    return ListTile(
                                      title: Text(item.ad),
                                      onTap: () {
                                        setState(() {
                                          _selectedAracIstekNedeniId = item.id;
                                          if (item.id == -1) {
                                            _customAracIstekNedeni = null;
                                            _customAracIstekNedeniController
                                                .clear();
                                          } else {
                                            _customAracIstekNedeni = null;
                                            _customAracIstekNedeniController
                                                .clear();
                                          }
                                        });
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _unlockInputsAfterSheet();
      if (mounted) setState(() => _isActionInProgress = false);
    });
  }

  Future<List<AracIstekNedeniItem>> _fetchAracIstekNedenleri() async {
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.aracIstekNedenleriGetir();

    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final message):
        throw Exception(message);
      case Loading():
        return [];
    }
  }

  Future<void> _openSecilenOgrenciListesiBottomSheet() async {
    if (_isActionInProgress) return;
    _lockAndUnfocusInputs();
    setState(() => _isActionInProgress = true);

    String searchQuery = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.67,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final selectedIds = _selectedOgrenciIds.toList();
                final filteredIds = searchQuery.isEmpty
                    ? selectedIds
                    : selectedIds.where((ogrenciNumara) {
                        final ogrenci = _ogrenciList.firstWhere(
                          (o) => '${o.numara}' == ogrenciNumara,
                          orElse: () => FilterOgrenciItem(
                            okulKodu: '',
                            sinif: '',
                            numara: -1,
                            adi: 'Bilinmeyen',
                            soyadi: 'Öğrenci',
                          ),
                        );
                        final fullName = '${ogrenci.adi} ${ogrenci.soyadi}'
                            .toLowerCase();
                        final q = searchQuery.toLowerCase();
                        return fullName.contains(q) ||
                            ogrenciNumara.toLowerCase().contains(q);
                      }).toList();
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.textOnPrimary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Seçilen Öğrenciler (${_selectedOgrenciIds.length})',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Dikkat'),
                                    content: const Text(
                                      'Tüm seçilen öğrenciler listeden çıkarılacaktır. Emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                        },
                                        child: const Text('Vazgeç'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          setModalState(() {
                                            _selectedOgrenciIds.clear();
                                          });
                                          setState(() {});
                                          FocusScope.of(context).unfocus();
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Evet',
                                          style: TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Tümünü Sil',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedOgrenciIds.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Öğrenci ara...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setModalState(() => searchQuery = val);
                              },
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: filteredIds.length,
                            itemBuilder: (context, index) {
                              final ogrenciNumara = filteredIds[index];
                              final ogrenci = _ogrenciList.firstWhere(
                                (o) => '${o.numara}' == ogrenciNumara,
                                orElse: () => FilterOgrenciItem(
                                  okulKodu: '',
                                  sinif: '',
                                  numara: -1,
                                  adi: 'Bilinmeyen',
                                  soyadi: 'Öğrenci',
                                ),
                              );

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${ogrenci.adi} ${ogrenci.soyadi}'
                                            .trim(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: AppColors.textTertiary,
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedOgrenciIds.remove(
                                            ogrenciNumara,
                                          );
                                        });
                                        setState(() {});
                                        if (_selectedOgrenciIds.isEmpty) {
                                          FocusScope.of(context).unfocus();
                                          Navigator.pop(context);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _unlockInputsAfterSheet();
      if (mounted) setState(() => _isActionInProgress = false);
    });
  }

  Future<void> _openOgrenciSecimBottomSheet() async {
    if (_isActionInProgress) return;
    FocusScope.of(context).unfocus();
    setState(() => _isActionInProgress = true);

    try {
      BrandedLoadingDialog.show(context);
      // UI'nin dialog'u çizmesi için bir frame ver.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      setState(() {
        _ogrenciSheetLoading = true;
        _ogrenciSheetError = null;
      });

      // İlk açılışta filtre verisini sunucudan al, sonraki açılışlarda cache kullan.
      if (!_hasOgrenciBaseCache) {
        final repo = ref.read(aracTalepRepositoryProvider);
        final result = await repo.ogrenciFiltrele();

        switch (result) {
          case Success(:final data):
            setState(() {
              _initialOkulKoduList = data.okulKodu;
              _initialSeviyeList = data.seviye;
              _initialSinifList = data.sinif;
              _initialOgrenciList = data.ogrenci;
              _okulKoduList = _initialOkulKoduList;
              _seviyeList = _initialSeviyeList;
              _sinifList = _initialSinifList;
              _kulupList = data.kulup;
              _takimList = data.takim;
              _ogrenciList = data.ogrenci;
            });
          case Failure(:final message):
            setState(() {
              _ogrenciSheetLoading = false;
              _ogrenciSheetError = message;
            });
            if (!mounted) return;
            BrandedLoadingDialog.hide(context);
            _showStatusBottomSheet(message, isError: true);
            return;
          case Loading():
            if (!mounted) return;
            BrandedLoadingDialog.hide(context);
            return;
        }
      }

      // State'ten mevcut seçimleri yükle
      final localSelectedOkul = {..._selectedOkulKodu};
      final localSelectedSeviye = {..._selectedSeviye};
      final localSelectedSinif = {..._selectedSinif};
      final localSelectedKulup = {..._selectedKulup};
      final localSelectedTakim = {..._selectedTakim};

      // Daha önce seçim yapıldıysa, sadece öğrenci listesini (ve downstream: kulüp/takım) tek çağrıyla güncelle.
      final bool hasAnyFilter =
          localSelectedOkul.isNotEmpty ||
          localSelectedSeviye.isNotEmpty ||
          localSelectedSinif.isNotEmpty ||
          localSelectedKulup.isNotEmpty ||
          localSelectedTakim.isNotEmpty;

      if (hasAnyFilter) {
        final resp = await _fetchOgrenciFilters(
          localSelectedOkul,
          localSelectedSeviye,
          localSelectedSinif,
          localSelectedKulup,
          localSelectedTakim,
        );
        if (resp != null && mounted) {
          setState(() {
            // Okul/Seviye/Sınıf listeleri ilk çağrıdaki gibi sabit kalsın.
            _okulKoduList = _initialOkulKoduList;
            _seviyeList = _initialSeviyeList;
            _sinifList = _initialSinifList;

            _kulupList = resp.kulup;
            _takimList = resp.takim;
            _ogrenciList = resp.ogrenci;
          });
        }
      } else {
        // Filtre yoksa upstream listeleri cache'ten sabitle.
        if (mounted) {
          setState(() {
            _okulKoduList = _initialOkulKoduList;
            _seviyeList = _initialSeviyeList;
            _sinifList = _initialSinifList;
            _ogrenciList = _initialOgrenciList;
          });
        }
      }

      if (mounted) {
        setState(() {
          _ogrenciSheetLoading = false;
        });
      }

      if (!mounted) return;
      BrandedLoadingDialog.hide(context);
      final localSelectedOgrenci = {..._selectedOgrenciIds};

      // Temp set for detail pages (Discard logic)
      final Set<String> tempSelectedItems = {};

      _currentFilterPage = '';

      if (!mounted) return;

      if (!mounted) return;

      _lockAndUnfocusInputs();
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.67,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setModalState) {
              Widget buildMain() {
                return OgrenciFilterMainMenuFull(
                  state: OgrenciFilterStateFull(
                    selectedOkulKodu: localSelectedOkul,
                    selectedSeviye: localSelectedSeviye,
                    selectedSinif: localSelectedSinif,
                    selectedKulup: localSelectedKulup,
                    selectedTakim: localSelectedTakim,
                    selectedOgrenciIds: localSelectedOgrenci,
                    okulKoduList: _okulKoduList,
                    seviyeList: _seviyeList,
                    sinifList: _sinifList,
                    kulupList: _kulupList,
                    takimList: _takimList,
                    ogrenciList: _ogrenciList,
                  ),
                  scrollController: scrollController,
                  onPageSelected: (page) {
                    tempSelectedItems.clear();
                    switch (page) {
                      case 'okul':
                        tempSelectedItems.addAll(localSelectedOkul);
                        break;
                      case 'seviye':
                        tempSelectedItems.addAll(localSelectedSeviye);
                        break;
                      case 'sinif':
                        tempSelectedItems.addAll(localSelectedSinif);
                        break;
                      case 'kulup':
                        tempSelectedItems.addAll(localSelectedKulup);
                        break;
                      case 'takim':
                        tempSelectedItems.addAll(localSelectedTakim);
                        break;
                      case 'ogrenci':
                        tempSelectedItems.addAll(localSelectedOgrenci);
                        break;
                    }
                    setModalState(() => _currentFilterPage = page);
                  },
                );
              }

              Widget buildDetail() {
                switch (_currentFilterPage) {
                  case 'okul':
                    return _buildOkulFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  case 'seviye':
                    return _buildSeviyeFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems,
                      localSelectedOkul,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  case 'sinif':
                    return _buildSinifFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems,
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  case 'kulup':
                    return _buildKulupFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems,
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  case 'takim':
                    return _buildTakimFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems,
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedOgrenci,
                    );
                  case 'ogrenci':
                    return OgrenciListFilterPageFull(
                      ogrenciList: _ogrenciList,
                      selectedIds: tempSelectedItems,
                      scrollController: scrollController,
                      onSelectionChanged: (newSelection) {
                        setModalState(() {
                          tempSelectedItems
                            ..clear()
                            ..addAll(newSelection);
                        });
                      },
                    );
                  default:
                    return buildMain();
                }
              }

              String _getFilterTitle(String key) {
                switch (key) {
                  case 'okul':
                    return 'Okul';
                  case 'seviye':
                    return 'Seviye';
                  case 'sinif':
                    return 'Sınıf';
                  case 'kulup':
                    return 'Kulüp';
                  case 'takim':
                    return 'Takım';
                  case 'ogrenci':
                    return 'Öğrenci';
                  default:
                    return 'Filtrele';
                }
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        if (_currentFilterPage.isNotEmpty)
                          InkWell(
                            onTap: () {
                              // BACK pressed: Discard changes
                              setModalState(() {
                                _currentFilterPage = '';
                                tempSelectedItems.clear();
                              });
                            },
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.arrow_back_ios,
                                  size: 20,
                                  color: AppColors.gradientStart,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Geri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.gradientStart,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(width: 0),
                        Expanded(
                          child: Align(
                            alignment: _currentFilterPage.isEmpty
                                ? Alignment.centerLeft
                                : Alignment.center,
                            child: Text(
                              _currentFilterPage.isEmpty
                                  ? 'Filtrele'
                                  : _getFilterTitle(_currentFilterPage),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Only show 'Temizle' on main page
                        if (_currentFilterPage.isEmpty)
                          TextButton(
                            onPressed: () async {
                              setModalState(() => _currentFilterPage = '');
                              localSelectedOkul.clear();
                              localSelectedSeviye.clear();
                              localSelectedSinif.clear();
                              localSelectedKulup.clear();
                              localSelectedTakim.clear();
                              localSelectedOgrenci.clear();

                              await _refreshOgrenciFilterData(
                                localSelectedOkul: localSelectedOkul,
                                localSelectedSeviye: localSelectedSeviye,
                                localSelectedSinif: localSelectedSinif,
                                localSelectedKulup: localSelectedKulup,
                                localSelectedTakim: localSelectedTakim,
                                localSelectedOgrenci: localSelectedOgrenci,
                                rebuild: setModalState,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text('Tüm filtreleri temizle'),
                          )
                        else
                          const SizedBox(width: 0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _currentFilterPage.isEmpty
                        ? buildMain()
                        : buildDetail(),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_currentFilterPage.isEmpty) {
                              setState(() {
                                // Öğrenci seçimini mevcut listeye ekle
                                _selectedOgrenciIds.addAll(
                                  localSelectedOgrenci,
                                );

                                // Filtreleri sıfırla
                                _selectedOkulKodu.clear();
                                _selectedSeviye.clear();
                                _selectedSinif.clear();
                                _selectedKulup.clear();
                                _selectedTakim.clear();
                              });
                              FocusScope.of(context).unfocus();
                              Navigator.pop(context);
                            } else {
                              // "TAMAM" pressed: Commit temp -> local
                              if (_currentFilterPage == 'okul') {
                                localSelectedOkul.clear();
                                localSelectedOkul.addAll(tempSelectedItems);
                              } else if (_currentFilterPage == 'seviye') {
                                localSelectedSeviye.clear();
                                localSelectedSeviye.addAll(tempSelectedItems);
                              } else if (_currentFilterPage == 'sinif') {
                                localSelectedSinif.clear();
                                localSelectedSinif.addAll(tempSelectedItems);
                              } else if (_currentFilterPage == 'kulup') {
                                localSelectedKulup.clear();
                                localSelectedKulup.addAll(tempSelectedItems);
                              } else if (_currentFilterPage == 'takim') {
                                localSelectedTakim.clear();
                                localSelectedTakim.addAll(tempSelectedItems);
                              } else if (_currentFilterPage == 'ogrenci') {
                                localSelectedOgrenci.clear();
                                localSelectedOgrenci.addAll(tempSelectedItems);
                              }

                              // Refresh downstream lists logic
                              if (_currentFilterPage != 'ogrenci') {
                                final updateSeviye =
                                    _currentFilterPage == 'okul';
                                final updateSinif =
                                    _currentFilterPage == 'okul' ||
                                    _currentFilterPage == 'seviye';
                                final updateKulup =
                                    _currentFilterPage == 'okul' ||
                                    _currentFilterPage == 'seviye' ||
                                    _currentFilterPage == 'sinif';
                                final updateTakim =
                                    _currentFilterPage == 'okul' ||
                                    _currentFilterPage == 'seviye' ||
                                    _currentFilterPage == 'sinif' ||
                                    _currentFilterPage == 'kulup';

                                await _refreshOgrenciFilterData(
                                  localSelectedOkul: localSelectedOkul,
                                  localSelectedSeviye: localSelectedSeviye,
                                  localSelectedSinif: localSelectedSinif,
                                  localSelectedKulup: localSelectedKulup,
                                  localSelectedTakim: localSelectedTakim,
                                  localSelectedOgrenci: localSelectedOgrenci,
                                  rebuild: setModalState,
                                  updateSeviyeList: updateSeviye,
                                  updateSinifList: updateSinif,
                                  updateKulupList: updateKulup,
                                  updateTakimList: updateTakim,
                                  updateOgrenciList: true,
                                  autoSelectAllOgrenci: true,
                                );
                              } else {
                                // For student selection, we might want to refresh count only
                                // But _refreshOgrenciFilterData also updates count logic if needed
                                // Just simple setState to reflect changes in Main view summary is enough
                                setModalState(() {});
                              }

                              setModalState(() {
                                _currentFilterPage = '';
                                tempSelectedItems.clear(); // cleanup
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentFilterPage.isEmpty ? 'Uygula' : 'Tamam',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  String _summaryForOkul(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} okul seçildi';
  }

  String _summaryForSeviye(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} seviye seçildi';
  }

  String _summaryForSinif(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} sınıf seçildi';
  }

  String _summaryForKulup(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} kulüp seçildi';
  }

  String _summaryForTakim(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    if (ids.length <= 2) return ids.join(', ');
    return '${ids.length} takım seçildi';
  }

  String _summaryForOgrenci(Set<String> ids) {
    if (ids.isEmpty) return 'Seçiniz';

    // _ogrenciList içinde aynı numara birden fazla kez gelebiliyor.
    // Sayımı her zaman seçili Set üzerinden (unique numara) yap.
    if (ids.length > 2) return '${ids.length} öğrenci seçildi';

    final Map<String, String> numaraToName = {};
    for (final o in _ogrenciList) {
      final numara = '${o.numara}';
      if (!ids.contains(numara)) continue;

      final name = '${o.adi} ${o.soyadi}'.trim();
      if (name.isEmpty) continue;

      numaraToName.putIfAbsent(numara, () => name);
    }

    final names = numaraToName.values.toList();
    if (names.length == ids.length && names.isNotEmpty) {
      return names.join(', ');
    }

    return '${ids.length} öğrenci seçildi';
  }

  Future<OgrenciFilterResponse?> _fetchOgrenciFilters(
    Set<String> selectedOkulKodlari,
    Set<String> selectedSeviyeler,
    Set<String> selectedSiniflar,
    Set<String> selectedKulupler,
    Set<String> selectedTakimlar,
  ) async {
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.mobilOgrenciFiltrele(
      okulKodlari: selectedOkulKodlari,
      seviyeler: selectedSeviyeler,
      siniflar: selectedSiniflar,
      kulupler: selectedKulupler,
      takimlar: selectedTakimlar,
    );

    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final message):
        if (mounted) {
          _showStatusBottomSheet(message, isError: true);
        }
        return null;
      case Loading():
        return null;
    }
  }

  Future<void> _refreshOgrenciFilterData({
    required Set<String> localSelectedOkul,
    required Set<String> localSelectedSeviye,
    required Set<String> localSelectedSinif,
    required Set<String> localSelectedKulup,
    required Set<String> localSelectedTakim,
    required Set<String> localSelectedOgrenci,
    required StateSetter rebuild,
    // Flags to control which downstream lists to update
    bool updateSeviyeList = false,
    bool updateSinifList = false,
    bool updateKulupList = false,
    bool updateTakimList = false,
    bool updateOgrenciList = false,
    bool autoSelectAllOgrenci = false,
  }) async {
    // Bu fonksiyon geçmişte ardışık 4-5 istek atıyordu. UX'te gecikmeye sebep olmaması için
    // tek bir API çağrısı ile gerekli listeleri güncelliyoruz.
    final bool shouldFetch =
        updateSeviyeList ||
        updateSinifList ||
        updateKulupList ||
        updateTakimList ||
        updateOgrenciList;
    if (!shouldFetch) return;

    final Set<String> reqOkul = localSelectedOkul;
    Set<String> reqSeviye = localSelectedSeviye;
    Set<String> reqSinif = localSelectedSinif;
    Set<String> reqKulup = localSelectedKulup;
    Set<String> reqTakim = localSelectedTakim;

    // Hedef "seviye" ise sadece okul gönder.
    if (updateSeviyeList &&
        !updateSinifList &&
        !updateKulupList &&
        !updateTakimList &&
        !updateOgrenciList) {
      reqSeviye = {};
      reqSinif = {};
      reqKulup = {};
      reqTakim = {};
    } else if (updateSinifList &&
        !updateKulupList &&
        !updateTakimList &&
        !updateOgrenciList) {
      // Hedef "sınıf" ise okul + seviye gönder.
      reqSinif = {};
      reqKulup = {};
      reqTakim = {};
    } else if (updateKulupList && !updateTakimList && !updateOgrenciList) {
      // Hedef "kulüp" ise okul + seviye + sınıf gönder.
      reqKulup = {};
      reqTakim = {};
    } else if (updateTakimList && !updateOgrenciList) {
      // Hedef "takım" ise okul + seviye + sınıf + kulüp gönder.
      reqTakim = {};
    }

    final resp = await _fetchOgrenciFilters(
      reqOkul,
      reqSeviye,
      reqSinif,
      reqKulup,
      reqTakim,
    );
    if (resp == null) return;

    rebuild(() {
      if (updateSeviyeList) {
        _seviyeList = resp.seviye;
        localSelectedSeviye.retainAll(_seviyeList.toSet());
      }
      if (updateSinifList) {
        _sinifList = resp.sinif;
        localSelectedSinif.retainAll(_sinifList.toSet());
      }
      if (updateKulupList) {
        _kulupList = resp.kulup;
        localSelectedKulup.retainAll(_kulupList.toSet());
      }
      if (updateTakimList) {
        _takimList = resp.takim;
        localSelectedTakim.retainAll(_takimList.toSet());
      }
      if (updateOgrenciList) {
        _ogrenciList = resp.ogrenci;

        final validOgrenciNums = _ogrenciList.map((o) => '${o.numara}').toSet();

        final bool filtersEmpty =
            localSelectedOkul.isEmpty &&
            localSelectedSeviye.isEmpty &&
            localSelectedSinif.isEmpty &&
            localSelectedKulup.isEmpty &&
            localSelectedTakim.isEmpty;

        if (autoSelectAllOgrenci) {
          if (filtersEmpty) {
            localSelectedOgrenci.retainAll(validOgrenciNums);
          } else {
            localSelectedOgrenci
              ..clear()
              ..addAll(validOgrenciNums);
          }
        } else {
          localSelectedOgrenci.retainAll(validOgrenciNums);
        }
      }
    });
  }

  Widget _buildOkulFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedSinif,
    Set<String> localSelectedKulup,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOgrenci,
  ) {
    final okulSource = _initialOkulKoduList.isNotEmpty
        ? _initialOkulKoduList
        : _okulKoduList;
    if (okulSource.isEmpty) {
      return const Center(child: Text('Okul verisi bulunamadı'));
    }

    final searchController = TextEditingController();
    String searchQuery = '';

    List<String> applyFilters() {
      if (searchQuery.isEmpty) return okulSource;
      final q = searchQuery.toLowerCase();
      return okulSource.where((s) => s.toLowerCase().contains(q)).toList();
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Okul ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) => innerSetState(() => searchQuery = val),
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedOkul.clear();
                  localSelectedSeviye.clear();
                  localSelectedSinif.clear();
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedOkul
                    ..clear()
                    ..addAll(filtered);
                  localSelectedSeviye.clear();
                  localSelectedSinif.clear();
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final okul = filtered[index];
                    final isSelected = localSelectedOkul.contains(okul);
                    return ListTile(
                      dense: true,
                      title: Text(
                        okul,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          innerSetState(() {
                            if (isSelected) {
                              localSelectedOkul.remove(okul);
                            } else {
                              localSelectedOkul.add(okul);
                            }
                            localSelectedSeviye.clear();
                            localSelectedSinif.clear();
                            localSelectedKulup.clear();
                            localSelectedTakim.clear();
                          });

                          () async {
                            await _refreshOgrenciFilterData(
                              localSelectedOkul: localSelectedOkul,
                              localSelectedSeviye: localSelectedSeviye,
                              localSelectedSinif: localSelectedSinif,
                              localSelectedKulup: localSelectedKulup,
                              localSelectedTakim: localSelectedTakim,
                              localSelectedOgrenci: localSelectedOgrenci,
                              rebuild: innerSetState,
                              autoSelectAllOgrenci: true,
                            );
                          }();
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.textOnPrimary,
                                    size: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      onTap: () {
                        innerSetState(() {
                          if (isSelected) {
                            localSelectedOkul.remove(okul);
                          } else {
                            localSelectedOkul.add(okul);
                          }
                          localSelectedSeviye.clear();
                          localSelectedSinif.clear();
                          localSelectedKulup.clear();
                          localSelectedTakim.clear();
                        });

                        () async {
                          await _refreshOgrenciFilterData(
                            localSelectedOkul: localSelectedOkul,
                            localSelectedSeviye: localSelectedSeviye,
                            localSelectedSinif: localSelectedSinif,
                            localSelectedKulup: localSelectedKulup,
                            localSelectedTakim: localSelectedTakim,
                            localSelectedOgrenci: localSelectedOgrenci,
                            rebuild: innerSetState,
                            autoSelectAllOgrenci: true,
                          );
                        }();
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSeviyeFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSinif,
    Set<String> localSelectedKulup,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOgrenci,
  ) {
    if (_seviyeList.isEmpty) {
      return const Center(child: Text('Seviye verisi bulunamadı'));
    }

    final searchController = TextEditingController();
    String searchQuery = '';

    List<String> applyFilters() {
      if (searchQuery.isEmpty) return _seviyeList;
      final q = searchQuery.toLowerCase();
      return _seviyeList.where((s) => s.toLowerCase().contains(q)).toList();
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Seviye ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) => innerSetState(() => searchQuery = val),
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedSeviye.clear();
                  localSelectedSinif.clear();
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedSeviye
                    ..clear()
                    ..addAll(filtered);
                  localSelectedSinif.clear();
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final seviye = filtered[index];
                    final isSelected = localSelectedSeviye.contains(seviye);
                    return ListTile(
                      dense: true,
                      title: Text(
                        seviye,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          innerSetState(() {
                            if (isSelected) {
                              localSelectedSeviye.remove(seviye);
                            } else {
                              localSelectedSeviye.add(seviye);
                            }
                            localSelectedSinif.clear();
                            localSelectedKulup.clear();
                            localSelectedTakim.clear();
                          });

                          () async {
                            await _refreshOgrenciFilterData(
                              localSelectedOkul: localSelectedOkul,
                              localSelectedSeviye: localSelectedSeviye,
                              localSelectedSinif: localSelectedSinif,
                              localSelectedKulup: localSelectedKulup,
                              localSelectedTakim: localSelectedTakim,
                              localSelectedOgrenci: localSelectedOgrenci,
                              rebuild: innerSetState,
                              updateSeviyeList: false,
                              autoSelectAllOgrenci: true,
                            );
                          }();
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.textOnPrimary,
                                    size: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      onTap: () {
                        innerSetState(() {
                          if (isSelected) {
                            localSelectedSeviye.remove(seviye);
                          } else {
                            localSelectedSeviye.add(seviye);
                          }
                          localSelectedSinif.clear();
                          localSelectedKulup.clear();
                          localSelectedTakim.clear();
                        });

                        () async {
                          await _refreshOgrenciFilterData(
                            localSelectedOkul: localSelectedOkul,
                            localSelectedSeviye: localSelectedSeviye,
                            localSelectedSinif: localSelectedSinif,
                            localSelectedKulup: localSelectedKulup,
                            localSelectedTakim: localSelectedTakim,
                            localSelectedOgrenci: localSelectedOgrenci,
                            rebuild: innerSetState,
                            updateSeviyeList: false,
                            autoSelectAllOgrenci: true,
                          );
                        }();
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSinifFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedSinif,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedKulup,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOgrenci,
  ) {
    if (_sinifList.isEmpty) {
      return const Center(child: Text('Sınıf verisi bulunamadı'));
    }

    final searchController = TextEditingController();
    String searchQuery = '';

    List<String> applyFilters() {
      if (searchQuery.isEmpty) return _sinifList;
      final q = searchQuery.toLowerCase();
      return _sinifList.where((s) => s.toLowerCase().contains(q)).toList();
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Sınıf ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) => innerSetState(() => searchQuery = val),
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedSinif.clear();
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    updateSinifList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedSinif
                    ..clear()
                    ..addAll(filtered);
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    updateSinifList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final sinif = filtered[index];
                    final isSelected = localSelectedSinif.contains(sinif);
                    return ListTile(
                      dense: true,
                      title: Text(
                        sinif,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          innerSetState(() {
                            if (isSelected) {
                              localSelectedSinif.remove(sinif);
                            } else {
                              localSelectedSinif.add(sinif);
                            }
                            localSelectedKulup.clear();
                            localSelectedTakim.clear();
                          });

                          () async {
                            await _refreshOgrenciFilterData(
                              localSelectedOkul: localSelectedOkul,
                              localSelectedSeviye: localSelectedSeviye,
                              localSelectedSinif: localSelectedSinif,
                              localSelectedKulup: localSelectedKulup,
                              localSelectedTakim: localSelectedTakim,
                              localSelectedOgrenci: localSelectedOgrenci,
                              rebuild: innerSetState,
                              updateSeviyeList: false,
                              updateSinifList: false,
                              autoSelectAllOgrenci: true,
                            );
                          }();
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.textOnPrimary,
                                    size: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      onTap: () {
                        innerSetState(() {
                          if (isSelected) {
                            localSelectedSinif.remove(sinif);
                          } else {
                            localSelectedSinif.add(sinif);
                          }
                          localSelectedKulup.clear();
                          localSelectedTakim.clear();
                        });

                        () async {
                          await _refreshOgrenciFilterData(
                            localSelectedOkul: localSelectedOkul,
                            localSelectedSeviye: localSelectedSeviye,
                            localSelectedSinif: localSelectedSinif,
                            localSelectedKulup: localSelectedKulup,
                            localSelectedTakim: localSelectedTakim,
                            localSelectedOgrenci: localSelectedOgrenci,
                            rebuild: innerSetState,
                            updateSeviyeList: false,
                            updateSinifList: false,
                            autoSelectAllOgrenci: true,
                          );
                        }();
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildKulupFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedKulup,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedSinif,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOgrenci,
  ) {
    if (_kulupList.isEmpty) {
      return const Center(child: Text('Kulüp verisi bulunamadı'));
    }

    final searchController = TextEditingController();
    String searchQuery = '';

    List<String> applyFilters() {
      if (searchQuery.isEmpty) return _kulupList;
      final q = searchQuery.toLowerCase();
      return _kulupList.where((s) => s.toLowerCase().contains(q)).toList();
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Kulüp ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) => innerSetState(() => searchQuery = val),
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedKulup.clear();
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    updateSinifList: false,
                    updateKulupList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedKulup
                    ..clear()
                    ..addAll(filtered);
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    updateSeviyeList: false,
                    updateSinifList: false,
                    updateKulupList: false,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final kulup = filtered[index];
                    final isSelected = localSelectedKulup.contains(kulup);
                    return ListTile(
                      dense: true,
                      title: Text(
                        kulup,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () {
                          innerSetState(() {
                            if (isSelected) {
                              localSelectedKulup.remove(kulup);
                            } else {
                              localSelectedKulup.add(kulup);
                            }
                            localSelectedTakim.clear();
                          });

                          () async {
                            await _refreshOgrenciFilterData(
                              localSelectedOkul: localSelectedOkul,
                              localSelectedSeviye: localSelectedSeviye,
                              localSelectedSinif: localSelectedSinif,
                              localSelectedKulup: localSelectedKulup,
                              localSelectedTakim: localSelectedTakim,
                              localSelectedOgrenci: localSelectedOgrenci,
                              rebuild: innerSetState,
                              updateSeviyeList: false,
                              updateSinifList: false,
                              updateKulupList: false,
                              autoSelectAllOgrenci: true,
                            );
                          }();
                        },
                        child: Container(
                          width: 40,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.primaryLight,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.textOnPrimary,
                                    size: 18,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      onTap: () {
                        innerSetState(() {
                          if (isSelected) {
                            localSelectedKulup.remove(kulup);
                          } else {
                            localSelectedKulup.add(kulup);
                          }
                          localSelectedTakim.clear();
                        });

                        () async {
                          await _refreshOgrenciFilterData(
                            localSelectedOkul: localSelectedOkul,
                            localSelectedSeviye: localSelectedSeviye,
                            localSelectedSinif: localSelectedSinif,
                            localSelectedKulup: localSelectedKulup,
                            localSelectedTakim: localSelectedTakim,
                            localSelectedOgrenci: localSelectedOgrenci,
                            rebuild: innerSetState,
                            updateSeviyeList: false,
                            updateSinifList: false,
                            updateKulupList: false,
                            autoSelectAllOgrenci: true,
                          );
                        }();
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTakimFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedSinif,
    Set<String> localSelectedKulup,
    Set<String> localSelectedOgrenci,
  ) {
    if (_takimList.isEmpty) {
      return const Center(child: Text('Takım verisi bulunamadı'));
    }

    final searchController = TextEditingController();
    String searchQuery = '';

    List<String> applyFilters() {
      if (searchQuery.isEmpty) return _takimList;
      final q = searchQuery.toLowerCase();
      return _takimList.where((s) => s.toLowerCase().contains(q)).toList();
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Takım ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) => innerSetState(() => searchQuery = val),
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedTakim.clear();
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedTakim
                    ..clear()
                    ..addAll(filtered);
                });

                () async {
                  await _refreshOgrenciFilterData(
                    localSelectedOkul: localSelectedOkul,
                    localSelectedSeviye: localSelectedSeviye,
                    localSelectedSinif: localSelectedSinif,
                    localSelectedKulup: localSelectedKulup,
                    localSelectedTakim: localSelectedTakim,
                    localSelectedOgrenci: localSelectedOgrenci,
                    rebuild: innerSetState,
                    autoSelectAllOgrenci: true,
                  );
                }();
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final takim = filtered[index];
                    final isSelected = localSelectedTakim.contains(takim);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedTakim.add(takim);
                          } else {
                            localSelectedTakim.remove(takim);
                          }
                        });

                        () async {
                          await _refreshOgrenciFilterData(
                            localSelectedOkul: localSelectedOkul,
                            localSelectedSeviye: localSelectedSeviye,
                            localSelectedSinif: localSelectedSinif,
                            localSelectedKulup: localSelectedKulup,
                            localSelectedTakim: localSelectedTakim,
                            localSelectedOgrenci: localSelectedOgrenci,
                            rebuild: innerSetState,
                            autoSelectAllOgrenci: true,
                          );
                        }();
                      },
                      title: Text(
                        takim,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      activeColor: AppColors.primary,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOgrenciFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedOgrenci,
  ) {
    final searchController = TextEditingController();
    String searchQuery = '';

    List<FilterOgrenciItem> applyFilters() {
      return _ogrenciList.where((o) {
        final fullName = '${o.adi} ${o.soyadi}'.toLowerCase();
        final matchSearch =
            searchQuery.isEmpty || fullName.contains(searchQuery.toLowerCase());
        return matchSearch;
      }).toList();
    }

    if (_ogrenciList.isEmpty) {
      return const Center(child: Text('Öğrenci verisi bulunamadı'));
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Öğrenci ara...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            searchController.clear();
                            innerSetState(() => searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.gradientStart,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (val) {
                  innerSetState(() => searchQuery = val);
                },
              ),
            ),
            _buildSelectActions(
              onClear: () {
                innerSetState(() => localSelectedOgrenci.clear());
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedOgrenci
                    ..clear()
                    ..addAll(filtered.map((o) => '${o.numara}'));
                });
              },
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sonuç bulunamadı',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: Colors.grey.shade300,
                  ),
                  itemBuilder: (context, index) {
                    final ogrenci = filtered[index];
                    final isSelected = localSelectedOgrenci.contains(
                      '${ogrenci.numara}',
                    );
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedOgrenci.add('${ogrenci.numara}');
                          } else {
                            localSelectedOgrenci.remove('${ogrenci.numara}');
                          }
                        });
                      },
                      title: Text(
                        '${ogrenci.adi} ${ogrenci.soyadi}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      activeColor: AppColors.primary,
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openYerSecimiBottomSheet() async {
    _lockAndUnfocusInputs();
    final selected = await showModalBottomSheet<GidilecekYerItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController();
        String query = '';

        return DraggableScrollableSheet(
          initialChildSize: 0.66,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: FutureBuilder<List<GidilecekYerItem>>(
                future: _fetchGidilecekYerler(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Yerler yüklenemedi: ${snapshot.error}'),
                    );
                  }

                  final yerleriList = snapshot.data ?? [];

                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      final filtered = yerleriList
                          .where(
                            (y) => y.yerAdi.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();

                      return SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  setModalState(() {
                                    query = value.trim().toLowerCase();
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Yer ara...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: query.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            searchController.clear();
                                            setModalState(() {
                                              query = '';
                                            });
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.gradientStart,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Sonuç bulunamadı',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = filtered[index];
                                    return ListTile(
                                      title: Text(item.yerAdi),
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context, item);
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      _addEntry(selected);
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    }
  }

  Future<List<GidilecekYerItem>> _fetchGidilecekYerler() async {
    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.aracIstekGidilecekYerGetir();

    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final message):
        throw Exception(message);
      case Loading():
        return [];
    }
  }

  void _addEntry(GidilecekYerItem yer) {
    final controller = TextEditingController();
    setState(() {
      _entries.add(
        _YerEntry(
          yer: yer,
          adresController: controller,
          focusNode: FocusNode(),
        ),
      );
    });
  }
}

class _YerEntry {
  final GidilecekYerItem yer;
  final TextEditingController adresController;
  final FocusNode focusNode;

  _YerEntry({
    required this.yer,
    required this.adresController,
    required this.focusNode,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_ekle_req.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class AracTalepBenEkleScreen extends ConsumerStatefulWidget {
  final int tuId;

  const AracTalepBenEkleScreen({super.key, required this.tuId});

  @override
  ConsumerState<AracTalepBenEkleScreen> createState() =>
      _AracTalepBenEkleScreenState();
}

class _AracTalepBenEkleScreenState
    extends ConsumerState<AracTalepBenEkleScreen> {
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
  String? _customAracIstekNedeni;
  List<AracIstekNedeniItem> _aracIstekNedenleri = [];
  // Yolcu (personel) seçimi için durum
  final Set<int> _selectedGorevYeriIds = {};
  final Set<int> _selectedGorevIds = {};
  final Set<int> _selectedPersonelIds = {};
  List<GorevYeriItem> _gorevYerleri = [];
  List<GorevItem> _gorevler = [];
  List<PersonelItem> _personeller = [];
  bool _personelSheetLoading = false;
  String? _personelSheetError;
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
  List<String> _kulupList = [];
  List<String> _takimList = [];
  List<FilterOgrenciItem> _ogrenciList = [];
  bool _ogrenciSheetLoading = false;
  String? _ogrenciSheetError;
  bool _isMEB = false;

  @override
  void dispose() {
    _mesafeController.dispose();
    _customAracIstekNedeniController.dispose();
    _aciklamaController.dispose();
    for (final entry in _entries) {
      entry.adresController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mesafeController = TextEditingController(text: _tahminiMesafe.toString());
    _customAracIstekNedeniController = TextEditingController();
    _aciklamaController = TextEditingController();
    _gidilecekTarih = DateTime.now();
    _syncDonusWithGidis(startHour: _gidisSaat, startMinute: _gidisDakika);
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
              'Tahmini Mesafe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gidilecek yere navigasyondan bakarak tahmini kaç kilometre mesafe olduğunu yazınız.',
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
                style: TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          '$aracTuru Araç Talebi',
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gidilecek Yer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                  ),
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: ElevatedButton.icon(
                      onPressed: _openYerSecimiBottomSheet,
                      icon: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 27,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Yer Ekle',
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_entries.isEmpty)
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Henüz yer eklenmedi.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  )
                else
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    color: Colors.white,
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
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFF707070),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _entries[index].adresController
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
                                        controller: entry.adresController,
                                        decoration: InputDecoration(
                                          hintText: 'Semt ve adres giriniz',
                                          prefixIcon: const Icon(
                                            Icons.location_on_outlined,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
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
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahmini Mesafe (km)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _tahminiMesafe > 1
                              ? () => _updateMesafe(_tahminiMesafe - 1)
                              : null,
                          child: Container(
                            width: 50,
                            height: 46,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: _tahminiMesafe > 1
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 64,
                          height: 46,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: TextField(
                            controller: _mesafeController,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(bottom: 9),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) return;
                              final intValue = int.tryParse(value);
                              if (intValue == null) return;
                              if (intValue < 1) {
                                _updateMesafe(1);
                              } else if (intValue > 9999) {
                                _updateMesafe(9999);
                              } else {
                                _updateMesafe(intValue);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _tahminiMesafe < 9999
                              ? () => _updateMesafe(_tahminiMesafe + 1)
                              : null,
                          child: Container(
                            width: 50,
                            height: 46,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.add,
                              color: _tahminiMesafe < 9999
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _showMesafeInfo,
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // MEB Toggle
                Row(
                  children: [
                    Switch(
                      value: _isMEB,
                      activeTrackColor: AppColors.gradientStart.withValues(
                        alpha: 0.5,
                      ),
                      activeThumbColor: AppColors.gradientEnd,
                      onChanged: (value) {
                        setState(() {
                          _isMEB = value;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text('MEB', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: DatePickerBottomSheetWidget(
                        label: 'Gidilecek Tarih',
                        labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: (Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.fontSize ??
                                      14) +
                                  1,
                            ),
                        initialDate: _gidilecekTarih,
                        minDate: DateTime.now(),
                        maxDate: DateTime.now().add(const Duration(days: 365)),
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
                        labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: (Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.fontSize ??
                                      14) +
                                  1,
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
                              'donus-${_gidisSaat}-${_gidisDakika}-${_donusSaat}-${_donusDakika}',
                            ),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: (Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.fontSize ??
                                          14) +
                                      1,
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
                const SizedBox(height: 32),
                Text(
                  'Araç İstek Nedeni',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
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
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
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
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade600),
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
                        controller: _customAracIstekNedeniController,
                        onChanged: (value) {
                          setState(() {
                            _customAracIstekNedeni = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Araç istek nedenini giriniz',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
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
                AciklamaFieldWidget(controller: _aciklamaController),

                const SizedBox(height: 32),
                Text(
                  'Yolcu Seçimi',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _openPersonelSecimBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _buildPersonelSummary(),
                            style: TextStyle(
                              color: _selectedPersonelIds.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: _selectedPersonelIds.isNotEmpty
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ),
                if (_selectedPersonelIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: TextButton(
                        onPressed: _openSecilenPersonelListesiBottomSheet,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          'Seçilen personelleri listele',
                          style: TextStyle(
                            color: AppColors.gradientStart,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _ogrenciSheetLoading ? null : _openOgrenciSecimBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
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
                                  ? Colors.black
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gradientStart,
                            ),
                          )
                        else
                          Icon(Icons.chevron_right, color: Colors.grey.shade600),
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
                        child: Text(
                          'Seçilen öğrencileri listele',
                          style: TextStyle(
                            color: AppColors.gradientStart,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Text(
                  'Toplam yolcu sayısı: ${_selectedPersonelIds.length + _selectedOgrenciIds.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
                      onPressed: _submitForm,
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

  void _submitForm() {
    // Basit validasyonlar
    if (_entries.isEmpty) {
      _showStatusBottomSheet(
        'Lütfen en az 1 gidilecek yer ekleyiniz',
        isError: true,
      );
      return;
    }
    if (_gidilecekTarih == null) {
      _showStatusBottomSheet('Lütfen gidilecek tarihi seçiniz', isError: true);
      return;
    }
    if (_selectedAracIstekNedeniId == null) {
      _showStatusBottomSheet(
        'Lütfen araç istek nedenini seçiniz',
        isError: true,
      );
      return;
    }
    if (_selectedAracIstekNedeniId == -1 &&
        (_customAracIstekNedeniController.text.trim().isEmpty)) {
      _showStatusBottomSheet(
        'Lütfen diğer istek nedenini giriniz',
        isError: true,
      );
      return;
    }

    // Açıklama minimum 30 karakter kontrolü (izin istek ekranlarıyla aynı)
    if (_aciklamaController.text.length < 30) {
      _showStatusBottomSheet(
        'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
        isError: true,
      );
      return;
    }

    final yolcuSayisi =
        _selectedPersonelIds.length + _selectedOgrenciIds.length;
    if (yolcuSayisi <= 0) {
      _showStatusBottomSheet('Lütfen en az 1 yolcu seçiniz', isError: true);
      return;
    }

    for (final entry in _entries) {
      if (!entry.yer.yerAdi.contains('Eyüboğlu') &&
          entry.adresController.text.trim().isEmpty) {
        _showStatusBottomSheet(
          'Lütfen yer için semt/adres giriniz',
          isError: true,
        );
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
      onSuccess: () {
        if (!mounted) return;
        _showStatusBottomSheet('Araç talebi gönderildi', isError: false);
      },
      onError: (error) {
        if (!mounted) return;
        _showStatusBottomSheet(
          error.isEmpty ? 'Hata oluştu' : error,
          isError: true,
        );
      },
    );
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext statusContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 64,
                color: isError ? Colors.red : Colors.green,
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

                  // Başarı durumunda Araç Taleplerini Yönet ekranına git
                  if (!isError) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        // Provider'ları yenile
                        ref.refresh(aracDevamEdenTaleplerProvider);
                        ref.refresh(aracTamamlananTaleplerProvider);

                        // Tüm önceki ekranları temizleyip doğrudan Araç Taleplerini Yönet'e git
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            context.go('/arac_istek');
                          }
                        });
                      }
                    });
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
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
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

  String _buildSelectedPersonelSummaryForOzet() {
    if (_selectedPersonelIds.isEmpty) return '-';
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

    final selectedPersonel = _personeller
        .where((p) => _selectedPersonelIds.contains(p.personelId))
        .toList();
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
      yolcuSayisi: _selectedPersonelIds.length + _selectedOgrenciIds.length,
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
        throw Exception('Araç talebi gönderilemedi: $message');
      case Loading():
        throw Exception('Yükleniyor');
    }
  }

  String _buildPersonelSummary() {
    if (_selectedPersonelIds.isEmpty) {
      return 'Personel seçiniz';
    }

    final selectedNames = _personeller
        .where((p) => _selectedPersonelIds.contains(p.personelId))
        .map((p) => '${p.adi} ${p.soyadi}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (selectedNames.isEmpty) {
      return '${_selectedPersonelIds.length} personel seçildi';
    }
    if (selectedNames.length <= 2) {
      return selectedNames.join(', ');
    }
    return '${selectedNames.length} personel seçildi';
  }

  String _buildOgrenciSummary() {
    if (_selectedOgrenciIds.isEmpty) {
      return 'Öğrenci seçiniz';
    }

    // _ogrenciList içinde aynı numara birden fazla kez gelebiliyor.
    // Sayımı her zaman seçili Set üzerinden (unique numara) yap.
    if (_selectedOgrenciIds.length > 2) {
      return '${_selectedOgrenciIds.length} öğrenci seçildi';
    }

    final Map<String, String> numaraToName = {};
    for (final o in _ogrenciList) {
      final numara = '${o.numara}';
      if (!_selectedOgrenciIds.contains(numara)) continue;
      numaraToName.putIfAbsent(numara, () => '${o.adi} ${o.soyadi}'.trim());
    }

    final names = numaraToName.values.where((n) => n.isNotEmpty).toList();
    if (names.length == _selectedOgrenciIds.length && names.length <= 2) {
      return names.join(', ');
    }

    return '${_selectedOgrenciIds.length} öğrenci seçildi';
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

  String _summaryForGorevYeri(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    final names = _gorevYerleri
        .where((g) => ids.contains(g.id))
        .map((g) => g.gorevYeriAdi)
        .toList();
    if (names.isEmpty) return '${ids.length} görev yeri seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} görev yeri seçildi';
  }

  String _summaryForGorev(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    final names = _gorevler
        .where((g) => ids.contains(g.id))
        .map((g) => g.gorevAdi)
        .toList();
    if (names.isEmpty) return '${ids.length} görev türü seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} görev türü seçildi';
  }

  String _summaryForPersonel(Set<int> ids) {
    if (ids.isEmpty) return 'Seçiniz';
    final names = _personeller
        .where((p) => ids.contains(p.personelId))
        .map((p) => '${p.adi} ${p.soyadi}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return '${ids.length} personel seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} personel seçildi';
  }

  String _getFilterTitle(String key) {
    switch (key) {
      case 'gorevYeri':
        return 'Görev Yeri';
      case 'gorev':
        return 'Görev';
      case 'personel':
        return 'Personel';
      default:
        return 'Filtre';
    }
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF014B92),
            ),
            child: const Text('Temizle', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF014B92),
            ),
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
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
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
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                             fontSize: 14,
                             color: Colors.grey.shade600,
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

    return showModalBottomSheet<void>(
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
                color: Colors.white,
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
    );
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

  Future<void> _openSecilenPersonelListesiBottomSheet() async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                              'Seçilen Kişiler',
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
                                      'Tüm seçilen kişiler listeden çıkarılacaktır. Emin misiniz?',
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
                                            _selectedPersonelIds.clear();
                                          });
                                          setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Evet',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Tümünü Sil',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _selectedPersonelIds.length,
                            itemBuilder: (context, index) {
                              final personelId = _selectedPersonelIds.elementAt(
                                index,
                              );
                              final personel = _personeller.firstWhere(
                                (p) => p.personelId == personelId,
                                orElse: () => PersonelItem(
                                  personelId: -1,
                                  adi: 'Bilinmeyen',
                                  soyadi: 'Kişi',
                                  gorevId: null,
                                  gorevYeriId: null,
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
                                        '${personel.adi} ${personel.soyadi}'
                                            .trim(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey[600],
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        setModalState(() {
                                          _selectedPersonelIds.remove(
                                            personelId,
                                          );
                                        });
                                        setState(() {});
                                        if (_selectedPersonelIds.isEmpty) {
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
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openSecilenOgrenciListesiBottomSheet() async {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
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
                              'Seçilen Öğrenciler',
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
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'Evet',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Tümünü Sil',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _selectedOgrenciIds.length,
                            itemBuilder: (context, index) {
                              final ogrenciNumara = _selectedOgrenciIds
                                  .elementAt(index);
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
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.grey[600],
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
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _openPersonelSecimBottomSheet() async {
    if (_personelSheetLoading) return;
    setState(() {
      _personelSheetLoading = true;
      _personelSheetError = null;
    });

    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.personelSecimVerisiGetir();

    switch (result) {
      case Success(:final data):
        setState(() {
          _personeller = data.personeller;
          _gorevler = data.gorevler;
          _gorevYerleri = data.gorevYerleri;
          _personelSheetLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _personelSheetLoading = false;
          _personelSheetError = message;
        });
        if (mounted) {
          _showStatusBottomSheet(message, isError: true);
        }
        return;
      case Loading():
        return;
    }

    final localSelectedGorevYeri = {..._selectedGorevYeriIds};
    final localSelectedGorev = {..._selectedGorevIds};
    final localSelectedPersonel = {..._selectedPersonelIds};
    _currentFilterPage = '';

    if (!mounted) return;

    showModalBottomSheet(
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
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterMainItem(
                    title: 'Görev Yeri',
                    selectedValue: _summaryForGorevYeri(localSelectedGorevYeri),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'gorevYeri'),
                  ),
                  _buildFilterMainItem(
                    title: 'Görev',
                    selectedValue: _summaryForGorev(localSelectedGorev),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'gorev'),
                  ),
                  _buildFilterMainItem(
                    title: 'Personel',
                    selectedValue: _summaryForPersonel(localSelectedPersonel),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'personel'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 25,
                    ),
                    child: Text(
                      'Seçilen yolcu sayısı: ${localSelectedPersonel.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: localSelectedPersonel.isEmpty
                            ? const Color(0xFFD32F2F)
                            : AppColors.gradientStart,
                      ),
                    ),
                  ),
                ],
              );
            }

            Widget buildDetail() {
              switch (_currentFilterPage) {
                case 'gorevYeri':
                  return _buildGorevYeriFilterPage(
                    setModalState,
                    localSelectedGorevYeri,
                    localSelectedGorev,
                    localSelectedPersonel,
                  );
                case 'gorev':
                  return _buildGorevFilterPage(
                    setModalState,
                    localSelectedGorev,
                    localSelectedGorevYeri,
                    localSelectedPersonel,
                  );
                case 'personel':
                default:
                  return _buildPersonelFilterPage(
                    setModalState,
                    localSelectedPersonel,
                    localSelectedGorev,
                    localSelectedGorevYeri,
                  );
              }
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentFilterPage.isNotEmpty)
                              Expanded(
                                flex: 0,
                                child: InkWell(
                                  onTap: () => setModalState(
                                    () => _currentFilterPage = '',
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Geri',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 64),
                            const Spacer(),
                            Text(
                              _currentFilterPage.isEmpty
                                  ? 'Filtrele'
                                  : _getFilterTitle(_currentFilterPage),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 64),
                          ],
                        ),
                      ),
                      const Divider(),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: _currentFilterPage.isEmpty
                            ? buildMain()
                            : buildDetail(),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 16,
                  right: 16,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentFilterPage.isEmpty) {
                          // Ana sayfadayız, seçimleri kaydet ve kapat
                          setState(() {
                            _selectedGorevYeriIds
                              ..clear()
                              ..addAll(localSelectedGorevYeri);
                            _selectedGorevIds
                              ..clear()
                              ..addAll(localSelectedGorev);
                            _selectedPersonelIds
                              ..clear()
                              ..addAll(localSelectedPersonel);
                          });
                          Navigator.pop(context);
                        } else {
                          // Detay sayfasındayız, ana sayfaya dön
                          setModalState(() => _currentFilterPage = '');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014B92),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentFilterPage.isEmpty ? 'Uygula' : 'Tamam',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
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
  }

  Future<void> _openOgrenciSecimBottomSheet() async {
    setState(() {
      _ogrenciSheetLoading = true;
      _ogrenciSheetError = null;
    });

    final repo = ref.read(aracTalepRepositoryProvider);
    final result = await repo.ogrenciFiltrele();

    switch (result) {
      case Success(:final data):
        setState(() {
          _initialOkulKoduList = data.okulKodu;
          _initialSeviyeList = data.seviye;
          _initialSinifList = data.sinif;
          _okulKoduList = _initialOkulKoduList;
          _seviyeList = _initialSeviyeList;
          _sinifList = _initialSinifList;
          _kulupList = data.kulup;
          _takimList = data.takim;
          _ogrenciList = data.ogrenci;
          _ogrenciSheetLoading = false;
        });
      case Failure(:final message):
        setState(() {
          _ogrenciSheetLoading = false;
          _ogrenciSheetError = message;
        });
        if (mounted) {
          _showStatusBottomSheet(message, isError: true);
        }
        return;
      case Loading():
        return;
    }

    // State'ten mevcut seçimleri yükle
    final localSelectedOkul = {..._selectedOkulKodu};
    final localSelectedSeviye = {..._selectedSeviye};
    final localSelectedSinif = {..._selectedSinif};
    final localSelectedKulup = {..._selectedKulup};
    final localSelectedTakim = {..._selectedTakim};
    final localSelectedOgrenci = {..._selectedOgrenciIds};

    // Temp set for detail pages (Discard logic)
    final Set<String> tempSelectedItems = {};
    
    
    // Initial hierarchical refresh
    await _refreshOgrenciFilterData(
      localSelectedOkul: localSelectedOkul,
      localSelectedSeviye: localSelectedSeviye,
      localSelectedSinif: localSelectedSinif,
      localSelectedKulup: localSelectedKulup,
      localSelectedTakim: localSelectedTakim,
      localSelectedOgrenci: localSelectedOgrenci,
      rebuild: setState,
      updateSeviyeList: true,
      updateSinifList: true,
      updateKulupList: true,
      updateTakimList: true,
      // updateOgrenciList: true // Maybe initial load is enough? 
      // Actually we should refresh student list too to be consistent with filters
      updateOgrenciList: true, 
    );
    
    _currentFilterPage = '';

    if (!mounted) return;

    showModalBottomSheet(
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
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  _buildFilterMainItem(
                    title: 'Okul',
                    selectedValue: _summaryForOkul(localSelectedOkul),
                    onTap: () {
                      tempSelectedItems.clear();
                      tempSelectedItems.addAll(localSelectedOkul);
                      setModalState(() => _currentFilterPage = 'okul');
                    },
                  ),
                  _buildFilterMainItem(
                    title: 'Seviye',
                    selectedValue: _summaryForSeviye(localSelectedSeviye),
                    onTap: () {
                       tempSelectedItems.clear();
                       tempSelectedItems.addAll(localSelectedSeviye);
                       setModalState(() => _currentFilterPage = 'seviye');
                    },
                  ),
                  _buildFilterMainItem(
                    title: 'Sınıf',
                    selectedValue: _summaryForSinif(localSelectedSinif),
                    onTap: () {
                       tempSelectedItems.clear();
                       tempSelectedItems.addAll(localSelectedSinif);
                       setModalState(() => _currentFilterPage = 'sinif');
                    },
                  ),
                  _buildFilterMainItem(
                    title: 'Kulüp',
                    selectedValue: _summaryForKulup(localSelectedKulup),
                    onTap: () {
                       tempSelectedItems.clear();
                       tempSelectedItems.addAll(localSelectedKulup);
                       setModalState(() => _currentFilterPage = 'kulup');
                    },
                  ),
                  _buildFilterMainItem(
                    title: 'Takım',
                    selectedValue: _summaryForTakim(localSelectedTakim),
                    onTap: () {
                       tempSelectedItems.clear();
                       tempSelectedItems.addAll(localSelectedTakim);
                       setModalState(() => _currentFilterPage = 'takim');
                    },
                  ),
                  _buildFilterMainItem(
                    title: 'Öğrenci',
                    selectedValue: _summaryForOgrenci(localSelectedOgrenci),
                    onTap: () {
                       tempSelectedItems.clear();
                       tempSelectedItems.addAll(localSelectedOgrenci);
                       setModalState(() => _currentFilterPage = 'ogrenci');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Seçilen öğrenci sayısı: ${localSelectedOgrenci.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: localSelectedOgrenci.isEmpty
                            ? const Color(0xFFD32F2F)
                            : AppColors.gradientStart,
                      ),
                    ),
                  ),
                ],
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
                  return _buildOgrenciFilterPage(
                    setModalState,
                    scrollController,
                    tempSelectedItems,
                  );
                default:
                  return buildMain();
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
                                Icon(Icons.arrow_back_ios, size: 20, color: AppColors.gradientStart),
                                Text(
                                  'Geri', 
                                  style: TextStyle(fontSize: 16, color: AppColors.gradientStart)
                                ),
                              ],
                            ),
                          )
                        else 
                          const Text(
                            'Filtrele',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      const Spacer(),
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
                            foregroundColor: const Color(0xFF014B92),
                          ),
                          child: const Text('Tüm filtreleri temizle'),
                        ),
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
                              // Filtre seçimlerini state'e kaydet
                              _selectedOkulKodu
                                ..clear()
                                ..addAll(localSelectedOkul);
                              _selectedSeviye
                                ..clear()
                                ..addAll(localSelectedSeviye);
                              _selectedSinif
                                ..clear()
                                ..addAll(localSelectedSinif);
                              _selectedKulup
                                ..clear()
                                ..addAll(localSelectedKulup);
                              _selectedTakim
                                ..clear()
                                ..addAll(localSelectedTakim);
                              // Öğrenci seçimini kaydet
                              _selectedOgrenciIds
                                ..clear()
                                ..addAll(localSelectedOgrenci);
                            });
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
                              final updateSeviye = _currentFilterPage == 'okul';
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
                                setModalState((){});
                            }

                            setModalState(() {
                                _currentFilterPage = '';
                                tempSelectedItems.clear(); // cleanup
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF014B92),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentFilterPage.isEmpty ? 'Uygula' : 'Tamam',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
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
    
    // 1. Update Seviye (Depends ONLY on School)
    if (updateSeviyeList) {
      final resp = await _fetchOgrenciFilters(
        localSelectedOkul,
        {}, // No Level
        {}, // No Class
        {}, // No Club
        {}, // No Team
      );
      if (resp != null) {
        rebuild(() {
          _seviyeList = resp.seviye;
          localSelectedSeviye.retainAll(_seviyeList.toSet());
        });
      }
    }

    // 2. Update Class (Depends on School AND Level)
    if (updateSinifList) {
      final resp = await _fetchOgrenciFilters(
        localSelectedOkul,
        localSelectedSeviye,
        {}, // No Class
        {}, // No Club
        {}, // No Team
      );
      if (resp != null) {
        rebuild(() {
          _sinifList = resp.sinif;
          localSelectedSinif.retainAll(_sinifList.toSet());
        });
      }
    }

    // 3. Update Club (Depends on School AND Level AND Class)
    // Note: User requirement says Club filter affects Student list but
    // Club selection itself depends on School/Level/Class? 
    // "kulüp seçimi okul, seviye ve sınıf başlıklarının filtresini etkilemeyecek" => This means Upstream doesn't change.
    // But does Club list *content* depend on S/L/C? Usually yes.
    // The requirement "hiyerarşi: ... siniflar, kulupler, takimlar" implies Club list is filtered by class.
    if (updateKulupList) {
      final resp = await _fetchOgrenciFilters(
        localSelectedOkul,
        localSelectedSeviye,
        localSelectedSinif,
        {}, // No Club
        {}, // No Team
      );
      if (resp != null) {
        rebuild(() {
          _kulupList = resp.kulup;
          localSelectedKulup.retainAll(_kulupList.toSet());
        });
      }
    }

    // 4. Update Team (Depends on School AND Level AND Class AND Club)
    if (updateTakimList) {
      final resp = await _fetchOgrenciFilters(
        localSelectedOkul,
        localSelectedSeviye,
        localSelectedSinif,
        localSelectedKulup,
        {}, // No Team
      );
      if (resp != null) {
        rebuild(() {
          _takimList = resp.takim;
          localSelectedTakim.retainAll(_takimList.toSet());
        });
      }
    }

    // 5. Update Student List (Depends on ALL)
    if (updateOgrenciList) {
      final resp = await _fetchOgrenciFilters(
        localSelectedOkul,
        localSelectedSeviye,
        localSelectedSinif,
        localSelectedKulup,
        localSelectedTakim,
      );
      if (resp != null) {
        rebuild(() {
          _ogrenciList = resp.ogrenci;
          
          final validOgrenciNums = _ogrenciList.map((o) => '${o.numara}').toSet();
          
          // Check if all filters are empty (meaning "All" in API terms)
          final bool filtersEmpty = localSelectedOkul.isEmpty &&
              localSelectedSeviye.isEmpty &&
              localSelectedSinif.isEmpty &&
              localSelectedKulup.isEmpty &&
              localSelectedTakim.isEmpty;

          if (autoSelectAllOgrenci) {
            if (filtersEmpty) {
               // If filters are empty, we don't want to auto-select ALL students in the database.
               localSelectedOgrenci.clear();
            } else {
               localSelectedOgrenci
                ..clear()
                ..addAll(validOgrenciNums);
            }
          } else {
             localSelectedOgrenci.retainAll(validOgrenciNums);
          }
        });
      }
    }
  }

  Widget _buildGorevYeriFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedGorevYeri,
    Set<int> localSelectedGorev,
    Set<int> localSelectedPersonel,
  ) {
    if (_gorevYerleri.isEmpty) {
      return const Center(child: Text('Görev yeri verisi bulunamadı'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () => setModalState(() {
            localSelectedGorevYeri.clear();
            _syncPersonelSelectionFromFilters(
              selectedGorevYeri: localSelectedGorevYeri,
              selectedGorev: localSelectedGorev,
              selectedPersonel: localSelectedPersonel,
            );
          }),
          onSelectAll: () {
            setModalState(() {
              localSelectedGorevYeri
                ..clear()
                ..addAll(_gorevYerleri.map((g) => g.id));
              _syncPersonelSelectionFromFilters(
                selectedGorevYeri: localSelectedGorevYeri,
                selectedGorev: localSelectedGorev,
                selectedPersonel: localSelectedPersonel,
              );
            });
          },
        ),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: _gorevYerleri.map((yer) {
              final isSelected = localSelectedGorevYeri.contains(yer.id);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedGorevYeri.add(yer.id);
                    } else {
                      localSelectedGorevYeri.remove(yer.id);
                    }
                    _syncPersonelSelectionFromFilters(
                      selectedGorevYeri: localSelectedGorevYeri,
                      selectedGorev: localSelectedGorev,
                      selectedPersonel: localSelectedPersonel,
                    );
                  });
                },
                title: Text(
                  yer.gorevYeriAdi,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                activeColor: const Color(0xFF014B92),
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGorevFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedGorev,
    Set<int> localSelectedGorevYeri,
    Set<int> localSelectedPersonel,
  ) {
    if (_gorevler.isEmpty) {
      return const Center(child: Text('Görev verisi bulunamadı'));
    }

    final Set<int> allowedGorevIdsByPersonel = localSelectedGorevYeri.isEmpty
        ? {}
        : _personeller
              .where(
                (p) => localSelectedGorevYeri.contains((p.gorevYeriId ?? -1)),
              )
              .map((p) => p.gorevId)
              .whereType<int>()
              .where((id) => id >= 0)
              .toSet();

    final filteredGorevler = _gorevler.where((gorev) {
      if (localSelectedGorevYeri.isEmpty) return true;

      final gyId = gorev.gorevYeriId ?? -1;
      final matchByYeri = gyId >= 0 && localSelectedGorevYeri.contains(gyId);
      final matchByPersonel = allowedGorevIdsByPersonel.contains(gorev.id);
      return matchByYeri || matchByPersonel;
    }).toList();

    if (filteredGorevler.isEmpty) {
      return const Center(
        child: Text('Seçilen görev yerine ait görev bulunamadı'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () => setModalState(() {
            localSelectedGorev.clear();
            _syncPersonelSelectionFromFilters(
              selectedGorevYeri: localSelectedGorevYeri,
              selectedGorev: localSelectedGorev,
              selectedPersonel: localSelectedPersonel,
            );
          }),
          onSelectAll: () {
            setModalState(() {
              localSelectedGorev
                ..clear()
                ..addAll(filteredGorevler.map((g) => g.id));
              _syncPersonelSelectionFromFilters(
                selectedGorevYeri: localSelectedGorevYeri,
                selectedGorev: localSelectedGorev,
                selectedPersonel: localSelectedPersonel,
              );
            });
          },
        ),
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: filteredGorevler.map((gorev) {
              final isSelected = localSelectedGorev.contains(gorev.id);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedGorev.add(gorev.id);
                    } else {
                      localSelectedGorev.remove(gorev.id);
                    }
                    _syncPersonelSelectionFromFilters(
                      selectedGorevYeri: localSelectedGorevYeri,
                      selectedGorev: localSelectedGorev,
                      selectedPersonel: localSelectedPersonel,
                    );
                  });
                },
                title: Text(
                  gorev.gorevAdi,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                activeColor: const Color(0xFF014B92),
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _syncPersonelSelectionFromFilters({
    required Set<int> selectedGorevYeri,
    required Set<int> selectedGorev,
    required Set<int> selectedPersonel,
  }) {
    final hasGorevYeri = selectedGorevYeri.isNotEmpty;
    final hasGorev = selectedGorev.isNotEmpty;

    if (!hasGorevYeri && !hasGorev) {
      selectedPersonel.clear();
      return;
    }

    final personelIds = _personeller
        .where((p) {
          final gorevYeriId = p.gorevYeriId ?? -1;
          final gorevId = p.gorevId ?? -1;

          final matchGorevYeri =
              !hasGorevYeri || selectedGorevYeri.contains(gorevYeriId);
          final matchGorev = !hasGorev || selectedGorev.contains(gorevId);

          return matchGorevYeri && matchGorev;
        })
        .map((p) => p.personelId)
        .toSet();

    selectedPersonel
      ..clear()
      ..addAll(personelIds);
  }

  Widget _buildPersonelFilterPage(
    StateSetter setModalState,
    Set<int> localSelectedPersonel,
    Set<int> localSelectedGorev,
    Set<int> localSelectedGorevYeri,
  ) {
    final searchController = TextEditingController();
    String searchQuery = '';

    List<PersonelItem> applyFilters() {
      return _personeller.where((p) {
        final matchGorev =
            localSelectedGorev.isEmpty ||
            localSelectedGorev.contains(p.gorevId ?? -1);
        final matchGorevYeri =
            localSelectedGorevYeri.isEmpty ||
            localSelectedGorevYeri.contains(p.gorevYeriId ?? -1);
        final fullName = '${p.adi} ${p.soyadi}'.toLowerCase();
        final matchSearch =
            searchQuery.isEmpty || fullName.contains(searchQuery.toLowerCase());
        return matchGorev && matchGorevYeri && matchSearch;
      }).toList();
    }

    if (_personeller.isEmpty) {
      return const Center(child: Text('Personel verisi bulunamadı'));
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        final filtered = applyFilters();
        // Seçilmiş ve filtrelemeye uyan personelleri göster
        final selectedAndFiltered = filtered
            .where((p) => localSelectedPersonel.contains(p.personelId))
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Personel ara...',
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Seçilmiş: ${selectedAndFiltered.length} / ${filtered.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF014B92),
                    ),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setModalState(() => localSelectedPersonel.clear());
                        innerSetState(() {});
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF014B92),
                      ),
                      child: const Text(
                        'Temizle',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          localSelectedPersonel
                            ..clear()
                            ..addAll(filtered.map((p) => p.personelId));
                        });
                        innerSetState(() {});
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF014B92),
                      ),
                      child: const Text('Tümü', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ],
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
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final kisi = filtered[index];
                    final isSelected = localSelectedPersonel.contains(
                      kisi.personelId,
                    );
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            localSelectedPersonel.add(kisi.personelId);
                          } else {
                            localSelectedPersonel.remove(kisi.personelId);
                          }
                        });
                        innerSetState(() {});
                      },
                      title: Text(
                        '${kisi.adi} ${kisi.soyadi}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final okul = filtered[index];
                    final isSelected = localSelectedOkul.contains(okul);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedOkul.add(okul);
                          } else {
                            localSelectedOkul.remove(okul);
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
                      title: Text(
                        okul,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final seviye = filtered[index];
                    final isSelected = localSelectedSeviye.contains(seviye);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedSeviye.add(seviye);
                          } else {
                            localSelectedSeviye.remove(seviye);
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
                      title: Text(
                        seviye,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final sinif = filtered[index];
                    final isSelected = localSelectedSinif.contains(sinif);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedSinif.add(sinif);
                          } else {
                            localSelectedSinif.remove(sinif);
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
                      title: Text(
                        sinif,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final kulup = filtered[index];
                    final isSelected = localSelectedKulup.contains(kulup);
                    return CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      onChanged: (val) {
                        innerSetState(() {
                          if (val == true) {
                            localSelectedKulup.add(kulup);
                          } else {
                            localSelectedKulup.remove(kulup);
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
                      title: Text(
                        kulup,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
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
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                child: ListView.builder(
                  controller: scrollController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
                  itemCount: filtered.length,
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
                          color: Colors.black87,
                        ),
                      ),
                      activeColor: const Color(0xFF014B92),
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
                color: Colors.white,
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
                                      onTap: () => Navigator.pop(context, item),
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
      _entries.add(_YerEntry(yer: yer, adresController: controller));
    });
  }
}

class _YerEntry {
  final GidilecekYerItem yer;
  final TextEditingController adresController;

  _YerEntry({required this.yer, required this.adresController});
}

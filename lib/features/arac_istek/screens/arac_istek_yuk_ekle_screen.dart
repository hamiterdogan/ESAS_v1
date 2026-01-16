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
import 'package:esas_v1/features/arac_istek/widgets/yer_ekle_button.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';

class AracIstekYukEkleScreen extends ConsumerStatefulWidget {
  final int tuId;

  const AracIstekYukEkleScreen({super.key, required this.tuId});

  @override
  ConsumerState<AracIstekYukEkleScreen> createState() =>
      _AracIstekYukEkleScreenState();
}

class _AracIstekYukEkleScreenState
    extends ConsumerState<AracIstekYukEkleScreen> {
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
  late TextEditingController _tasInacakYukController;
  late TextEditingController _aciklamaController;
  final _tasInacakYukFocusNode = FocusNode();
  final _aciklamaFocusNode = FocusNode();
  int _tahminiMesafe = 1;
  DateTime? _gidilecekTarih;
  int _gidisSaat = 8;
  int _gidisDakika = 0;
  int _donusSaat = 9;
  int _donusDakika = 0;

  late final int _initialTahminiMesafe;
  late final DateTime _initialGidilecekTarih;
  late final int _initialGidisSaat;
  late final int _initialGidisDakika;
  late final int _initialDonusSaat;
  late final int _initialDonusDakika;

  @override
  void dispose() {
    _mesafeController.dispose();
    _tasInacakYukController.dispose();
    _aciklamaController.dispose();
    for (final entry in _entries) {
      entry.adresController.dispose();
    }
    _tasInacakYukFocusNode.dispose();
    _aciklamaFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mesafeController = TextEditingController(text: _tahminiMesafe.toString());
    _tasInacakYukController = TextEditingController();
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
    if (_tasInacakYukController.text.trim().isNotEmpty) return true;
    if (_aciklamaController.text.trim().isNotEmpty) return true;

    return false;
  }

  Future<bool> _confirmExitIfNeeded() async {
    if (!_hasFormData()) return true;
    return AppDialogs.showFormExitConfirm(context);
  }

  Future<bool> _onWillPop() async {
    return _confirmExitIfNeeded();
  }

  void _lockAndUnfocusInputs() {
    _tasInacakYukFocusNode.canRequestFocus = false;
    _aciklamaFocusNode.canRequestFocus = false;
    FocusScope.of(context).unfocus();
  }

  void _unlockInputsAfterSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _tasInacakYukFocusNode.canRequestFocus = true;
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
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 17),
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

  String _getFormattedTitle(String aracTuru) {
    if (aracTuru == 'Yük') {
      return 'Yük Aracı İsteği';
    } else if (aracTuru == 'Minibüs') {
      return 'Minübüs İsteği';
    } else if (aracTuru == 'Otobüs') {
      return 'Otobüs İsteği';
    }
    return '$aracTuru Araç İsteği';
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
                    return const Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: BrandedLoadingIndicator(
                          size: 80,
                          strokeWidth: 6,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Yerler yüklenemedi: ${snapshot.error}'),
                    );
                  }

                  final yerler = snapshot.data ?? [];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Yer ara',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            query = value.toLowerCase();
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: yerler.length,
                          itemBuilder: (context, index) {
                            final yer = yerler[index];
                            final matches =
                                query.isEmpty ||
                                yer.yerAdi.toLowerCase().contains(query);
                            if (!matches) return const SizedBox.shrink();

                            return ListTile(
                              title: Text(yer.yerAdi),
                              onTap: () {
                                Navigator.pop(context, yer);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );

    _unlockInputsAfterSheet();
    if (selected != null) {
      _addEntry(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aracTuru = _getAracTuruName();
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
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
          ),
          elevation: 0,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gidilecek Yer Bölümü
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
                  YerEkleButton(onTap: _openYerSecimiBottomSheet),
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
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                  const SizedBox(height: 24),

                  // Taşınacak Yük
                  Text(
                    'Taşınacak Yük',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    focusNode: _tasInacakYukFocusNode,
                    controller: _tasInacakYukController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Taşınacak yükün detaylarını giriniz',
                      filled: true,
                      fillColor: AppColors.textOnPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  AciklamaFieldWidget(
                    controller: _aciklamaController,
                    focusNode: _aciklamaFocusNode,
                  ),
                  const SizedBox(height: 24),

                  // Gönder Butonu
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
      ),
    );
  }

  Future<void> _submitForm() async {
    // Form validasyonu
    if (_entries.isEmpty) {
      _showStatusBottomSheet('Lütfen gidilecek yeri seçiniz', isError: true);
      return;
    }

    if (_tasInacakYukController.text.trim().isEmpty) {
      _showStatusBottomSheet(
        'Lütfen taşınacak yük hakkında bilgi giriniz',
        isError: true,
      );
      _tasInacakYukFocusNode.requestFocus();
      return;
    }

    // Açıklama minimum 30 karakter kontrolü (Binek ekranıyla aynı)
    if (_aciklamaController.text.length < 30) {
      _showStatusBottomSheet(
        'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
        isError: true,
      );
      _aciklamaFocusNode.requestFocus();
      return;
    }

    // API request oluştur
    final req = _buildAracIstekEkleReq();
    final ozetItems = _buildAracIstekOzetItems(req);

    _lockAndUnfocusInputs();
    showAracIstekOzetBottomSheet(
      context: context,
      request: req,
      talepTipi: 'Yük',
      ozetItems: ozetItems,
      onGonder: () async {
        await _sendAracIstek(req);
      },
      onSuccess: () {
        if (!mounted) return;
        _showStatusBottomSheet('Talep başarıyla gönderildi', isError: false);
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

  Future<void> _sendAracIstek(AracIstekEkleReq req) async {
    try {
      BrandedLoadingDialog.show(context);
      final repo = ref.read(aracTalepRepositoryProvider);
      final result = await repo.aracIstekEkle(req);

      if (mounted) {
        BrandedLoadingDialog.hide(context);
        if (!mounted) return;
        switch (result) {
          case Success():
            // onSuccess callback'i çalıştır (özet ekranında tanımlanmış)
            Navigator.pop(context);
          case Failure(:final message):
            throw Exception(message);
          case Loading():
            break;
        }
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
      }
      rethrow;
    }
  }

  AracIstekEkleReq _buildAracIstekEkleReq() {
    final currentPersonelId = ref.read(currentPersonelIdProvider);
    final gidilecekTarih = _gidilecekTarih ?? DateTime.now();

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

    final aracTuru = _getAracTuruName();

    return AracIstekEkleReq(
      personelId: currentPersonelId,
      gidilecekTarih: gidilecekTarih,
      gidisSaat: _gidisSaat.toString().padLeft(2, '0'),
      gidisDakika: _gidisDakika.toString().padLeft(2, '0'),
      donusSaat: _donusSaat.toString().padLeft(2, '0'),
      donusDakika: _donusDakika.toString().padLeft(2, '0'),
      aracTuru: aracTuru,
      yolcuPersonelSatir: [],
      yolcuDepartmanId: [],
      okullarSatir: [],
      gidilecekYerSatir: gidilecekYerSatir,
      yolcuSayisi: 0,
      mesafe: _tahminiMesafe,
      istekNedeni: '',
      istekNedeniDiger: '',
      aciklama: _aciklamaController.text,
      tasinacakYuk: _tasInacakYukController.text.trim(),
      meb: false,
    );
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
        label: 'Açıklama',
        value: req.aciklama.isEmpty ? '-' : req.aciklama,
        multiLine: true,
      ),
      AracIstekOzetItem(
        label: 'Taşınacak Yük',
        value: req.tasinacakYuk.isEmpty ? '-' : req.tasinacakYuk,
        multiLine: true,
      ),
      AracIstekOzetItem(
        label: 'Gidilecek Yer(ler)',
        value: _buildGidilecekYerSummary(),
      ),
    ];

    return items;
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _buildGidilecekYerSummary() {
    if (_entries.isEmpty) {
      return '-';
    }
    return _entries
        .map((entry) {
          final yer = entry.yer.yerAdi;
          final semt = entry.adresController.text.trim();
          if (semt.isEmpty) {
            return yer;
          }
          return '$yer - $semt';
        })
        .join('\n');
  }

  void _addEntry(GidilecekYerItem yer) {
    final controller = TextEditingController();
    setState(() {
      _entries.add(_YerEntry(yer: yer, adresController: controller));
    });
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

                  // Başarı durumunda önceki ekrana dön
                  if (!isError) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        final router = GoRouter.of(context);
                        if (router.canPop()) {
                          context.pop();
                        } else {
                          context.go('/arac_istek');
                        }
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

class _YerEntry {
  final GidilecekYerItem yer;
  final TextEditingController adresController;

  _YerEntry({required this.yer, required this.adresController});
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/common/index.dart';

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
  int _tahminiMesafe = 1;
  DateTime? _gidilecekTarih;
  int _gidisSaat = 8;
  int _gidisDakika = 0;
  int _donusSaat = 9;
  int _donusDakika = 0;
  // Araç istek nedeni seçimi için durum
  int? _selectedAracIstekNedeniId;
  String? _customAracIstekNedeni;
  List<_AracIstekNedeniItem> _aracIstekNedenleri = [];
  bool _aracIstekNedeniLoading = false;
  // Yolcu (personel) seçimi için durum
  final Set<int> _selectedGorevYeriIds = {};
  final Set<int> _selectedGorevIds = {};
  final Set<int> _selectedPersonelIds = {};
  List<_GorevYeriItem> _gorevYerleri = [];
  List<_GorevItem> _gorevler = [];
  List<_PersonelItem> _personeller = [];
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
  List<String> _kulupList = [];
  List<String> _takimList = [];
  List<_FilterOgrenciItem> _ogrenciList = [];
  bool _ogrenciSheetLoading = false;
  String? _ogrenciSheetError = null;

  @override
  void dispose() {
    _mesafeController.dispose();
    _customAracIstekNedeniController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Binek Araç Talebi',
          style: TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gidilecek Yer',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
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
              FractionallySizedBox(
                widthFactor: 0.45,
                child: DatePickerBottomSheetWidget(
                  label: 'Gidilecek Tarih',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TimePickerBottomSheetWidget(
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
                  const SizedBox(width: 16),
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
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
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
              const SizedBox(height: 32),
              Text(
                'Yolcu Seçimi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
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
                onTap: _openOgrenciSecimBottomSheet,
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
    );
  }

  void _submitForm() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Araç talebi gönderildi')));
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

    final selectedNames = _ogrenciList
        .where((o) => _selectedOgrenciIds.contains('${o.numara}'))
        .map((o) => '${o.adi} ${o.soyadi}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (selectedNames.isEmpty) {
      return '${_selectedOgrenciIds.length} öğrenci seçildi';
    }
    if (selectedNames.length <= 2) {
      return selectedNames.join(', ');
    }
    return '${selectedNames.length} öğrenci seçildi';
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
      orElse: () => _AracIstekNedeniItem(id: -1, ad: ''),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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
              child: FutureBuilder<List<_AracIstekNedeniItem>>(
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

  Future<List<_AracIstekNedeniItem>> _fetchAracIstekNedenleri() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/AracIstek/AracIstekNedeniDoldur');
      final data = response.data as List<dynamic>;

      return [
        _AracIstekNedeniItem(id: -1, ad: 'DİĞER'),
        ...data
            .map(
              (e) => _AracIstekNedeniItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ];
    } catch (e) {
      throw Exception('Nedeler yüklenemedi: $e');
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
                                orElse: () => _PersonelItem(
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
                                orElse: () => _FilterOgrenciItem(
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

    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.get('/Personel/PersonelleriGetir'),
        dio.get('/TalepYonetimi/GorevDoldur'),
        dio.get('/TalepYonetimi/GorevYeriDoldur'),
      ]);

      final personelData = results[0].data as List<dynamic>;
      final gorevData = results[1].data as List<dynamic>;
      final gorevYeriData = results[2].data as List<dynamic>;

      setState(() {
        _personeller = personelData
            .map((e) => _PersonelItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _gorevler = gorevData
            .map((e) => _GorevItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _gorevYerleri = gorevYeriData
            .map((e) => _GorevYeriItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _personelSheetLoading = false;
      });
    } catch (e) {
      setState(() {
        _personelSheetLoading = false;
        _personelSheetError = 'Personel verisi alınamadı: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_personelSheetError ?? 'Hata')));
      }
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

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/TalepYonetimi/OgrenciFiltrele',
        data: {
          'okulKodu': '0',
          'seviye': '0',
          'sinif': '0',
          'kulup': '0',
          'takim': '0',
        },
      );

      final filterResponse = _OgrenciFilterResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      setState(() {
        _okulKoduList = filterResponse.okulKodu;
        _seviyeList = filterResponse.seviye;
        _sinifList = filterResponse.sinif;
        _kulupList = filterResponse.kulup;
        _takimList = filterResponse.takim;
        _ogrenciList = filterResponse.ogrenci;
        _ogrenciSheetLoading = false;
      });
    } catch (e) {
      setState(() {
        _ogrenciSheetLoading = false;
        _ogrenciSheetError = 'Öğrenci verisi alınamadı: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_ogrenciSheetError ?? 'Hata')));
      }
      return;
    }

    final localSelectedOkul = <String>{};
    final localSelectedSeviye = <String>{};
    final localSelectedSinif = <String>{};
    final localSelectedKulup = <String>{};
    final localSelectedTakim = <String>{};
    final localSelectedOgrenci = {..._selectedOgrenciIds};
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
                    title: 'Okul',
                    selectedValue: _summaryForOkul(localSelectedOkul),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'okul'),
                  ),
                  _buildFilterMainItem(
                    title: 'Seviye',
                    selectedValue: _summaryForSeviye(localSelectedSeviye),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'seviye'),
                  ),
                  _buildFilterMainItem(
                    title: 'Sınıf',
                    selectedValue: _summaryForSinif(localSelectedSinif),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'sinif'),
                  ),
                  _buildFilterMainItem(
                    title: 'Kulüp',
                    selectedValue: _summaryForKulup(localSelectedKulup),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'kulup'),
                  ),
                  _buildFilterMainItem(
                    title: 'Takım',
                    selectedValue: _summaryForTakim(localSelectedTakim),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'takim'),
                  ),
                  _buildFilterMainItem(
                    title: 'Öğrenci',
                    selectedValue: _summaryForOgrenci(localSelectedOgrenci),
                    onTap: () =>
                        setModalState(() => _currentFilterPage = 'ogrenci'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 25,
                    ),
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
                    localSelectedOkul,
                    localSelectedSeviye,
                    localSelectedSinif,
                    localSelectedKulup,
                    localSelectedTakim,
                    localSelectedOgrenci,
                  );
                case 'seviye':
                  return _buildSeviyeFilterPage(
                    setModalState,
                    localSelectedSeviye,
                    localSelectedOkul,
                    localSelectedSinif,
                    localSelectedKulup,
                    localSelectedTakim,
                    localSelectedOgrenci,
                  );
                case 'sinif':
                  return _buildSinifFilterPage(
                    setModalState,
                    localSelectedSinif,
                    localSelectedOkul,
                    localSelectedSeviye,
                    localSelectedKulup,
                    localSelectedTakim,
                    localSelectedOgrenci,
                  );
                case 'kulup':
                  return _buildKulupFilterPage(
                    setModalState,
                    localSelectedKulup,
                    localSelectedOkul,
                    localSelectedSeviye,
                    localSelectedSinif,
                    localSelectedTakim,
                    localSelectedOgrenci,
                  );
                case 'takim':
                  return _buildTakimFilterPage(
                    setModalState,
                    localSelectedTakim,
                    localSelectedOkul,
                    localSelectedSeviye,
                    localSelectedSinif,
                    localSelectedKulup,
                    localSelectedOgrenci,
                  );
                case 'ogrenci':
                  return _buildOgrenciFilterPage(
                    setModalState,
                    localSelectedOgrenci,
                  );
                default:
                  return buildMain();
              }
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: const Text(
                          'Filtrele',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                      onPressed: () async {
                        if (_currentFilterPage.isEmpty) {
                          setState(() {
                            _selectedOgrenciIds
                              ..clear()
                              ..addAll(localSelectedOgrenci);
                          });
                          Navigator.pop(context);
                        } else {
                          // Filtre seçimi yapıldığında API'ye istekte bulun
                          await _applyOgrenciFilters(
                            localSelectedOkul,
                            localSelectedSeviye,
                            localSelectedSinif,
                            localSelectedKulup,
                            localSelectedTakim,
                          );
                          // Öğrenci seçimini filtrelere göre senkronize et
                          _syncOgrenciSelectionFromFilters(
                            localSelectedOkul,
                            localSelectedSeviye,
                            localSelectedSinif,
                            localSelectedKulup,
                            localSelectedTakim,
                            localSelectedOgrenci,
                          );
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
    final names = _ogrenciList
        .where((o) => ids.contains('${o.numara}'))
        .map((o) => '${o.adi} ${o.soyadi}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) return '${ids.length} öğrenci seçildi';
    if (names.length <= 2) return names.join(', ');
    return '${names.length} öğrenci seçildi';
  }

  Future<void> _applyOgrenciFilters(
    Set<String> selectedOkulKodlari,
    Set<String> selectedSeviyeler,
    Set<String> selectedSiniflar,
    Set<String> selectedKulupler,
    Set<String> selectedTakimlar,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/TalepYonetimi/MobilOgrenciFiltrele',
        data: {
          'okulKodlari': selectedOkulKodlari.isEmpty
              ? ['0']
              : selectedOkulKodlari.toList(),
          'seviyeler': selectedSeviyeler.isEmpty
              ? ['0']
              : selectedSeviyeler.toList(),
          'siniflar': selectedSiniflar.isEmpty
              ? ['0']
              : selectedSiniflar.toList(),
          'kulupler': selectedKulupler.isEmpty
              ? ['0']
              : selectedKulupler.toList(),
          'takimlar': selectedTakimlar.isEmpty
              ? ['0']
              : selectedTakimlar.toList(),
        },
      );

      final filterResponse = _OgrenciFilterResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (mounted) {
        setState(() {
          _okulKoduList = filterResponse.okulKodu;
          _seviyeList = filterResponse.seviye;
          _sinifList = filterResponse.sinif;
          _kulupList = filterResponse.kulup;
          _takimList = filterResponse.takim;
          _ogrenciList = filterResponse.ogrenci;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Filtre uygulanırken hata: $e')));
      }
    }
  }

  void _syncOgrenciSelectionFromFilters(
    Set<String> selectedOkulKodlari,
    Set<String> selectedSeviyeler,
    Set<String> selectedSiniflar,
    Set<String> selectedKulupler,
    Set<String> selectedTakimlar,
    Set<String> selectedOgrenci,
  ) {
    final hasFilters =
        selectedOkulKodlari.isNotEmpty ||
        selectedSeviyeler.isNotEmpty ||
        selectedSiniflar.isNotEmpty ||
        selectedKulupler.isNotEmpty ||
        selectedTakimlar.isNotEmpty;

    if (!hasFilters) {
      selectedOgrenci.clear();
      return;
    }

    // Filtrelere uygun öğrencileri seç
    final ogrenciNumaralari = _ogrenciList.map((o) => '${o.numara}').toSet();
    selectedOgrenci
      ..clear()
      ..addAll(ogrenciNumaralari);
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

    List<_PersonelItem> applyFilters() {
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
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedSinif,
    Set<String> localSelectedKulup,
    Set<String> localSelectedTakim,
    Set<String> localSelectedOgrenci,
  ) {
    if (_okulKoduList.isEmpty) {
      return const Center(child: Text('Okul verisi bulunamadı'));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () {
            setModalState(() {
              localSelectedOkul.clear();
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
          onSelectAll: () {
            setModalState(() {
              localSelectedOkul
                ..clear()
                ..addAll(_okulKoduList);
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
            itemCount: _okulKoduList.length,
            itemBuilder: (context, index) {
              final okul = _okulKoduList[index];
              final isSelected = localSelectedOkul.contains(okul);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedOkul.add(okul);
                    } else {
                      localSelectedOkul.remove(okul);
                    }
                    _syncOgrenciSelectionFromFilters(
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  });
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
  }

  Widget _buildSeviyeFilterPage(
    StateSetter setModalState,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () {
            setModalState(() {
              localSelectedSeviye.clear();
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
          onSelectAll: () {
            setModalState(() {
              localSelectedSeviye
                ..clear()
                ..addAll(_seviyeList);
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
            itemCount: _seviyeList.length,
            itemBuilder: (context, index) {
              final seviye = _seviyeList[index];
              final isSelected = localSelectedSeviye.contains(seviye);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedSeviye.add(seviye);
                    } else {
                      localSelectedSeviye.remove(seviye);
                    }
                    _syncOgrenciSelectionFromFilters(
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  });
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
  }

  Widget _buildSinifFilterPage(
    StateSetter setModalState,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () {
            setModalState(() {
              localSelectedSinif.clear();
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
          onSelectAll: () {
            setModalState(() {
              localSelectedSinif
                ..clear()
                ..addAll(_sinifList);
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
            itemCount: _sinifList.length,
            itemBuilder: (context, index) {
              final sinif = _sinifList[index];
              final isSelected = localSelectedSinif.contains(sinif);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedSinif.add(sinif);
                    } else {
                      localSelectedSinif.remove(sinif);
                    }
                    _syncOgrenciSelectionFromFilters(
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  });
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
  }

  Widget _buildKulupFilterPage(
    StateSetter setModalState,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () {
            setModalState(() {
              localSelectedKulup.clear();
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
          onSelectAll: () {
            setModalState(() {
              localSelectedKulup
                ..clear()
                ..addAll(_kulupList);
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
            itemCount: _kulupList.length,
            itemBuilder: (context, index) {
              final kulup = _kulupList[index];
              final isSelected = localSelectedKulup.contains(kulup);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedKulup.add(kulup);
                    } else {
                      localSelectedKulup.remove(kulup);
                    }
                    _syncOgrenciSelectionFromFilters(
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  });
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
  }

  Widget _buildTakimFilterPage(
    StateSetter setModalState,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSelectActions(
          onClear: () {
            setModalState(() {
              localSelectedTakim.clear();
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
          onSelectAll: () {
            setModalState(() {
              localSelectedTakim
                ..clear()
                ..addAll(_takimList);
              _syncOgrenciSelectionFromFilters(
                localSelectedOkul,
                localSelectedSeviye,
                localSelectedSinif,
                localSelectedKulup,
                localSelectedTakim,
                localSelectedOgrenci,
              );
            });
          },
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 0, 16),
            itemCount: _takimList.length,
            itemBuilder: (context, index) {
              final takim = _takimList[index];
              final isSelected = localSelectedTakim.contains(takim);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                onChanged: (val) {
                  setModalState(() {
                    if (val == true) {
                      localSelectedTakim.add(takim);
                    } else {
                      localSelectedTakim.remove(takim);
                    }
                    _syncOgrenciSelectionFromFilters(
                      localSelectedOkul,
                      localSelectedSeviye,
                      localSelectedSinif,
                      localSelectedKulup,
                      localSelectedTakim,
                      localSelectedOgrenci,
                    );
                  });
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
  }

  Widget _buildOgrenciFilterPage(
    StateSetter setModalState,
    Set<String> localSelectedOgrenci,
  ) {
    final searchController = TextEditingController();
    String searchQuery = '';

    List<_FilterOgrenciItem> applyFilters() {
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
                setModalState(() => localSelectedOgrenci.clear());
                innerSetState(() {});
              },
              onSelectAll: () {
                setModalState(() {
                  localSelectedOgrenci
                    ..clear()
                    ..addAll(filtered.map((o) => '${o.numara}'));
                });
                innerSetState(() {});
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
                        setModalState(() {
                          if (val == true) {
                            localSelectedOgrenci.add('${ogrenci.numara}');
                          } else {
                            localSelectedOgrenci.remove('${ogrenci.numara}');
                          }
                        });
                        innerSetState(() {});
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
    final selected = await showModalBottomSheet<_GidilecekYerItem>(
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
              child: FutureBuilder<List<_GidilecekYerItem>>(
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

  Future<List<_GidilecekYerItem>> _fetchGidilecekYerler() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/AracIstek/GidilecekYerGetir');
      final data = response.data as List<dynamic>;

      return [
        _GidilecekYerItem(id: 'diger', yerAdi: 'Diğer'),
        ...data
            .map((e) => _GidilecekYerItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ];
    } catch (e) {
      throw Exception('Yerler yüklenemedi: $e');
    }
  }

  void _addEntry(_GidilecekYerItem yer) {
    final controller = TextEditingController();
    setState(() {
      _entries.add(_YerEntry(yer: yer, adresController: controller));
    });
  }
}

class _YerEntry {
  final _GidilecekYerItem yer;
  final TextEditingController adresController;

  _YerEntry({required this.yer, required this.adresController});
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? -1;
  return -1;
}

class _GidilecekYerItem {
  final dynamic id;
  final String yerAdi;

  _GidilecekYerItem({required this.id, required this.yerAdi});

  factory _GidilecekYerItem.fromJson(Map<String, dynamic> json) {
    return _GidilecekYerItem(
      id: json['id'] ?? json['ID'] ?? -1,
      yerAdi:
          (json['yerAdi'] ?? json['YerAdi'] ?? json['ad'] ?? json['Ad'] ?? '')
              .toString(),
    );
  }
}

class _GorevYeriItem {
  final int id;
  final String gorevYeriAdi;

  _GorevYeriItem({required this.id, required this.gorevYeriAdi});

  factory _GorevYeriItem.fromJson(Map<String, dynamic> json) {
    return _GorevYeriItem(
      id: _asInt(
        json['id'] ??
            json['ID'] ??
            json['gorevYeriId'] ??
            json['GorevYeriId'] ??
            -1,
      ),
      gorevYeriAdi:
          (json['gorevYeriAdi'] ??
                  json['GorevYeriAdi'] ??
                  json['gorevYeri'] ??
                  json['GorevYeri'] ??
                  json['ad'] ??
                  json['Ad'] ??
                  '')
              .toString(),
    );
  }
}

class _GorevItem {
  final int id;
  final String gorevAdi;
  final int? gorevYeriId;

  _GorevItem({
    required this.id,
    required this.gorevAdi,
    required this.gorevYeriId,
  });

  factory _GorevItem.fromJson(Map<String, dynamic> json) {
    return _GorevItem(
      id: _asInt(json['id'] ?? json['ID'] ?? json['gorevId'] ?? -1),
      gorevAdi:
          (json['gorev'] ??
                  json['Gorev'] ??
                  json['gorevAdi'] ??
                  json['Ad'] ??
                  '')
              .toString(),
      gorevYeriId: _asInt(
        json['gorevYeriId'] ?? json['GorevYeriId'] ?? json['gorevYeriID'] ?? -1,
      ),
    );
  }
}

class _PersonelItem {
  final int personelId;
  final String adi;
  final String soyadi;
  final int? gorevId;
  final int? gorevYeriId;

  _PersonelItem({
    required this.personelId,
    required this.adi,
    required this.soyadi,
    required this.gorevId,
    required this.gorevYeriId,
  });

  factory _PersonelItem.fromJson(Map<String, dynamic> json) {
    return _PersonelItem(
      personelId: _asInt(
        json['personelId'] ?? json['PersonelId'] ?? json['id'] ?? json['ID'],
      ),
      adi: (json['adi'] ?? json['Ad'] ?? '').toString(),
      soyadi: (json['soyadi'] ?? json['Soyad'] ?? json['Soyadi'] ?? '')
          .toString(),
      gorevId: _asInt(
        json['gorevId'] ?? json['GorevId'] ?? json['gorevID'] ?? -1,
      ),
      gorevYeriId: _asInt(
        json['gorevYeriId'] ?? json['GorevYeriId'] ?? json['gorevYeriID'] ?? -1,
      ),
    );
  }
}

class _AracIstekNedeniItem {
  final dynamic id;
  final String ad;

  _AracIstekNedeniItem({required this.id, required this.ad});

  factory _AracIstekNedeniItem.fromJson(Map<String, dynamic> json) {
    return _AracIstekNedeniItem(
      id: json['id'] ?? json['ID'] ?? -1,
      ad:
          (json['istekNedeni'] ??
                  json['IstekNedeni'] ??
                  json['ad'] ??
                  json['Ad'] ??
                  json['name'] ??
                  json['Name'] ??
                  '')
              .toString(),
    );
  }
}

class _OgrenciFilterResponse {
  final List<String> okulKodu;
  final List<String> seviye;
  final List<String> sinif;
  final List<String> kulup;
  final List<String> takim;
  final List<_FilterOgrenciItem> ogrenci;

  _OgrenciFilterResponse({
    required this.okulKodu,
    required this.seviye,
    required this.sinif,
    required this.kulup,
    required this.takim,
    required this.ogrenci,
  });

  factory _OgrenciFilterResponse.fromJson(Map<String, dynamic> json) {
    return _OgrenciFilterResponse(
      okulKodu: List<String>.from(
        (json['okulKodu'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      seviye: List<String>.from(
        (json['seviye'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      sinif: List<String>.from(
        (json['sinif'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      kulup: List<String>.from(
        (json['kulup'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      takim: List<String>.from(
        (json['takim'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      ogrenci: List<_FilterOgrenciItem>.from(
        (json['ogrenci'] as List<dynamic>?)?.map(
              (e) => _FilterOgrenciItem.fromJson(e as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }
}

class _FilterOgrenciItem {
  final String okulKodu;
  final String sinif;
  final int numara;
  final String adi;
  final String soyadi;

  _FilterOgrenciItem({
    required this.okulKodu,
    required this.sinif,
    required this.numara,
    required this.adi,
    required this.soyadi,
  });

  factory _FilterOgrenciItem.fromJson(Map<String, dynamic> json) {
    return _FilterOgrenciItem(
      okulKodu: (json['okulKodu'] ?? '').toString(),
      sinif: (json['sinif'] ?? '').toString(),
      numara: _asInt(json['numara'] ?? -1),
      adi: (json['adi'] ?? '').toString(),
      soyadi: (json['soyadi'] ?? '').toString(),
    );
  }
}

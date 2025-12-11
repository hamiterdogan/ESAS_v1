import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
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
  int _tahminiMesafe = 1;
  DateTime? _gidilecekTarih;
  int _gidisSaat = 8;
  int _gidisDakika = 0;
  int _donusSaat = 9;
  int _donusDakika = 0;
  List<_IstekNedeniItem> _istekNedenleri = [];
  bool _istekNedeniLoading = false;
  String? _istekNedeniError;
  int? _selectedIstekNedeniId;
  String _selectedIstekNedeniText = '';

  @override
  void dispose() {
    _mesafeController.dispose();
    for (final entry in _entries) {
      entry.adresController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mesafeController = TextEditingController(text: _tahminiMesafe.toString());
    _gidilecekTarih = DateTime.now();
    _syncDonusWithGidis(startHour: _gidisSaat, startMinute: _gidisDakika);
  }

  void _syncDonusWithGidis({required int startHour, required int startMinute}) {
    int targetHour = startHour + 1;
    int targetMinute = startMinute;

    // Clamp to latest allowed if overflow
    if (targetHour > 23) {
      targetHour = 23;
      targetMinute = _allowedMinutes.last;
    }

    final nextConstraint = _computeDonusMin(startHour, startMinute);

    // Ensure selected return is strictly after start
    if (_isBeforeOrEqual(targetHour, targetMinute, startHour, startMinute)) {
      targetHour = nextConstraint.$1;
      targetMinute = nextConstraint.$2;
    }

    // If even target is before constraint, bump to constraint
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
    // If minute is the last allowed (55), next valid must be next hour at :00
    if (startMinute >= _allowedMinutes.last) {
      if (startHour >= 23) {
        return (23, _allowedMinutes.last);
      }
      final nextHour = (startHour + 1).clamp(0, 23);
      return (nextHour, _allowedMinutes.first);
    }

    // Same hour allowed but must be strictly greater minute
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
              ElevatedButton.icon(
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
                  backgroundColor: AppColors.gradientEnd,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
                                        entry.yer.ad,
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
                                if (!entry.yer.ad.contains('Eyüboğlu'))
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Araç İstek Nedeni',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_istekNedeniLoading)
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_istekNedeniError != null)
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          _istekNedeniError ?? 'Hata',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _openIstekNedeniBottomSheet,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedIstekNedeniText.isEmpty
                                    ? 'Nedeni Seçiniz'
                                    : _selectedIstekNedeniText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedIstekNedeniText.isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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

  Future<void> _ensureIstekNedenleriLoaded() async {
    if (_istekNedenleri.isNotEmpty) return;
    if (_istekNedeniLoading) return;

    setState(() {
      _istekNedeniLoading = true;
      _istekNedeniError = null;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://esasapi.eyuboglu.k12.tr/api/TalepYonetimi/AracIstekNedeniDoldur',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data is Map && response.data['data'] != null)
            ? response.data['data']
            : [];

        final items = data.map((item) {
          final id = item['id'] ?? item['ID'];
          final text = item['istekNedeni'] ?? item['ad'] ?? item['Ad'] ?? '';
          return _IstekNedeniItem(id: id, ad: text);
        }).toList();

        setState(() {
          _istekNedenleri = items;
          _istekNedeniLoading = false;
        });
      } else {
        setState(() {
          _istekNedeniError = 'Veri yüklenemedi';
          _istekNedeniLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _istekNedeniError = 'Hata: ${e.toString()}';
        _istekNedeniLoading = false;
      });
    }
  }

  void _submitForm() {
    // Placeholder for form submission logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Araç talebi gönderildi')));
  }

  Future<void> _openYerSecimiBottomSheet() async {
    final selected = await showModalBottomSheet<GidilecekYer>(
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
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        return FutureBuilder<List<GidilecekYer>>(
                          future: ref.read(gidilecekYerlerProvider.future),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Yerler yüklenemedi\n${snapshot.error}',
                                ),
                              );
                            }

                            final data = snapshot.data ?? [];
                            final baseList = [
                              GidilecekYer(id: 'diger', ad: 'Diğer'),
                              ...data,
                            ];

                            return StatefulBuilder(
                              builder: (context, setModalState) {
                                final filtered = baseList
                                    .where(
                                      (y) => y.ad.toLowerCase().contains(
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
                                              query = value
                                                  .trim()
                                                  .toLowerCase();
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText: 'Yer ara...',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            suffixIcon: query.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear,
                                                    ),
                                                    onPressed: () {
                                                      searchController.clear();
                                                      setModalState(() {
                                                        query = '';
                                                      });
                                                    },
                                                  )
                                                : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: filtered.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(
                                                height: 0.5,
                                                thickness: 0.5,
                                              ),
                                          itemBuilder: (context, index) {
                                            final item = filtered[index];
                                            return ListTile(
                                              title: Text(item.ad),
                                              onTap: () =>
                                                  Navigator.pop(context, item),
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
                        );
                      },
                    ),
                  ),
                ],
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

  Future<void> _openIstekNedeniBottomSheet() async {
    await _ensureIstekNedenleriLoaded();

    if (!mounted) return;

    final selected = await showModalBottomSheet<_IstekNedeniItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                String query = '';
                final searchController = TextEditingController();
                final filtered = _istekNedenleri
                    .where(
                      (item) =>
                          item.ad.toLowerCase().contains(query.toLowerCase()),
                    )
                    .toList();

                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  hintText: 'Ara',
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
                                  ),
                                ),
                                onChanged: (value) {
                                  setModalState(() {
                                    query = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 0.5, thickness: 0.5),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    title: Text(item.ad),
                                    onTap: () => Navigator.pop(context, item),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedIstekNedeniId = selected.id;
        _selectedIstekNedeniText = selected.ad;
      });
    }
  }

  void _addEntry(GidilecekYer yer) {
    final controller = TextEditingController();
    setState(() {
      _entries.add(_YerEntry(yer: yer, adresController: controller));
    });
  }
}

class _YerEntry {
  final GidilecekYer yer;
  final TextEditingController adresController;

  _YerEntry({required this.yer, required this.adresController});
}

class _IstekNedeniItem {
  final dynamic id;
  final String ad;

  _IstekNedeniItem({required this.id, required this.ad});
}

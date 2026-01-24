import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_ikram_data.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_ikram_ekle_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_ekle_req.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/widgets/yiyecek_icecek_ozet_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/common/widgets/okul_secim_widget.dart';
import 'package:esas_v1/common/widgets/validation_uyari_widget.dart';
import 'package:esas_v1/common/widgets/istek_basarili_widget.dart';
// Add this for Success/Failure checks

class YiyecekIcecekIstekScreen extends ConsumerStatefulWidget {
  const YiyecekIcecekIstekScreen({super.key});

  @override
  ConsumerState<YiyecekIcecekIstekScreen> createState() =>
      _YiyecekIcecekIstekScreenState();
}

class _YiyecekIcecekIstekScreenState
    extends ConsumerState<YiyecekIcecekIstekScreen> {
  final Set<String> _selectedBinaKodlari = <String>{};
  final TextEditingController _searchBinaController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedDonem;
  String? _selectedEtkinlik;
  final TextEditingController _customEtkinlikController =
      TextEditingController();
  final FocusNode _customEtkinlikFocusNode = FocusNode();
  final TextEditingController _ikramYeriController = TextEditingController();
  final FocusNode _ikramYeriFocusNode = FocusNode();
  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();

  // Validation Focus Nodes
  final FocusNode _donemFocusNode = FocusNode();
  final FocusNode _etkinlikFocusNode = FocusNode();
  final FocusNode _submitFocusNode = FocusNode();

  final List<YiyecekIcecekIkramData> _addedIkramlar = [];

  // Initial values for form data tracking
  late DateTime? _initialSelectedDate;
  late String? _initialSelectedDonem;
  late String? _initialSelectedEtkinlik;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initialSelectedDate = _selectedDate;
    _initialSelectedDonem = _selectedDonem;
    _initialSelectedEtkinlik = _selectedEtkinlik;
  }

  @override
  void dispose() {
    _searchBinaController.dispose();
    _customEtkinlikController.dispose();
    _customEtkinlikFocusNode.dispose();
    _ikramYeriController.dispose();
    _ikramYeriFocusNode.dispose();
    _aciklamaController.dispose();
    _aciklamaFocusNode.dispose();
    _donemFocusNode.dispose();
    _etkinlikFocusNode.dispose();
    _submitFocusNode.dispose();
    super.dispose();
  }

  void _lockAndUnfocusInputs() {
    FocusScope.of(context).unfocus();
  }

  void _unlockInputsAfterSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  void _toggleSelection(String binaKodu) {
    if (_selectedBinaKodlari.contains(binaKodu)) {
      _selectedBinaKodlari.remove(binaKodu);
    } else {
      _selectedBinaKodlari.add(binaKodu);
    }
  }

  bool _isSameDate(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasFormData() {
    // Check if any building is selected
    if (_selectedBinaKodlari.isNotEmpty) return true;
    // Check if date is different from initial
    if (!_isSameDate(_selectedDate, _initialSelectedDate)) return true;
    // Check if donem is selected
    if (_selectedDonem != null && _selectedDonem != _initialSelectedDonem)
      return true;
    // Check if etkinlik is selected
    if (_selectedEtkinlik != null &&
        _selectedEtkinlik != _initialSelectedEtkinlik)
      return true;
    // Check if custom etkinlik has text
    if (_customEtkinlikController.text.trim().isNotEmpty) return true;
    // Check if ikram yeri has text
    if (_ikramYeriController.text.trim().isNotEmpty) return true;
    // Check if aciklama has text
    if (_aciklamaController.text.trim().isNotEmpty) return true;
    // Check if any ikram items are added
    if (_addedIkramlar.isNotEmpty) return true;
    return false;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return AppDialogs.showFormExitConfirm(context);
  }

  String _buildSelectedText(List<SatinAlmaBina> binalar) {
    final selectedNames = binalar
        .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
        .map((b) => b.binaAdi)
        .toList();

    if (selectedNames.isEmpty) return 'Okul seçiniz';
    if (selectedNames.length <= 2) {
      return selectedNames.join(', ');
    }
    return '${selectedNames.length} okul seçildi';
  }

  Future<void> _showEtkinlikBottomSheet() async {
    _lockAndUnfocusInputs();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final etkinliklerAsync = ref.watch(etkinlikAdlariProvider);

              return etkinliklerAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: BrandedLoadingIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'Etkinlik listesi alınamadı',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (etkinlikler) {
                  return StatefulBuilder(
                    builder: (modalCtx, setModalState) {
                      // Bu bottom sheet için lokal bir controller kullanalım
                      // Ancak dispose edilmesine gerek yok, statefulbuilder içinde kalacak
                      // Fakat her builder call'da yeniden oluşturmamak için dışarıda bir yerde mi tutmalıyız?
                      // Hayır, StatefulBuilder her rebuild olduğunda değil, modal açıldığında çalışır.
                      // Fakat arama textini tutmak için bir degiskene ihtiyacimiz var.
                      // Bunu StatefulBuilder'in parent scope'unda tanimlayalim (yani builder callback disinda degil, icinde state olarak)
                      // Ama StatefulBuilder state tutmaz, sadece rebuild eder.
                      // En temizi yukarida bir degisken tanimlamak degil,
                      // buradaki builder'in disinda bir degisken tanimlayip (bu metot icinde),
                      // text degistikce o degiskeni guncelleyip setModalState cagirmak.

                      return _EtkinlikSearchableSheet(
                        etkinlikler: etkinlikler,
                        onSelect: (selected) {
                          setState(() {
                            _selectedEtkinlik = selected;
                            if (selected != 'Diğer') {
                              _customEtkinlikController.clear();
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
    _unlockInputsAfterSheet();
  }

  Future<void> _showDonemBottomSheet() async {
    _lockAndUnfocusInputs();
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final donemlerAsync = ref.watch(donemlerProvider);

              return donemlerAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: BrandedLoadingIndicator()),
                ),
                error: (err, stack) => SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      'Dönem listesi alınamadı',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (donemler) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Dönem Seçiniz',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...donemler.map((donem) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedDonem = donem;
                                });
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  donem,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.border,
                              indent: 16,
                              endIndent: 16,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
    _unlockInputsAfterSheet();
  }

  Future<void> _showBinaBottomSheet() async {
    _lockAndUnfocusInputs();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncBinalar = ref.watch(satinAlmaBinalarProvider);
              return asyncBinalar.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 64)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Bina listesi alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (binalar) {
                  return StatefulBuilder(
                    builder: (modalCtx, setModalState) {
                      final searchQuery = _searchBinaController.text
                          .toLowerCase();
                      final filteredBinalar = searchQuery.isEmpty
                          ? binalar
                          : binalar
                                .where(
                                  (b) => b.binaAdi.toLowerCase().contains(
                                    searchQuery,
                                  ),
                                )
                                .toList();

                      return SizedBox(
                        height: MediaQuery.of(ctx).size.height * 0.65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Okul Seçiniz',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          1,
                                      color: AppColors.inputLabelColor,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: TextField(
                                controller: _searchBinaController,
                                onChanged: (_) {
                                  setModalState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Okul adı ile ara...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon:
                                      _searchBinaController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchBinaController.clear();
                                            setModalState(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(
                                        () => _selectedBinaKodlari.clear(),
                                      );
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Temizle',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(
                                        () => _selectedBinaKodlari.addAll(
                                          filteredBinalar.map(
                                            (e) => e.binaKodu,
                                          ),
                                        ),
                                      );
                                      setModalState(() {});
                                    },
                                    child: const Text(
                                      'Tümünü seç',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: filteredBinalar.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Eşleşen okul bulunamadı',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredBinalar.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade300,
                                        indent: 20,
                                        endIndent: 20,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = filteredBinalar[index];
                                        final isSelected = _selectedBinaKodlari
                                            .contains(item.binaKodu);
                                        return OkulSecimListItem(
                                          title: item.binaAdi,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(
                                              () => _toggleSelection(
                                                item.binaKodu,
                                              ),
                                            );
                                            setModalState(() {});
                                          },
                                        );
                                      },
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gradientStart,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'Tamam',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
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
              );
            },
          ),
        );
      },
    );
    _unlockInputsAfterSheet();
  }

  Future<void> _showSelectedBinalarSheet(List<SatinAlmaBina> binalar) async {
    _lockAndUnfocusInputs();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * (2 / 3),
          child: StatefulBuilder(
            builder: (modalCtx, setModalState) {
              final currentSelectedBinalar = binalar
                  .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Seçilen Okullar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize:
                            (Theme.of(
                                  context,
                                ).textTheme.titleMedium?.fontSize ??
                                16) +
                            1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentSelectedBinalar.length,
                      itemBuilder: (context, index) {
                        final item = currentSelectedBinalar[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.binaAdi,
                            style: TextStyle(
                              fontSize:
                                  (Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.fontSize ??
                                      16) +
                                  2,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedBinaKodlari.remove(item.binaKodu);
                              });
                              setModalState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gradientStart,
                          foregroundColor: AppColors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Tamam',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ),
    );
    _unlockInputsAfterSheet();
  }

  Future<void> _validateAndSubmit() async {
    // 1. Dönem Kontrolü
    if (_selectedDonem == null) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen dönem seçiniz",
      );
      return;
    }

    // 2. Etkinlik Adı Kontrolü
    if (_selectedEtkinlik == null) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen etkinlik adını seçiniz",
      );
      return;
    }

    // 3. Etkinlik Adı "Diğer" ise input kontrolü
    if (_selectedEtkinlik == 'Diğer' &&
        _customEtkinlikController.text.trim().isEmpty) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen etkinlik adını giriniz",
      );
      return;
    }

    // 4. İkram Yapılacak Yer Kontrolü
    if (_ikramYeriController.text.trim().isEmpty) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen ikram yapılak yer bilgisi giriniz",
      );
      return;
    }

    // 5. Açıklama Kontrolü
    if (_aciklamaController.text.trim().isEmpty) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen açıklama giriniz",
      );
      return;
    }

    // 6. En az bir ikram kontrolü
    // 6. En az bir ikram kontrolü
    if (_addedIkramlar.isEmpty) {
      await ValidationUyariWidget.goster(
        context: context,
        message: "Lütfen ikram bilgisi giriniz",
      );
      if (!mounted) return;
      // İkram eklenmemişse direkt ikram ekle sayfasına yönlendir
      Navigator.push<YiyecekIcecekIkramData>(
        context,
        MaterialPageRoute(
          builder: (context) => const YiyecekIcecekIkramEkleScreen(),
        ),
      ).then((result) {
        if (result != null) {
          setState(() {
            _addedIkramlar.add(result);
          });
          // Focus on submit button and hide keyboard
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            FocusScope.of(context).unfocus(); // Ensure keyboard is gone
            if (_submitFocusNode.canRequestFocus) {
              _submitFocusNode.requestFocus();
            }
          });
        }
      });
      return;
    }

    // Validasyon başarılı, özet ekranını göster
    _showSummary();
  }

  void _showSummary() async {
    // Prepare Data
    // Map selected bina codes to IDs
    final binalar = ref.read(satinAlmaBinalarProvider).asData?.value ?? [];
    final List<int> binaIds = [];
    String binalarText = ''; // For summary text

    final selectedBinaNames = <String>[];
    for (var code in _selectedBinaKodlari) {
      final bina = binalar.firstWhere(
        (b) => b.binaKodu == code,
        orElse: () => SatinAlmaBina(id: 0, binaAdi: '', binaKodu: ''),
      );
      if (bina.id != 0) {
        binaIds.add(bina.id);
        selectedBinaNames.add(bina.binaAdi);
      }
    }
    binalarText = selectedBinaNames.join(', ');

    // Map Ikrams
    final List<IkramRequest> ikramRequests = _addedIkramlar.map((ikramData) {
      // Parse secilenIkramlar strings to booleans
      final secilen = ikramData.secilenIkramlar;
      String digerIkramStr = 'string'; // Default per example if empty

      // Check for 'Diğer: ...'
      final digerItem = secilen.firstWhere(
        (e) => e.startsWith('Diğer'),
        orElse: () => '',
      );
      if (digerItem.startsWith('Diğer: ')) {
        digerIkramStr = digerItem.substring(7);
      }

      return IkramRequest(
        cay: secilen.contains('Çay'),
        kahve: secilen.contains('Kahve'),
        mesrubat: secilen.contains('Meşrubat'),
        kasarliSimit: secilen.contains('Kaşarlı Simit'),
        kruvasan: secilen.contains('Kruvasan'),
        kurabiye: secilen.contains('Kurabiye'),
        ogleYemegi: secilen.contains('Öğle Yemeği'),
        kokteyl: secilen.contains('Kokteyl'),
        aksamYemegi: secilen.contains('Akşam Yemeği'),
        kumanya: secilen.contains('Kumanya'),
        diger: secilen.any((e) => e.startsWith('Diğer')),
        digerIkram: digerIkramStr,
        kiKatilimci: ikramData.kurumIciAdet,
        kdKatilimci: ikramData.kurumDisiAdet,
        toplamKatilimci: ikramData.kurumIciAdet + ikramData.kurumDisiAdet,
        baslangicSaat: ikramData.baslangicSaati.split(':')[0],
        baslangicDakika: ikramData.baslangicSaati.split(':')[1],
        bitisSaat: ikramData.bitisSaati.split(':')[0],
        bitisDakika: ikramData.bitisSaati.split(':')[1],
      );
    }).toList();

    final req = YiyecekIstekEkleReq(
      binaId: binaIds,
      ikramlar: ikramRequests,
      etkinlikTarihi:
          _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      donem: _selectedDonem ?? 'string',
      etkinlikAdi: _selectedEtkinlik ?? 'string',
      etkinlikAdiDiger: _selectedEtkinlik == 'Diğer'
          ? _customEtkinlikController.text
          : 'string',
      ikramYeri: _ikramYeriController.text,
      aciklama: _aciklamaController.text,
    );

    // Build Summary Items
    final ozetItems = <YiyecekIcecekOzetItem>[];

    ozetItems.add(YiyecekIcecekOzetItem(label: 'Okullar', value: binalarText));

    String etkinlikAdi = _selectedEtkinlik ?? '-';
    if (etkinlikAdi == 'Diğer') {
      etkinlikAdi = 'Diğer (${_customEtkinlikController.text})';
    }
    ozetItems.add(
      YiyecekIcecekOzetItem(label: 'Etkinlik Adı', value: etkinlikAdi),
    );

    String tarihStr = '-';
    if (_selectedDate != null) {
      tarihStr =
          '${_selectedDate!.day.toString().padLeft(2, '0')}.${_selectedDate!.month.toString().padLeft(2, '0')}.${_selectedDate!.year}';
    }
    ozetItems.add(
      YiyecekIcecekOzetItem(label: 'Etkinlik Tarihi', value: tarihStr),
    );

    ozetItems.add(
      YiyecekIcecekOzetItem(label: 'Dönem', value: _selectedDonem ?? '-'),
    );
    ozetItems.add(
      YiyecekIcecekOzetItem(
        label: 'İkram Yeri',
        value: _ikramYeriController.text,
      ),
    );
    ozetItems.add(
      YiyecekIcecekOzetItem(
        label: 'Açıklama',
        value: _aciklamaController.text.isEmpty
            ? '-'
            : _aciklamaController.text,
      ),
    );

    // Ikram Summary
    final ikramOzetleri = _addedIkramlar
        .map((ikram) {
          String treats = ikram.secilenIkramlar.join(', ');
          return 'Saat: ${ikram.baslangicSaati}-${ikram.bitisSaati} | Kişi: ${ikram.kurumIciAdet + ikram.kurumDisiAdet} | $treats';
        })
        .join('\n\n');

    ozetItems.add(
      YiyecekIcecekOzetItem(label: 'Eklenen İkramlar', value: ikramOzetleri),
    );

    // Show Summary Sheet
    await showYiyecekIcecekOzetBottomSheet(
      context: context,
      request: req,
      talepTipi: 'Yiyecek İçecek',
      ozetItems: ozetItems,
      onGonder: () async {
        // Actual API submission logic moved here (minus the loading dialog which is handled by wrapper)
        final repo = ref.read(yiyecekIcecekRepositoryProvider);
        // Repository method returns void currently and throws exception on error.
        // We need to wrap it to be safe or update repository to return Result.
        // Since existing repository method matches what we expect (exception on failure), we can just call it.
        await repo.yiyecekIstekEkle(req);
      },
      onSuccess: () async {
        if (!mounted) return;
        await IstekBasariliWidget.goster(
          context: context,
          message: 'Yiyecek içecek isteğiniz oluşturulmuştur.',
          onConfirm: () async {
            ref.invalidate(yiyecekIstekDevamEdenTaleplerProvider);
            ref.invalidate(yiyecekIstekTamamlananTaleplerProvider);
            if (!context.mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
            if (!context.mounted) return;
            context.go('/yiyecek_icecek_istek');
          },
        );
      },
      onError: (error) {
        _showStatusBottomSheet(error, isError: true);
      },
    );
  }

  void _showStatusBottomSheet(
    String message, {
    bool isError = false,
    bool onSuccess = false,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: AppColors.textPrimary54,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.textOnPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isError ? AppColors.error : AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_rounded : Icons.check_circle,
                  size: 48,
                  color: isError ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    if (onSuccess) {
                      Navigator.pop(
                        context,
                      ); // Return to previous screen (Management Screen)
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

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
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            centerTitle: false,
            title: const Text(
              'Yiyecek İçecek İstek',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.gradientStart,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
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
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Okul Seçim Widget
                Text(
                  'İkramın yapılacağı okul/bina seçiniz',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showBinaBottomSheet,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                          child: binalarAsync.when(
                            data: (binalar) => Text(
                              _buildSelectedText(binalar),
                              style: TextStyle(
                                color: _selectedBinaKodlari.isEmpty
                                    ? Colors.grey.shade600
                                    : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            loading: () => const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Yükleniyor...'),
                              ],
                            ),
                            error: (err, stack) => const Text(
                              'Liste alınamadı',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (_selectedBinaKodlari.isNotEmpty)
                  binalarAsync.when(
                    data: (binalar) => TextButton.icon(
                      onPressed: () => _showSelectedBinalarSheet(binalar),
                      icon: const Icon(Icons.list),
                      label: Text(
                        'Seçilen Okullar (${_selectedBinaKodlari.length})',
                        style: const TextStyle(fontSize: 15),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gradientStart,
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                const SizedBox(height: 16),

                // Etkinlik Tarihi ve Dönem Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Etkinlik Tarihi
                    Expanded(
                      child: DatePickerBottomSheetWidget(
                        label: 'Etkinlik Tarihi',
                        labelStyle: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              fontSize:
                                  (Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.fontSize ??
                                      14) +
                                  1,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inputLabelColor,
                            ),
                        initialDate: _selectedDate,
                        onDateChanged: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                        placeholder: 'Tarih',
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Dönem
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dönem',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.fontSize ??
                                          14) +
                                      1,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.inputLabelColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _showDonemBottomSheet,
                            child: Focus(
                              focusNode: _donemFocusNode,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textOnPrimary,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _selectedDonem ?? 'Seçiniz',
                                        style: TextStyle(
                                          color: _selectedDonem == null
                                              ? Colors.grey.shade600
                                              : AppColors.textPrimary,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const CommonDivider(),
                const SizedBox(height: 16),

                // Etkinlik Adı Seçimi
                Text(
                  'Etkinlik Adı',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showEtkinlikBottomSheet,
                  child: Focus(
                    focusNode: _etkinlikFocusNode,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedEtkinlik ?? 'Seçiniz',
                              style: TextStyle(
                                color: _selectedEtkinlik == null
                                    ? Colors.grey.shade600
                                    : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                // "Diğer" seçildiyse manuel giriş
                if (_selectedEtkinlik == 'Diğer') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customEtkinlikController,
                    focusNode: _customEtkinlikFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Etkinlik adını yazınız',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // İkram Yapılacak Yer
                Text(
                  'İkram Yapılacak Yer',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    fontWeight: FontWeight.bold,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ikramYeriController,
                  focusNode: _ikramYeriFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Bahçe, study vb. belirtiniz',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const CommonDivider(),
                const SizedBox(height: 16),

                // Eklenen İkramlar Listesi
                if (_addedIkramlar.isNotEmpty) ...[
                  ..._addedIkramlar.asMap().entries.map((entry) {
                    final index = entry.key;
                    final ikram = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(ikram),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            CustomSlidableAction(
                              onPressed: (context) async {
                                final result =
                                    await Navigator.push<
                                      YiyecekIcecekIkramData
                                    >(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            YiyecekIcecekIkramEkleScreen(
                                              existingData: ikram,
                                            ),
                                      ),
                                    );

                                if (result != null) {
                                  setState(() {
                                    _addedIkramlar[index] = result;
                                  });
                                }
                              },
                              backgroundColor: AppColors.primary,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 24,
                                      color: AppColors.textOnPrimary,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Düzenle',
                                      style: TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            CustomSlidableAction(
                              onPressed: (context) {
                                setState(() {
                                  _addedIkramlar.removeAt(index);
                                });
                              },
                              backgroundColor: AppColors.error,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 24,
                                      color: AppColors.textOnPrimary,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Sil',
                                      style: TextStyle(
                                        color: AppColors.textOnPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.textOnPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ikram.secilenIkramlar.join(", "),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${ikram.toplamAdet} kişi',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    '${ikram.baslangicSaati} - ${ikram.bitisSaati}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // İkram Ekle Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () async {
                      final result =
                          await Navigator.push<YiyecekIcecekIkramData>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const YiyecekIcecekIkramEkleScreen(),
                            ),
                          );

                      if (result != null) {
                        setState(() {
                          _addedIkramlar.add(result);
                        });
                        // Focus on submit button and hide keyboard
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (!context.mounted) return;
                          FocusScope.of(context).unfocus();
                          if (_submitFocusNode.canRequestFocus) {
                            _submitFocusNode.requestFocus();
                          }
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'İkram Ekle',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            '+',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const CommonDivider(),
                const SizedBox(height: 24),
                AciklamaFieldWidget(
                  controller: _aciklamaController,
                  focusNode: _aciklamaFocusNode,
                ),
                const SizedBox(height: 24),
                GonderButtonWidget(
                  onPressed: () => _validateAndSubmit(),
                  padding: 14.0,
                  borderRadius: 8.0,
                  textStyle: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EtkinlikSearchableSheet extends StatefulWidget {
  final List<String> etkinlikler;
  final ValueChanged<String> onSelect;

  const _EtkinlikSearchableSheet({
    required this.etkinlikler,
    required this.onSelect,
  });

  @override
  State<_EtkinlikSearchableSheet> createState() =>
      _EtkinlikSearchableSheetState();
}

class _EtkinlikSearchableSheetState extends State<_EtkinlikSearchableSheet> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filteredList;

  @override
  void initState() {
    super.initState();
    _filteredList = List.from(widget.etkinlikler);
    _filteredList.add('Diğer');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = List.from(widget.etkinlikler);
        _filteredList.add('Diğer');
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredList = widget.etkinlikler
            .where((e) => e.toLowerCase().contains(lowerQuery))
            .toList();
        // Arama sonucunda 'Diğer' hep altta kalsın
        _filteredList.add('Diğer');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Etkinlik Seçiniz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Etkinlik ara',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredList.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredList.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = _filteredList[index];
                      return InkWell(
                        onTap: () => widget.onSelect(item),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

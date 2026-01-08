import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_ikram_data.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_ikram_ekle_screen.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';

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
  final TextEditingController _customEtkinlikController = TextEditingController();
  final TextEditingController _ikramYeriController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final List<YiyecekIcecekIkramData> _addedIkramlar = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _searchBinaController.dispose();
    _customEtkinlikController.dispose();
    _ikramYeriController.dispose();
    _aciklamaController.dispose();
    _aciklamaFocusNode.dispose();
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
      backgroundColor: Colors.white,
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
                      style: TextStyle(color: Colors.red.shade600),
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
      backgroundColor: Colors.white,
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
                      style: TextStyle(color: Colors.red.shade600),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            const Divider(height: 1, color: Color(0xFFE0E0E0), indent: 16, endIndent: 16),
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
                                  hintText: 'Okul adı ile ara',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
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
                                  : ListView.builder(
                                      itemCount: filteredBinalar.length,
                                      itemBuilder: (context, index) {
                                        final item = filteredBinalar[index];
                                        final isSelected = _selectedBinaKodlari
                                            .contains(item.binaKodu);
                                        return CheckboxListTile(
                                          dense: true,
                                          title: Text(
                                            item.binaAdi,
                                            style: TextStyle(
                                              fontSize:
                                                  (Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.fontSize ??
                                                      16) +
                                                  2,
                                            ),
                                          ),
                                          value: isSelected,
                                          activeColor: AppColors.gradientStart,
                                          onChanged: (_) {
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
      backgroundColor: Colors.white,
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
                          foregroundColor: Colors.white,
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

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isError ? Colors.red.shade100 : Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check,
                  color: isError ? Colors.red : Colors.green,
                  size: 32,
                ),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          centerTitle: false,
          title: const Text(
            'Yiyecek İçecek İstek',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.gradientStart,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
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
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
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
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
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
                                  : Colors.black,
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
                            style: TextStyle(color: Colors.red),
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
                      labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) + 1,
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
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize:
                                (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                                1,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inputLabelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                         GestureDetector(
                          onTap: _showDonemBottomSheet,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    _selectedDonem ?? 'Seçiniz',
                                    style: TextStyle(
                                      color: _selectedDonem == null
                                          ? Colors.grey.shade600
                                          : Colors.black,
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
                      ],
                    ),
                  ),
                ],
              ),
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
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
                                : Colors.black,
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

              // "Diğer" seçildiyse manuel giriş
              if (_selectedEtkinlik == 'Diğer') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customEtkinlikController,
                  decoration: InputDecoration(
                    hintText: 'Etkinlik adını yazınız',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
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
                decoration: InputDecoration(
                  hintText: 'Bahçe, study vb. belirtiniz',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
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
                                  await Navigator.push<YiyecekIcecekIkramData>(
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
                            backgroundColor: const Color(0xFF014B92),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF014B92),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Düzenle',
                                    style: TextStyle(
                                      color: Colors.white,
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
                            backgroundColor: Colors.red,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Sil',
                                    style: TextStyle(
                                      color: Colors.white,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200.withOpacity(0.5),
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
                                color: Colors.black87,
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
                    final result = await Navigator.push<YiyecekIcecekIkramData>(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'İkram Ekle',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          '+',
                          style: TextStyle(
                            color: Colors.black,
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
              const SizedBox(height: 24),
              AciklamaFieldWidget(
                controller: _aciklamaController,
                focusNode: _aciklamaFocusNode,
              ),
            ],
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
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredList.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFE0E0E0),
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


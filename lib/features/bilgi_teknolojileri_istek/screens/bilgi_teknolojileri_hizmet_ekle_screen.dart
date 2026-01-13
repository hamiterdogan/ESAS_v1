import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/bilgi_teknolojileri_hizmet_data.dart';
import 'package:intl/intl.dart';

class BilgiTeknolojileriHizmetEkleScreen extends ConsumerStatefulWidget {
  final BilgiTeknolojileriHizmetData? existingData;
  final String destekTuru;

  const BilgiTeknolojileriHizmetEkleScreen({
    super.key,
    this.existingData,
    this.destekTuru = 'bilgiTek',
  });

  @override
  ConsumerState<BilgiTeknolojileriHizmetEkleScreen> createState() =>
      _BilgiTeknolojileriHizmetEkleScreenState();
}

class _BilgiTeknolojileriHizmetEkleScreenState
    extends ConsumerState<BilgiTeknolojileriHizmetEkleScreen> {
  final Set<String> _selectedBinaKodlari = <String>{};
  final TextEditingController _searchBinaController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final FocusNode _okulFocusNode = FocusNode();
  final FocusNode _tarihFocusNode = FocusNode();
  final FocusNode _kategoriFocusNode = FocusNode();
  DateTime? _selectedDate;
  String? _selectedHizmetKategorisi;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      // Initialize form fields with existing data
      _selectedHizmetKategorisi = widget.existingData!.kategori;
      _aciklamaController.text = widget.existingData!.aciklama;
      try {
        _selectedDate = DateFormat(
          'dd.MM.yyyy',
        ).parse(widget.existingData!.tarih);
      } catch (e) {
        _selectedDate = null;
      }
      // For bina selection, we'll need to match the names after binalar loads
      // This will be handled in build method with WidgetsBinding callback
    }
  }

  @override
  void dispose() {
    _searchBinaController.dispose();
    _aciklamaController.dispose();
    _aciklamaFocusNode.dispose();
    _okulFocusNode.dispose();
    _tarihFocusNode.dispose();
    _kategoriFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showWarningBottomSheet(String message) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _showBinaBottomSheet() async {
    FocusScope.of(context).unfocus();
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
                      style: TextStyle(color: AppColors.error),
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
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
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
                                          color: AppColors.textSecondary,
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
                                    foregroundColor: AppColors.textOnPrimary,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _showSelectedBinalarSheet(List<SatinAlmaBina> binalar) async {
    FocusScope.of(context).unfocus();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  Future<void> _showHizmetKategorisiBottomSheet() async {
    FocusScope.of(context).unfocus();

    await showModalBottomSheet<void>(
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
              final asyncKategoriler = ref.watch(
                hizmetKategorileriProvider(widget.destekTuru),
              );
              return asyncKategoriler.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 64)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hizmet kategorileri alınamadı',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.refresh(
                            hizmetKategorileriProvider(widget.destekTuru),
                          ),
                          child: const Text('Tekrar dene'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (kategoriler) {
                  return SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.55,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hizmet Kategorisi Seçin',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          4,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        Expanded(
                          child: kategoriler.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: kategoriler.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    thickness: 0.6,
                                    color: Colors.grey.shade300,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = kategoriler[index];
                                    final isSelected =
                                        _selectedHizmetKategorisi == item;
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item,
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
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedHizmetKategorisi = item;
                                        });
                                        Navigator.pop(ctx);
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
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

    // Initialize selected okul/bina from existing data
    if (widget.existingData != null && binalarAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_selectedBinaKodlari.isEmpty) {
          final binalar = binalarAsync.value!;
          for (final binaAdi in widget.existingData!.binaAdlari) {
            final bina = binalar.firstWhere(
              (b) => b.binaAdi == binaAdi,
              orElse: () => SatinAlmaBina(id: 0, binaKodu: '', binaAdi: ''),
            );
            if (bina.binaKodu.isNotEmpty) {
              setState(() {
                _selectedBinaKodlari.add(bina.binaKodu);
              });
            }
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Bilgi Teknolojileri Hizmet Ekle',
            style: TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Okul Seçim Widget
                Text(
                  'İsteğin yapılacağı okul/bina seçiniz',
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
                  child: Focus(
                    focusNode: _okulFocusNode,
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

                // İstenen Son Çözüm Tarihi Widget
                Focus(
                  focusNode: _tarihFocusNode,
                  child: DatePickerBottomSheetWidget(
                    label: 'İstenen Son Çözüm Tarihi:',
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
                    placeholder: 'Tarih seçiniz',
                  ),
                ),

                const SizedBox(height: 16),

                // Hizmet Kategorisi Widget
                Text(
                  'Hizmet Kategorisi',
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
                  onTap: _showHizmetKategorisiBottomSheet,
                  child: Focus(
                    focusNode: _kategoriFocusNode,
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
                            child: Text(
                              _selectedHizmetKategorisi ?? 'Seçiniz',
                              style: TextStyle(
                                color: _selectedHizmetKategorisi == null
                                    ? Colors.grey.shade600
                                    : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Açıklama Widget
                AciklamaFieldWidget(
                  controller: _aciklamaController,
                  focusNode: _aciklamaFocusNode,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // 1. Okul seçimi kontrolü
                if (_selectedBinaKodlari.isEmpty) {
                  await _showWarningBottomSheet(
                    'Lütfen en az bir okul seçiniz',
                  );
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_okulFocusNode.canRequestFocus) {
                      _okulFocusNode.requestFocus();
                    }
                  });
                  return;
                }

                // 2. Tarih kontrolü
                if (_selectedDate == null) {
                  await _showWarningBottomSheet(
                    'Lütfen istenen son çözüm tarihini seçiniz',
                  );
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_tarihFocusNode.canRequestFocus) {
                      _tarihFocusNode.requestFocus();
                    }
                  });
                  return;
                }

                // 3. Hizmet kategorisi kontrolü
                if (_selectedHizmetKategorisi == null) {
                  await _showWarningBottomSheet(
                    'Lütfen hizmet kategorisi seçiniz',
                  );
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_kategoriFocusNode.canRequestFocus) {
                      _kategoriFocusNode.requestFocus();
                    }
                  });
                  return;
                }

                // 4. Açıklama kontrolü
                if (_aciklamaController.text.trim().isEmpty) {
                  await _showWarningBottomSheet('Lütfen açıklama giriniz');
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_aciklamaFocusNode.canRequestFocus) {
                      _aciklamaFocusNode.requestFocus();
                    }
                  });
                  return;
                }

                // Verileri hazırla ve geri dön
                final binalarAsync = ref.read(satinAlmaBinalarProvider);
                final binalar = binalarAsync.value ?? [];
                final selectedBinaAdlari = binalar
                    .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
                    .map((b) => b.binaAdi)
                    .toList();

                final data = BilgiTeknolojileriHizmetData(
                  binaAdlari: selectedBinaAdlari,
                  tarih: DateFormat('dd.MM.yyyy').format(_selectedDate!),
                  kategori: _selectedHizmetKategorisi!,
                  aciklama: _aciklamaController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context, data);
                }
              },
              child: const Text(
                'Tamam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/widgets/satin_alma_urun_card.dart';

class SatinAlmaTalepScreen extends ConsumerStatefulWidget {
  const SatinAlmaTalepScreen({super.key});

  @override
  ConsumerState<SatinAlmaTalepScreen> createState() =>
      _SatinAlmaTalepScreenState();
}

class _SatinAlmaTalepScreenState extends ConsumerState<SatinAlmaTalepScreen> {
  final Set<String> _selectedBinaKodlari = <String>{};
  final TextEditingController _alimAmaciController = TextEditingController();
  final FocusNode _alimAmaciFocusNode = FocusNode();
  final TextEditingController _saticiFirmaController = TextEditingController();
  final TextEditingController _saticiTelefonController =
      TextEditingController();
  final TextEditingController _webSitesiController = TextEditingController();
  final TextEditingController _searchBinaController = TextEditingController();
  DateTime _teslimTarihi = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _alimAmaciController.dispose();
    _alimAmaciFocusNode.dispose();
    _saticiFirmaController.dispose();
    _saticiTelefonController.dispose();
    _webSitesiController.dispose();
    _searchBinaController.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (dialogContext) {
        return Center(
          child: Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            alignment: Alignment.center,
            child: const BrandedLoadingIndicator(size: 153, strokeWidth: 24),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleSelection(String binaKodu) {
    setState(() {
      if (_selectedBinaKodlari.contains(binaKodu)) {
        _selectedBinaKodlari.remove(binaKodu);
      } else {
        _selectedBinaKodlari.add(binaKodu);
      }
    });
  }

  String _buildSelectedText(List<SatinAlmaBina> binalar) {
    if (_selectedBinaKodlari.isEmpty) return 'Seçiniz';

    final selectedNames = binalar
        .where((e) => _selectedBinaKodlari.contains(e.binaKodu))
        .map((e) => e.binaAdi)
        .toList();

    if (selectedNames.isEmpty) return 'Seçiniz';
    if (selectedNames.length <= 2) {
      return selectedNames.join(', ');
    }
    return '${selectedNames.length} okul seçildi';
  }

  void _showSelectedBinalarSheet(List<SatinAlmaBina> allBinalar) {
    final selectedBinalar = allBinalar
        .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final currentSelectedBinalar = allBinalar
                  .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  Flexible(
                    child: currentSelectedBinalar.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Seçili okul bulunmamaktadır',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: currentSelectedBinalar.length,
                            itemBuilder: (context, index) {
                              final bina = currentSelectedBinalar[index];
                              return ListTile(
                                title: Text(bina.binaAdi),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    // Son okul siliniyorsa modalı hemen kapat
                                    if (currentSelectedBinalar.length == 1) {
                                      setState(() {
                                        _selectedBinaKodlari.remove(
                                          bina.binaKodu,
                                        );
                                      });
                                      Navigator.pop(context);
                                    } else {
                                      setState(() {
                                        _selectedBinaKodlari.remove(
                                          bina.binaKodu,
                                        );
                                      });
                                      setModalState(() {});
                                    }
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Kapat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showBinaBottomSheet() {
    showModalBottomSheet(
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
                  child: Center(child: CircularProgressIndicator()),
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
                      // Filter binalar based on search query
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
                            // Search field
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
                                  onPressed: () {
                                    _searchBinaController.clear();
                                    Navigator.pop(context);
                                  },
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
  }

  @override
  Widget build(BuildContext context) {
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text(
              'Satın Alma Talebi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF014B92),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          elevation: 0,
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
                  Text(
                    'Satın Alma Talebinde Bulunulan Okullar',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
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
                              loading: () => Row(
                                children: const [
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
                              error: (err, stack) => Text(
                                'Liste alınamadı',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedBinaKodlari.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: binalarAsync.when(
                        data: (binalar) => TextButton.icon(
                          onPressed: () => _showSelectedBinalarSheet(binalar),
                          icon: const Icon(Icons.list),
                          label: Text(
                            'Seçilen Okullar (${_selectedBinaKodlari.length})',
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
                    ),
                  const SizedBox(height: 16),
                  // Alımın Amacı (Binek Araç "Açıklama" alanı formatıyla)
                  AciklamaFieldWidget(
                    controller: _alimAmaciController,
                    focusNode: _alimAmaciFocusNode,
                    labelText: 'Alımın Amacı',
                  ),

                  const SizedBox(height: 24),

                  // Satıcı Firma
                  Text(
                    'Satıcı Firma',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saticiFirmaController,
                    decoration: InputDecoration(
                      hintText: 'Firma adını giriniz',
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

                  const SizedBox(height: 16),

                  // Satıcı Telefon
                  Text(
                    'Satıcı Telefon',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _saticiTelefonController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Telefon numarası',
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

                  const SizedBox(height: 16),

                  // Web Sitesi
                  Text(
                    'Web Sitesi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _webSitesiController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://',
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

                  const SizedBox(height: 24),

                  // Teslim edilecek tarih (Dokümantasyon Baskı İstek ile aynı widget)
                  Text(
                    'Son Teslim Tarihi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerBottomSheetWidget(
                          label: null,
                          initialDate: _teslimTarihi,
                          minDate: DateTime.now(),
                          maxDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          onDateChanged: (date) {
                            setState(() => _teslimTarihi = date);
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Expanded(child: SizedBox()),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const SatinAlmaUrunCard(),
                  const SizedBox(height: 24),
                  // TODO: Başka ürün ekle butonu vs.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

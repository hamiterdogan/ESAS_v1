import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_ekle_req.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_urun_ekle_screen.dart';
import 'package:esas_v1/common/widgets/ders_saati_spinner_widget.dart';
import 'package:esas_v1/features/satin_alma/widgets/satin_alma_ozet_bottom_sheet.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _genelToplamController = TextEditingController();
  String? _odemeSekli = 'Nakit';
  bool _vadeli = false;
  int _odemeVadesi = 1;
  DateTime _teslimTarihi = DateTime.now();
  final List<SatinAlmaUrunBilgisi> _urunler = [];
  final List<PlatformFile> _selectedFiles = [];
  final TextEditingController _fiyatTeklifIcerikController =
      TextEditingController();

  double _parseMoneyToDouble(String value) {
    final cleaned = value
        .toUpperCase()
        .replaceAll('TL', '')
        .replaceAll('TRY', '')
        .replaceAll('₺', '')
        .trim();
    if (cleaned.isEmpty) return 0;

    final normalized = cleaned
        .replaceAll(RegExp(r'[^0-9.,-]'), '')
        // Turkish format: 1.234,56
        .replaceAll('.', '')
        .replaceAll(',', '.');

    return double.tryParse(normalized) ?? 0;
  }

  void _updateGenelToplam() {
    final sum = _urunler.fold<double>(
      0,
      (prev, e) => prev + _parseMoneyToDouble(e.toplamTlFiyati),
    );
    final formatted = NumberFormat('#,##0.00', 'tr_TR').format(sum);
    _genelToplamController.text = '$formatted TL';
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
        type: FileType.custom,
        allowMultiple: true,
      );

      if (result != null) {
        final existingNames = _selectedFiles.map((f) => f.name).toSet();
        final newFiles = <PlatformFile>[];
        final duplicateNames = <String>[];

        for (final file in result.files) {
          if (existingNames.contains(file.name)) {
            duplicateNames.add(file.name);
          } else {
            newFiles.add(file);
          }
        }

        setState(() {
          _selectedFiles.addAll(newFiles);
        });

        if (duplicateNames.isNotEmpty && mounted) {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: 60,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu dosyayı daha önce eklediniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duplicateNames.join(', '),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dosya seçimi başarısız: $e')));
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _updateGenelToplam();
    _updateExchangeRates();
  }

  Future<void> _updateExchangeRates() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/Finans/MerkezBankasiDovizKurlariniGuncelle', data: {});
    } catch (e) {
      // Silently fail - no error messages
      debugPrint('Exchange rate update failed: $e');
    }
  }

  void _deleteUrun(int index) {
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ürünü Sil',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bu ürünü silmek istediğinize emin misiniz?',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Sil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((shouldDelete) {
      if (shouldDelete == true) {
        setState(() {
          _urunler.removeAt(index);
          _updateGenelToplam();
        });
      }
    });
  }

  @override
  void dispose() {
    _alimAmaciController.dispose();
    _alimAmaciFocusNode.dispose();
    _saticiFirmaController.dispose();
    _saticiTelefonController.dispose();
    _webSitesiController.dispose();
    _searchBinaController.dispose();
    _genelToplamController.dispose();
    _fiyatTeklifIcerikController.dispose();
    super.dispose();
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

  void _showOdemeSekliBottomSheet() {
    final options = ['Nakit', 'Kredi Kartı', 'Havale/EFT'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ödeme Şekli Seçiniz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  options.length,
                  (index) => Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _odemeSekli = options[index]);
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  options[index],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_odemeSekli == options[index])
                                const Icon(
                                  Icons.check,
                                  color: AppColors.gradientStart,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (index < options.length - 1)
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                          height: 0,
                        ),
                    ],
                  ),
                ),
              ],
            ),
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
          context.go('/satin_alma');
        }
      },
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
                    onPressed: () => context.go('/satin_alma'),
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Satın Alma Talebi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
                              error: (err, stack) => Text(
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      hintText: '+90 5xx xxx xx xx',
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
                      hintText: 'https://site.com',
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
                  if (_urunler.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _urunler.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final urun = _urunler[index];
                        return SizedBox(
                          width: double.infinity,
                          child: Slidable(
                            key: ValueKey(index),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                CustomSlidableAction(
                                  onPressed: (_) {
                                    Navigator.push<SatinAlmaUrunBilgisi>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SatinAlmaUrunEkleScreen(
                                              initialBilgi: urun,
                                            ),
                                      ),
                                    ).then((result) {
                                      if (result != null) {
                                        setState(() {
                                          _urunler[index] = result;
                                          _updateGenelToplam();
                                        });
                                      }
                                    });
                                  },
                                  backgroundColor: Colors.blue,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Düzenle',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                CustomSlidableAction(
                                  onPressed: (_) => _deleteUrun(index),
                                  backgroundColor: Colors.red,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Sil',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
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
                            child: Builder(
                              builder: (builderContext) => GestureDetector(
                                onTap: () {
                                  final slidable = Slidable.of(builderContext);
                                  final isClosed =
                                      slidable?.actionPaneType.value ==
                                      ActionPaneType.none;

                                  if (!isClosed) {
                                    slidable?.close();
                                    return;
                                  }
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Card(
                                    elevation: 2,
                                    color:
                                        Color.lerp(
                                          Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                          Colors.white,
                                          0.65,
                                        ) ??
                                        Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final anaKategori =
                                                  (urun.anaKategori ?? '')
                                                      .trim();
                                              final altKategori =
                                                  (urun.altKategori ?? '')
                                                      .trim();
                                              final urunDetay =
                                                  (urun.urunDetay ?? '').trim();

                                              final miktar = urun.miktar ?? 0;
                                              final birim =
                                                  ((urun.olcuBirimiKisaltma ??
                                                                  '')
                                                              .trim()
                                                              .isNotEmpty
                                                          ? urun.olcuBirimiKisaltma
                                                          : urun.olcuBirimi)
                                                      ?.trim();

                                              final paraKod =
                                                  (urun.paraBirimiKod ?? '')
                                                      .trim();
                                              final displayParaKod =
                                                  paraKod.toUpperCase() == 'TRY'
                                                  ? 'TL'
                                                  : paraKod;

                                              final fiyatAna =
                                                  (urun.fiyatAna ?? '').trim();
                                              final fiyatKusurat =
                                                  (urun.fiyatKusurat ?? '')
                                                      .trim();

                                              // Birim fiyatı KDV dahil olarak hesapla
                                              double birimFiyatDouble = 0.0;
                                              try {
                                                final fiyatAnaDouble =
                                                    double.tryParse(
                                                      fiyatAna
                                                          .replaceAll('.', '')
                                                          .replaceAll(',', '.'),
                                                    ) ??
                                                    0;
                                                final fiyatKusuratDouble =
                                                    double.tryParse(
                                                      fiyatKusurat,
                                                    ) ??
                                                    0;
                                                birimFiyatDouble =
                                                    fiyatAnaDouble +
                                                    (fiyatKusuratDouble / 100);

                                                // KDV ekle
                                                if (urun.kdvDahilDegil &&
                                                    urun.kdvOrani > 0) {
                                                  birimFiyatDouble +=
                                                      birimFiyatDouble *
                                                      (urun.kdvOrani / 100);
                                                }
                                              } catch (e) {
                                                birimFiyatDouble = 0.0;
                                              }

                                              final numberFormat = NumberFormat(
                                                '#,##0.00',
                                                'tr_TR',
                                              );
                                              final birimFiyat = numberFormat
                                                  .format(birimFiyatDouble);

                                              final toplamFiyat =
                                                  (urun.toplamFiyat ?? '')
                                                      .trim()
                                                      .replaceAll(
                                                        RegExp(
                                                          r'\bTRY\b',
                                                          caseSensitive: false,
                                                        ),
                                                        'TL',
                                                      );
                                              final tlKurFiyati =
                                                  (urun.tlKurFiyati ?? '')
                                                      .trim()
                                                      .replaceAll(
                                                        RegExp(
                                                          r'\bTRY\b',
                                                          caseSensitive: false,
                                                        ),
                                                        'TL',
                                                      );
                                              final toplamTlFiyat =
                                                  (urun.toplamTlFiyati)
                                                      .trim()
                                                      .replaceAll(
                                                        RegExp(
                                                          r'\bTRY\b',
                                                          caseSensitive: false,
                                                        ),
                                                        'TL',
                                                      );

                                              String line3 =
                                                  '$miktar${(birim ?? '').isNotEmpty ? ' $birim' : ''}';
                                              if (birimFiyat.isNotEmpty ||
                                                  displayParaKod.isNotEmpty) {
                                                final birimFiyatHasPara =
                                                    birimFiyat
                                                        .toUpperCase()
                                                        .contains(
                                                          displayParaKod
                                                              .toUpperCase(),
                                                        );
                                                final birimFiyatWithPara =
                                                    birimFiyat.isNotEmpty
                                                    ? (displayParaKod
                                                                  .isNotEmpty &&
                                                              !birimFiyatHasPara
                                                          ? '$birimFiyat $displayParaKod'
                                                          : birimFiyat)
                                                    : displayParaKod;
                                                line3 =
                                                    '$line3 * $birimFiyatWithPara'
                                                        .trim();
                                              }

                                              final toplamFiyatHasPara =
                                                  toplamFiyat
                                                      .toUpperCase()
                                                      .contains(
                                                        displayParaKod
                                                            .toUpperCase(),
                                                      );
                                              final line4Left =
                                                  (toplamFiyat.isNotEmpty
                                                          ? (displayParaKod
                                                                        .isNotEmpty &&
                                                                    !toplamFiyatHasPara
                                                                ? '$toplamFiyat $displayParaKod'
                                                                : toplamFiyat)
                                                          : displayParaKod)
                                                      .trim();
                                              final line4 =
                                                  displayParaKod
                                                          .toUpperCase()
                                                          .contains('TRY') ||
                                                      displayParaKod
                                                          .toUpperCase()
                                                          .contains('TL')
                                                  ? toplamTlFiyat
                                                  : '${line4Left.isNotEmpty ? line4Left : ''}${tlKurFiyati.isNotEmpty ? ' * $tlKurFiyati' : ''}${toplamTlFiyat.isNotEmpty ? ' = $toplamTlFiyat' : ''}'
                                                        .trim();

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text: anaKategori,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        if (altKategori
                                                            .isNotEmpty)
                                                          TextSpan(
                                                            text:
                                                                ' - $altKategori',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: Colors
                                                                  .grey
                                                                  .shade800,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (urunDetay.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      urunDetay,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey
                                                            .shade800,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    line3,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          Colors.grey.shade700,
                                                    ),
                                                  ),
                                                  if (line4.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      line4,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .gradientStart,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        final result =
                            await Navigator.push<SatinAlmaUrunBilgisi>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SatinAlmaUrunEkleScreen(),
                              ),
                            );

                        if (result != null) {
                          setState(() {
                            _urunler.add(result);
                            _updateGenelToplam();
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.gradientStart,
                        size: 28,
                      ),
                      label: const Text(
                        'Ürün / Hizmet Ekle',
                        style: TextStyle(
                          color: AppColors.gradientStart,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text(
                    'Genel Toplam',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _genelToplamController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: '0,00 TL',
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ödeme Şekli',
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
                            GestureDetector(
                              onTap: () => _showOdemeSekliBottomSheet(),
                              child: Container(
                                width:
                                    MediaQuery.of(context).size.width - 72 - 20,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _odemeSekli ?? 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _odemeSekli == null
                                            ? Colors.grey.shade500
                                            : Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Switch(
                            value: _vadeli,
                            activeColor: AppColors.gradientStart,
                            inactiveTrackColor: Colors.white,
                            onChanged: (v) {
                              setState(() {
                                _vadeli = v;
                                if (!v) {
                                  _odemeVadesi = 1;
                                }
                              });
                            },
                          ),
                          const Text(
                            'Vadeli',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_vadeli) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DersSaatiSpinnerWidget(
                          label: 'Ödeme Vadesi',
                          minValue: 1,
                          maxValue: 999,
                          initialValue: _odemeVadesi,
                          onValueChanged: (value) {
                            setState(() {
                              _odemeVadesi = value;
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Gün',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Fiyat Teklifi / Sözleşme Ekle
                  Text(
                    'Fiyat Teklifi / Sözleşme Ekle',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickFiles,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 24,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dosya Seçmek İçin Dokunun',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '(pdf, jpg, jpeg, png, doc, docx, xls, xlsx)',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.insert_drive_file_outlined,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _removeFile(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Dosyaların İçeriğini Belirtiniz
                  Text(
                    'Dosyaların İçeriğini Belirtiniz',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fiyatTeklifIcerikController,
                    decoration: InputDecoration(
                      hintText: 'Dosya içeriği hakkında bilgi veriniz',
                      contentPadding: const EdgeInsets.all(12),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 0.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 0.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade600,
                          width: 0.5,
                        ),
                      ),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 32),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<SatinAlmaOzetItem> _buildSatinAlmaOzetItems(
    List<SatinAlmaBina> allBinalar,
    SatinAlmaEkleReq request,
  ) {
    final selectedBinaNames = allBinalar
        .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
        .map((b) => b.binaAdi)
        .toList();
    final binaText = selectedBinaNames.isEmpty
        ? 'Belirtilmedi'
        : selectedBinaNames.join('\n');

    final teslimTarihiText = DateFormat(
      'dd.MM.yyyy',
    ).format(request.sonTeslimTarihi);
    final odemeText = _odemeSekli ?? '-';
    final vadeText = _vadeli ? 'Vadeli ($_odemeVadesi gün)' : 'Peşin';

    final urunOzet = _urunler
        .map((u) {
          final kategori = [
            u.anaKategori ?? '',
            if (u.altKategori != null && u.altKategori!.isNotEmpty)
              u.altKategori ?? '',
          ].where((e) => e.isNotEmpty).join(' / ');

          final miktarText = u.miktar != null
              ? '${u.miktar} ${u.olcuBirimiKisaltma ?? u.olcuBirimi ?? ''}'
                    .trim()
              : '';

          final pieces = [
            if (kategori.isNotEmpty) kategori,
            u.urunDetay ?? '',
            if (miktarText.isNotEmpty) miktarText,
            if (u.toplamTlFiyati.isNotEmpty) u.toplamTlFiyati,
          ].where((e) => e.toString().trim().isNotEmpty).toList();

          return pieces.join(' • ');
        })
        .join('\n');

    final genelToplamText = _genelToplamController.text.isNotEmpty
        ? _genelToplamController.text
        : NumberFormat('#,##0.00', 'tr_TR').format(request.genelToplam);

    final items = <SatinAlmaOzetItem>[
      SatinAlmaOzetItem(label: 'Okullar', value: binaText),
      SatinAlmaOzetItem(
        label: 'Teslim Tarihi',
        value: teslimTarihiText,
        multiLine: false,
      ),
      SatinAlmaOzetItem(
        label: 'Ödeme Şekli',
        value: odemeText,
        multiLine: false,
      ),
      SatinAlmaOzetItem(label: 'Vade', value: vadeText, multiLine: false),
      SatinAlmaOzetItem(
        label: 'Genel Toplam',
        value: genelToplamText,
        multiLine: false,
      ),
      SatinAlmaOzetItem(
        label: 'Ürün Sayısı',
        value: '${_urunler.length}',
        multiLine: false,
      ),
      SatinAlmaOzetItem(label: 'Alım Amacı', value: request.aliminAmaci),
      SatinAlmaOzetItem(
        label: 'Ürünler',
        value: urunOzet.isEmpty ? 'Belirtilmedi' : urunOzet,
      ),
    ];

    if (_selectedFiles.isNotEmpty) {
      items.insert(
        6,
        SatinAlmaOzetItem(
          label: 'Dosya Sayısı',
          value: '${_selectedFiles.length}',
          multiLine: false,
        ),
      );
      // Dosya adlarını özet ekranında göster
      final dosyaAdlari = _selectedFiles.map((f) => f.name).join('\n');
      items.insert(
        7,
        SatinAlmaOzetItem(
          label: 'Yüklenen Dosyalar',
          value: dosyaAdlari,
          multiLine: true,
        ),
      );
    }

    if (_saticiFirmaController.text.trim().isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Satıcı Firma',
          value: _saticiFirmaController.text.trim(),
        ),
      );
    }

    if (_saticiTelefonController.text.trim().isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Satıcı Telefonu',
          value: _saticiTelefonController.text.trim(),
          multiLine: false,
        ),
      );
    }

    if (_webSitesiController.text.trim().isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Web Sitesi',
          value: _webSitesiController.text.trim(),
        ),
      );
    }

    if (request.dosyaAciklama.trim().isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Dosya Açıklaması',
          value: request.dosyaAciklama.trim(),
        ),
      );
    }

    return items;
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    if (!RegExp(r'^[0-9+ ()-]+$').hasMatch(input)) {
      return 'Lütfen geçerli bir telefon numarası giriniz (örn. +90 555 555 55 55).';
    }
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 14) {
      return 'Telefon numarası 10-14 haneli olmalıdır (örn. +90 555 555 55 55).';
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;

    final uri = Uri.tryParse(input);
    final hasValidScheme =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!hasValidScheme) {
      return 'Lütfen geçerli bir web adresi giriniz (https://... ).';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_alimAmaciController.text.trim().isEmpty) {
      _showStatusBottomSheet(
        'Lütfen alımın amacını belirtiniz.',
        isError: true,
      );
      return;
    }

    if (_urunler.isEmpty) {
      _showStatusBottomSheet('Lütfen en az 1 ürün ekleyiniz.', isError: true);
      return;
    }

    final phoneError = _validatePhone(_saticiTelefonController.text);
    if (phoneError != null) {
      _showStatusBottomSheet(phoneError, isError: true);
      return;
    }

    final websiteError = _validateWebsite(_webSitesiController.text);
    if (websiteError != null) {
      _showStatusBottomSheet(websiteError, isError: true);
      return;
    }

    try {
      int odemeSekliId = 0;
      final paymentMethodMap = {'Nakit': 1, 'Kredi Kartı': 2, 'Havale/EFT': 3};
      if (_odemeSekli != null && paymentMethodMap.containsKey(_odemeSekli)) {
        odemeSekliId = paymentMethodMap[_odemeSekli] ?? 0;
      }

      final binalar = await ref.read(satinAlmaBinalarProvider.future);
      List<int> binaIds = [];
      if (_selectedBinaKodlari.isNotEmpty) {
        binaIds = binalar
            .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
            .map((b) => b.id)
            .toList();
      }

      final urunSatirlar = _urunler.map((u) {
        double birimFiyat = 0;
        try {
          final ana =
              double.tryParse(
                (u.fiyatAna ?? '0').replaceAll('.', '').replaceAll(',', '.'),
              ) ??
              0;
          final kusurat = double.tryParse(u.fiyatKusurat ?? '0') ?? 0;
          birimFiyat = ana + (kusurat / 100);
        } catch (_) {}

        return SatinAlmaUrunSatir(
          satinAlmaAltKategoriId: u.altKategoriId,
          digerUrun: '',
          birimId: u.olcuBirimiId,
          satinAlmaAnaKategoriId: u.anaKategoriId,
          birimFiyati: birimFiyat,
          urunDetay: u.urunDetay ?? '',
          miktar: u.miktar ?? 1,
          paraBirimi: u.paraBirimi,
        );
      }).toList();

      final req = SatinAlmaEkleReq(
        formFiles: _selectedFiles,
        pesin: !_vadeli,
        sonTeslimTarihi: _teslimTarihi,
        aliminAmaci: _alimAmaciController.text,
        odemeSekliId: odemeSekliId,
        webSitesi: _webSitesiController.text,
        saticiTel: _saticiTelefonController.text,
        binaIds: binaIds,
        odemeVadesiGun: _vadeli ? _odemeVadesi : 0,
        urunSatirlar: urunSatirlar,
        saticiFirma: _saticiFirmaController.text,
        genelToplam: _parseMoneyToDouble(_genelToplamController.text),
        dosyaAciklama: _fiyatTeklifIcerikController.text,
      );

      final ozetItems = _buildSatinAlmaOzetItems(binalar, req);

      if (!mounted) return;

      await showSatinAlmaOzetBottomSheet(
        context: context,
        request: req,
        talepTipi: 'Satın Alma',
        ozetItems: ozetItems,
        onGonder: () async {
          BrandedLoadingDialog.show(context);
          try {
            final repo = ref.read(satinAlmaRepositoryProvider);
            final result = await repo.satinAlmaEkle(req);

            if (!mounted) return;

            switch (result) {
              case Success():
                return;
              case Failure(message: final msg):
                throw Exception(msg);
              case Loading():
                throw Exception('Talep gönderilemedi');
            }
          } finally {
            if (mounted) {
              BrandedLoadingDialog.hide(context);
            }
          }
        },
        onSuccess: () {
          // Liste ekranına dön ve verileri tazele
          ref.invalidate(satinAlmaDevamEdenTaleplerProvider);
          ref.invalidate(satinAlmaTamamlananTaleplerProvider);
          context.go('/satin_alma');
        },
        onError: (error) {
          _showStatusBottomSheet('Hata: $error', isError: true);
        },
      );
    } catch (e) {
      if (mounted) {
        _showStatusBottomSheet('Beklenmeyen hata: $e', isError: true);
      }
    }
  }

  void _showStatusBottomSheet(String message, {bool isError = false}) {
    if (!mounted) return;
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
}

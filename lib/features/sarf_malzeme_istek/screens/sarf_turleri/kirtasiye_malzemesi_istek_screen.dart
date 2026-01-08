import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_ekle_req.dart';
import 'package:esas_v1/features/satin_alma/widgets/satin_alma_ozet_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_urun_ekle_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_turleri/sarf_malzeme_urun_ekle_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_ekle_req.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/repositories/sarf_malzeme_repository.dart'
    hide sarfMalzemeRepositoryProvider;
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/core/models/result.dart';

class KirtasiyeMalzemesiIstekScreen extends ConsumerStatefulWidget {
  const KirtasiyeMalzemesiIstekScreen({super.key});

  @override
  ConsumerState<KirtasiyeMalzemesiIstekScreen> createState() =>
      _KirtasiyeMalzemesiIstekScreenState();
}

class _KirtasiyeMalzemesiIstekScreenState
    extends ConsumerState<KirtasiyeMalzemesiIstekScreen> {
  final Set<String> _selectedBinaKodlari = <String>{};
  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final GlobalKey _aciklamaKey = GlobalKey();
  final TextEditingController _searchBinaController = TextEditingController();
  final List<SatinAlmaUrunBilgisi> _urunler = [];
  final List<PlatformFile> _selectedFiles = [];
  final TextEditingController _fiyatTeklifIcerikController =
      TextEditingController();
  final GlobalKey _gonderButtonKey = GlobalKey();

  Future<void> _scrollToWidget(GlobalKey key) async {
    final context = key.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  void _lockAndUnfocusInputs() {
    _aciklamaFocusNode.canRequestFocus = false;
    _aciklamaFocusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  void _unlockInputsAfterSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _aciklamaFocusNode.canRequestFocus = true;
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

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    // 1. Validate 'Açıklama' (Description) field
    if (_aciklamaController.text.trim().isEmpty) {
      FocusScope.of(context).unfocus();
      await Future.delayed(Duration.zero);
      // Ensure widget is visible if possible
      final keyContext = _aciklamaKey.currentContext;
      if (keyContext != null) {
        await Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }

      if (mounted) {
        await showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Lütfen bir açıklama giriniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // After closing sheet, focus key
        if (mounted) {
          _aciklamaFocusNode.canRequestFocus = true;
          FocusScope.of(context).requestFocus(_aciklamaFocusNode);
        }
      }
      return;
    }

    if (_urunler.isEmpty) {
      FocusScope.of(context).unfocus();
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lütfen en az 1 ürün ekleyiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF004D8C,
                        ), // Match screenshot blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } // End if (mounted)

      // After closing sheet, navigate to Urun Ekle
      if (mounted) {
        final result = await Navigator.push<SatinAlmaUrunBilgisi>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const SarfMalzemeUrunEkleScreen(talepTuru: 'Temizlik'),
          ),
        );

        if (result != null) {
          setState(() {
            _urunler.add(result);
          });
        }
        // After returning, scroll to submit button and unfocus
        if (mounted) {
          FocusScope.of(context).unfocus();
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToWidget(_gonderButtonKey);
          });
        }
      } // End if (mounted)
      return;
    }

    final urunSatirlar = _urunler.map((u) {
      return SatinAlmaUrunSatir(
        satinAlmaAltKategoriId: u.altKategoriId,
        digerUrun: '',
        birimId: u.olcuBirimiId,
        satinAlmaAnaKategoriId: u.anaKategoriId,
        birimFiyati: 0, // Temizlik malzemesinde fiyat yok
        urunDetay: u.urunDetay ?? '',
        miktar: u.miktar ?? 1,
        paraBirimi: u.paraBirimiKod,
      );
    }).toList();

    // Get current value of binalar for summary
    final binalarAsync = ref.read(satinAlmaBinalarProvider);
    final binalar = binalarAsync.asData?.value ?? [];

    // Map selected codes to IDs
    final selectedBinaIds = binalar
        .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
        .map((b) => b.id)
        .toList();

    // Construct a request object with available data and dummy defaults for others
    final req = SatinAlmaEkleReq(
      formFiles: _selectedFiles,
      pesin: true, // Default
      sonTeslimTarihi: DateTime.now(), // Default
      aliminAmaci: _aciklamaController.text, // Use user input for description
      odemeSekliId: 0, // Default
      webSitesi: '',
      saticiTel: '',
      binaId: selectedBinaIds, // Pass selected IDs
      odemeVadesiGun: 0,
      urunSatirlar: urunSatirlar,
      saticiFirma: '',
      genelToplam: 0,
      dosyaAciklama: _fiyatTeklifIcerikController.text,
    );

    final ozetItems = _buildOzetItems(req, binalar);

    // Prepare actual API request model
    final sarfReq = SarfMalzemeEkleReq(
      binaId: selectedBinaIds,
      talebinAmaci: _aciklamaController.text,
      talepTuru: 'Kırtasiye Malzemeleri',
      urunSatir: _urunler.map((u) {
        return SarfMalzemeUrunSatir(
          satinAlmaAnaKategoriId:
              u.anaKategoriId ?? 14, // Default to 14 (Temizlik) if null
          satinAlmaAltKategoriId: u.altKategoriId,
          urunDetay: u.urunDetay ?? '',
          miktar: u.miktar ?? 1,
          birimId: u.olcuBirimiId ?? 0,
        );
      }).toList(),
      formFiles: _selectedFiles,
      dosyaAciklama: _fiyatTeklifIcerikController.text,
    );

    // Track if submission was successful
    bool isSubmitted = false;

    await showSatinAlmaOzetBottomSheet(
      context: context,
      request: req,
      talepTipi: 'Kırtasiye Malzemesi',
      ozetItems: ozetItems,
      customJsonSnapshot: sarfReq.toJson(),
      onGonder: () async {
        // Call Repository
        final repo = ref.read(sarfMalzemeRepositoryProvider);
        final result = await repo.sarfMalzemeEkle(sarfReq);

        if (result is Failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: ${result.message}')));
          return;
        }
      },
      onSuccess: () async {
        isSubmitted = true;
        if (mounted) {
          // Show success bottom sheet
          await showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Kırtasiye malzemesi istek talebiniz gönderilmiştir',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
            ),
          );
          // Navigate to management screen
          if (mounted) {
            ref.invalidate(sarfMalzemeDevamEdenTaleplerProvider);
            context.go('/sarf_malzeme_istek');
          }
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $error')));
        }
      },
    );

    // If not submitted (e.g. "Düzenle" pressed or dismissed), focus cancel and scroll to button
    if (!isSubmitted && mounted) {
      // Explicitly unfocus any active focus node to dismiss keyboard and remove cursor
      FocusManager.instance.primaryFocus?.unfocus();
      FocusScope.of(context).unfocus();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollToWidget(_gonderButtonKey);
        }
      });
    }
  }

  List<SatinAlmaOzetItem> _buildOzetItems(
    SatinAlmaEkleReq request,
    List<SatinAlmaBina> binalar,
  ) {
    final items = <SatinAlmaOzetItem>[];

    // 1. Seçilen Okullar
    if (_selectedBinaKodlari.isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Seçilen Okullar',
          value: binalar
              .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
              .map((b) => b.binaAdi)
              .join('\n'),
          multiLine: true,
        ),
      );
    }

    // 2. Açıklama
    if (request.aliminAmaci.trim().isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Açıklama',
          value: request.aliminAmaci.trim(),
          multiLine: true,
        ),
      );
    }

    // 3. Ürünler
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
            // Price removed as it's not relevant for this screen
          ].where((e) => e.toString().trim().isNotEmpty).toList();

          return pieces.join(' • ');
        })
        .join('\n');

    items.add(
      SatinAlmaOzetItem(
        label: 'Ürün Sayısı',
        value: '${_urunler.length}',
        multiLine: false,
      ),
    );
    items.add(
      SatinAlmaOzetItem(
        label: 'Ürünler',
        value: urunOzet.isEmpty ? 'Belirtilmedi' : urunOzet,
      ),
    );

    // 4. Eklenen Dosyalar
    if (_selectedFiles.isNotEmpty) {
      items.add(
        SatinAlmaOzetItem(
          label: 'Dosya Sayısı',
          value: '${_selectedFiles.length}',
          multiLine: false,
        ),
      );
      final dosyaAdlari = _selectedFiles.map((f) => f.name).join('\n');
      items.add(
        SatinAlmaOzetItem(
          label: 'Yüklenen Dosyalar',
          value: dosyaAdlari,
          multiLine: true,
        ),
      );
    }

    // 5. Eklenen Dosya Açıklaması
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

  Future<void> _pickFiles() async {
    _lockAndUnfocusInputs();
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
          await showModalBottomSheet(
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
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                  ),
                ],
              ),
            ),
          );
          _unlockInputsAfterSheet();
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

  void _deleteUrun(int index) {
    FocusScope.of(context).unfocus();
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inputLabelColor,
                  ),
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
        });
      }
    });
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
    final selectedBinalar = binalar
        .where((b) => _selectedBinaKodlari.contains(b.binaKodu))
        .toList();

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
                        color: AppColors.inputLabelColor,
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

  @override
  void dispose() {
    _aciklamaController.dispose();
    _aciklamaFocusNode.dispose();
    _searchBinaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F5),
      appBar: AppBar(
        title: const Text(
          'Kırtasiye Malzemesi İstek',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                  'Satın Alma İsteğinde Bulunulan Okullar',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
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
                KeyedSubtree(
                  key: _aciklamaKey,
                  child: AciklamaFieldWidget(
                    controller: _aciklamaController,
                    focusNode: _aciklamaFocusNode,
                    labelText: 'Açıklama',
                  ),
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
                                          SarfMalzemeUrunEkleScreen(
                                            initialBilgi: urun,
                                            talepTuru: 'Kırtasiye',
                                          ),
                                    ),
                                  ).then((result) {
                                    if (result != null) {
                                      setState(() {
                                        _urunler[index] = result;
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  color: Colors.white,
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
                                                (urun.anaKategori ?? '').trim();
                                            final altKategori =
                                                (urun.altKategori ?? '').trim();
                                            final urunDetay =
                                                (urun.urunDetay ?? '').trim();

                                            final miktar = urun.miktar ?? 0;
                                            final birim =
                                                ((urun.olcuBirimi ?? '')
                                                            .trim()
                                                            .isNotEmpty
                                                        ? urun.olcuBirimi
                                                        : urun.olcuBirimiKisaltma)
                                                    ?.trim();

                                            String line3 =
                                                '$miktar${(birim ?? '').isNotEmpty ? ' $birim' : ''}';

                                            // Display logic based on user request:
                                            // "Ürün Alt Kategorisi" (Bold)
                                            // "Ürün Detayı" (Font +1 -> 15)
                                            // "Miktar Birim" (Font +1 -> 15)

                                            // Usage: If altKategori exists, use it as title. If not, fallback to anaKategori.
                                            final titleText =
                                                altKategori.isNotEmpty
                                                ? altKategori
                                                : anaKategori;
                                            // Since we are showing only Subcategory as title (if exists), we avoid "Main - Sub".

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  titleText,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                if (urunDetay.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    urunDetay,
                                                    style: TextStyle(
                                                      fontSize:
                                                          15, // +1px as requested
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                Text(
                                                  line3,
                                                  style: TextStyle(
                                                    fontSize:
                                                        15, // +1px as requested
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
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
                      final result = await Navigator.push<SatinAlmaUrunBilgisi>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SarfMalzemeUrunEkleScreen(
                            talepTuru: 'Kırtasiye',
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _urunler.add(result);
                        });
                      }

                      // After returning, scroll to submit button and unfocus
                      if (mounted) {
                        FocusScope.of(context).unfocus();
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _scrollToWidget(_gonderButtonKey);
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.gradientStart,
                      size: 28,
                    ),
                    label: const Text(
                      'Ürün Ekle',
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
                const SizedBox(height: 24),
                // Fiyat Teklifi / Sözleşme Ekle
                Text(
                  'Dosya / Fotoğraf Yükle',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.inputLabelColor,
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
                const SizedBox(height: 16),
                Text(
                  'Dosyaların İçeriğini Belirtiniz',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.inputLabelColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fiyatTeklifIcerikController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Dosyaların içeriğini belirtiniz.',
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.gradientStart,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 32),
                DecoratedBox(
                  key: _gonderButtonKey,
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
    );
  }
}

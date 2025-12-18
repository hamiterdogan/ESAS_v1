import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/generic_summary_bottom_sheet.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokuman_tur_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_baski_istek_req.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart';

class DokumantasyonBaskiIstekScreen extends ConsumerStatefulWidget {
  const DokumantasyonBaskiIstekScreen({super.key});

  @override
  ConsumerState<DokumantasyonBaskiIstekScreen> createState() =>
      _DokumantasyonBaskiIstekScreenState();
}

class _DokumantasyonBaskiIstekScreenState
    extends ConsumerState<DokumantasyonBaskiIstekScreen> {
  late DateTime _teslimTarihi;
  late final TextEditingController _aciklamaController;

  // Doküman Türü
  List<DokumanTurModel> _dokumanTurleri = [];
  DokumanTurModel? _selectedDokumanTuru;
  bool _isLoadingDokumanTurleri = false;

  // Baskı Adedi & Sayfa Sayısı
  int _baskiAdedi = 1;
  int _sayfaSayisi = 1;
  late final TextEditingController _baskiAdediController;
  late final TextEditingController _sayfaSayisiController;

  // Baskı Boyutu
  String _baskiBoyutu = 'A4'; // Default A4
  List<String> _baskiBoyutlari = [];
  bool _isLoadingBaskiBoyutlari = false;

  // Toggles
  bool _isRenkliBaski = false;
  bool _isArkaliOnlu = false;
  bool _isKopyaElden = false;

  // File Upload
  List<File> _selectedFiles = [];
  TextEditingController _dosyaIcerikController = TextEditingController();

  // Class Selection
  final Set<String> _selectedOkulKodu = {};
  final Set<String> _selectedSeviye = {};
  final Set<String> _selectedSinif = {};
  List<String> _okulKoduList = [];
  List<String> _seviyeList = [];
  List<String> _sinifList = [];
  // Initial lists to preserve original data
  List<String> _initialOkulKoduList = [];
  List<String> _initialSeviyeList = [];
  List<String> _initialSinifList = [];

  bool _classSheetLoading = false;
  String? _classSheetError;
  String _currentFilterPage = '';
  int _totalStudentCount = 0;

  // Lock mechanism for multi-tap prevention
  bool _isActionInProgress = false;
  final FocusNode _dosyaIcerikFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _teslimTarihi = DateTime.now().add(const Duration(days: 2));
    _aciklamaController = TextEditingController();
    _dosyaIcerikController = TextEditingController();
    _baskiAdediController = TextEditingController(text: _baskiAdedi.toString());
    _sayfaSayisiController = TextEditingController(
      text: _sayfaSayisi.toString(),
    );

    _fetchDokumanTurleri();
    _fetchBaskiBoyutlari();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _dosyaIcerikController.dispose();
    _baskiAdediController.dispose();
    _sayfaSayisiController.dispose();
    _dosyaIcerikFocusNode.dispose();
    super.dispose();
  }

  // Accumulative class selection (with counts)
  final List<_SelectedClass> _accumulatedClasses = [];

  bool get _hasInitialCache =>
      _initialOkulKoduList.isNotEmpty &&
      _initialSeviyeList.isNotEmpty &&
      _initialSinifList.isNotEmpty;

  void _showBlockingLoadingDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6), // Dim background further
      builder: (dialogContext) {
        return Center(
          child: Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              color: Colors.transparent, // Show only the indicator
              borderRadius: BorderRadius.circular(32),
            ),
            alignment: Alignment.center,
            child: const BrandedLoadingIndicator(size: 153, strokeWidth: 24),
          ),
        );
      },
    );
  }

  void _hideBlockingLoadingDialog() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _fetchDokumanTurleri() async {
    setState(() {
      _isLoadingDokumanTurleri = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/DokumantasyonIstek/DokumanTuruGetir');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _dokumanTurleri = data
              .map((e) => DokumanTurModel.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching dokuman turleri: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doküman türleri yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDokumanTurleri = false;
        });
      }
    }
  }

  Future<void> _fetchBaskiBoyutlari() async {
    setState(() {
      _isLoadingBaskiBoyutlari = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/DokumantasyonIstek/BaskiBoyutuGetir');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _baskiBoyutlari = data.map((e) => e.toString()).toList();
          // Ensure A4 is selected if available
          if (!_baskiBoyutlari.contains(_baskiBoyutu) &&
              _baskiBoyutlari.isNotEmpty) {
            _baskiBoyutu = _baskiBoyutlari.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching baski boyutlari: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Baskı boyutları yüklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBaskiBoyutlari = false;
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
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
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.paths.map((path) => File(path!)));
        });
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dosya seçimi başarısız: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _updateBaskiAdedi(int value) {
    if (value < 1 || value > 9999) return;
    setState(() {
      _baskiAdedi = value;
      _baskiAdediController.text = value.toString();
      _baskiAdediController.selection = TextSelection.fromPosition(
        TextPosition(offset: _baskiAdediController.text.length),
      );
    });
  }

  void _updateSayfaSayisi(int value) {
    if (value < 1 || value > 9999) return;
    setState(() {
      _sayfaSayisi = value;
      _sayfaSayisiController.text = value.toString();
      _sayfaSayisiController.selection = TextSelection.fromPosition(
        TextPosition(offset: _sayfaSayisiController.text.length),
      );
    });
  }

  void _showDokumanTuruBottomSheet() {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Doküman Türü Seçiniz',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isLoadingDokumanTurleri)
                const Center(
                  child: BrandedLoadingIndicator(size: 48, strokeWidth: 3),
                )
              else if (_dokumanTurleri.isEmpty)
                const Center(child: Text('Doküman türü bulunamadı'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dokumanTurleri.length,
                    itemBuilder: (context, index) {
                      final item = _dokumanTurleri[index];
                      return ListTile(
                        leading: _selectedDokumanTuru?.id == item.id
                            ? const Icon(
                                Icons.check,
                                color: AppColors.gradientStart,
                              )
                            : const SizedBox(width: 24), // Placeholder
                        title: Text(item.tur),
                        onTap: () {
                          setState(() {
                            _selectedDokumanTuru = item;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _isActionInProgress = false);
    });
  }

  void _showBaskiBoyutuBottomSheet() {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Baskı Boyutu Seçiniz',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (_isLoadingBaskiBoyutlari)
                const Center(
                  child: BrandedLoadingIndicator(size: 48, strokeWidth: 3),
                )
              else if (_baskiBoyutlari.isEmpty)
                const Center(child: Text('Baskı boyutu bulunamadı'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _baskiBoyutlari.length,
                    itemBuilder: (context, index) {
                      final item = _baskiBoyutlari[index];
                      return ListTile(
                        leading: _baskiBoyutu == item
                            ? const Icon(
                                Icons.check,
                                color: AppColors.gradientStart,
                              )
                            : const SizedBox(width: 24),
                        title: Text(item),
                        onTap: () {
                          setState(() {
                            _baskiBoyutu = item;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) setState(() => _isActionInProgress = false);
    });
  }

  void _submit() {
    if (_isActionInProgress) return;

    // Validations
    if (_selectedDokumanTuru == null) {
      _showStatusBottomSheet('Lütfen doküman türünü seçiniz.', isError: true);
      return;
    }

    // Açıklama validation (Binek araç ekranı ile aynı)
    if (_aciklamaController.text.length < 30) {
      _showStatusBottomSheet(
        'Lütfen en az 30 karakter olacak şekilde açıklama giriniz',
        isError: true,
      );
      return;
    }

    if (!_isKopyaElden) {
      if (_selectedFiles.isEmpty) {
        _showStatusBottomSheet(
          'Lütfen en az bir dosya seçiniz.',
          isError: true,
        );
        return;
      }
      if (_dosyaIcerikController.text.trim().isEmpty) {
        _dosyaIcerikFocusNode.requestFocus();
        _showStatusBottomSheet(
          'Lütfen dosya içeriğini belirtiniz.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isActionInProgress = true);

    // Calculate lists and totals
    final visibleClasses = _accumulatedClasses
        .where((e) => e.ogrenciSayisi > 0)
        .toList();
    final classesToUse = visibleClasses.isNotEmpty
        ? visibleClasses
        : _accumulatedClasses;

    final totalStudents = classesToUse.fold<int>(
      0,
      (p, c) => p + c.ogrenciSayisi,
    );

    // Map OkullarSatir
    final okullarSatir = classesToUse.map((e) {
      String seviye = '';
      if (e.sinif.length >= 2) {
        seviye = e.sinif.substring(0, 2);
      } else {
        seviye = e.sinif;
      }

      return OkulSatirItem(okulKodu: e.okul, sinif: e.sinif, seviye: seviye);
    }).toList();

    // Prepare Request Object
    final request = DokumantasyonBaskiIstekReq(
      teslimTarihi: _teslimTarihi,
      baskiAdedi: _baskiAdedi,
      kagitTalebi: _baskiBoyutu,
      dokumanTuru: _selectedDokumanTuru?.tur ?? '',
      aciklama: _aciklamaController.text,
      baskiTuru: _isRenkliBaski ? 'Renkli Baskı' : 'Siyah-Beyaz Baskı',
      onluArkali: _isArkaliOnlu,
      kopyaElden: _isKopyaElden,
      formFile: _selectedFiles
          .map((e) => e.path.split(Platform.pathSeparator).last)
          .toList(),
      dosyaAciklama: _dosyaIcerikController.text,
      sayfaSayisi: _sayfaSayisi,
      toplamSayfa: _baskiAdedi * _sayfaSayisi,
      ogrenciSayisi: totalStudents,
      okullarSatir: okullarSatir,
    );

    // Summary Items
    final summaryItems = <GenericSummaryItem>[
      GenericSummaryItem(
        label: 'Teslim Tarihi',
        value:
            '${_teslimTarihi.day.toString().padLeft(2, '0')}.${_teslimTarihi.month.toString().padLeft(2, '0')}.${_teslimTarihi.year}',
        multiLine: false,
      ),
      GenericSummaryItem(
        label: 'Doküman Türü',
        value: _selectedDokumanTuru?.tur ?? '-',
        multiLine: false,
      ),
      GenericSummaryItem(
        label: 'Baskı Özellikleri',
        value: [
          '$_baskiAdedi Adet, $_sayfaSayisi Sayfa (Toplam: ${_baskiAdedi * _sayfaSayisi})',
          'Boyut: $_baskiBoyutu',
          _isRenkliBaski ? 'Renkli Baskı' : 'Siyah-Beyaz Baskı',
          _isArkaliOnlu ? 'Arkalı Önlü' : 'Tek Yön',
        ].join('\n'),
        multiLine: true,
      ),
      GenericSummaryItem(
        label: 'Teslimat Şekli',
        value: _isKopyaElden ? 'Kopya elden teslim edilecek' : 'Dosya yüklendi',
        multiLine: false,
      ),
      GenericSummaryItem(
        label: 'Açıklama',
        value: _aciklamaController.text.isEmpty
            ? '-'
            : _aciklamaController.text,
        multiLine: true,
      ),
    ];

    if (!_isKopyaElden) {
      if (_selectedFiles.isNotEmpty) {
        summaryItems.add(
          GenericSummaryItem(
            label: 'Dosyalar',
            value: _selectedFiles
                .map((e) => e.path.split(Platform.pathSeparator).last)
                .join('\n'),
            multiLine: true,
          ),
        );
      }

      summaryItems.add(
        GenericSummaryItem(
          label: 'Dosya İçeriği',
          value: _dosyaIcerikController.text,
          multiLine: true,
        ),
      );
    }

    // Add selected classes summary
    if (classesToUse.isNotEmpty) {
      final classDetails = classesToUse
          .map((e) => '${e.okul} - ${e.sinif} (${e.ogrenciSayisi} öğrenci)')
          .join('\n');

      summaryItems.add(
        GenericSummaryItem(
          label: 'Seçilen Sınıflar',
          value: 'Toplam $totalStudents Öğrenci\n$classDetails',
          multiLine: true,
        ),
      );
    }

    setState(() => _isActionInProgress = false);

    showGenericSummaryBottomSheet(
      context: context,
      requestData: request
          .toJson(), // Use toJson for generic display if needed, but we already manually built summaryItems
      title: 'Dokümantasyon Baskı İstek',
      summaryItems: summaryItems,
      showRequestData: false,
      onConfirm: () async {
        final repo = ref.read(dokumantasyonIstekRepositoryProvider);
        final result = await repo.dokumantasyonBaskiIstekEkle(
          request: request,
          files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        );

        if (result is Failure) {
          throw Exception(result.message);
        }
      },
      onSuccess: () {
        ref.invalidate(dokumantasyonDevamEdenTaleplerProvider);
        _showStatusBottomSheet(
          'Dokümantasyon baskı isteği başarıyla gönderildi',
        );
      },
      onError: (error) {
        _showStatusBottomSheet(error, isError: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Dokümantasyon Baskı İstek',
          style: TextStyle(color: Colors.white),
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
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teslim Tarihi Label Outside for Layout
              Text(
                'Teslim edilecek tarih',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: DatePickerBottomSheetWidget(
                      // Label is handled externally for alignment purposes
                      label: null,
                      initialDate: _teslimTarihi,
                      minDate: DateTime.now().add(const Duration(days: 2)),
                      maxDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (date) {
                        setState(() {
                          _teslimTarihi = date;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Placeholder for spacing, similar to A4 Screen if we had an info icon
                  // Or leave empty if no icon requested here. The user didn't request info icon here.
                  // But to keep consistency with A4 screen layout (50% width), we need an Expanded empty box or similar.
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),

              // Doküman Türü
              Text(
                'Doküman Türü',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showDokumanTuruBottomSheet,
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
                      Text(
                        _selectedDokumanTuru?.tur ?? 'Seçiniz',
                        style: TextStyle(
                          color: _selectedDokumanTuru == null
                              ? Colors.grey.shade600
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Baskı Adedi & Sayfa Sayısı
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baskı Adedi',
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
                        _buildSpinnerRow(
                          _baskiAdedi,
                          _baskiAdediController,
                          _updateBaskiAdedi,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sayfa Sayısı',
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
                        _buildSpinnerRow(
                          _sayfaSayisi,
                          _sayfaSayisiController,
                          _updateSayfaSayisi,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Toplam Sayfa: ${_baskiAdedi * _sayfaSayisi}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize:
                        (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                            14) +
                        2,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Baskı Boyutu
              Text(
                'Baskı Boyutu',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showBaskiBoyutuBottomSheet,
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
                      Text(
                        _baskiBoyutu,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              AciklamaFieldWidget(controller: _aciklamaController),
              const SizedBox(height: 24),

              // Renkli Baskı Toggle
              Row(
                children: [
                  Switch(
                    value: _isRenkliBaski,
                    activeTrackColor: AppColors.gradientStart.withOpacity(0.5),
                    activeThumbColor: AppColors.gradientEnd,
                    onChanged: (value) {
                      setState(() {
                        _isRenkliBaski = value;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text('Renkli Baskı', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),

              // Arkalı Önlü Baskı Toggle
              Row(
                children: [
                  Switch(
                    value: _isArkaliOnlu,
                    activeTrackColor: AppColors.gradientStart.withOpacity(0.5),
                    activeThumbColor: AppColors.gradientEnd,
                    onChanged: (value) {
                      setState(() {
                        _isArkaliOnlu = value;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Arkalı Önlü Baskı',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              // Çoğaltılacak kopya elden gönderilecektir Toggle
              Row(
                children: [
                  Switch(
                    value: _isKopyaElden,
                    activeTrackColor: AppColors.gradientStart.withOpacity(0.5),
                    activeThumbColor: AppColors.gradientEnd,
                    onChanged: (value) {
                      setState(() {
                        _isKopyaElden = value;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Çoğaltılacak kopya elden teslim edilecektir',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (!_isKopyaElden) ...[
                const SizedBox(height: 24),

                // Basılacak Dosya
                Text(
                  'Basılacak Dosya',
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
                                file.path.split(Platform.pathSeparator).last,
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

                // Dosyaların içeriğini belirtiniz
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
                  focusNode: _dosyaIcerikFocusNode,
                  controller: _dosyaIcerikController,
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
              ],
              const SizedBox(height: 24),
              // Dokümanın istendiği sınıflar
              Text(
                'Dokümanın İstendiği Sınıflar',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _openSinifSecimBottomSheet,
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
                          'Yeni sınıf ekle',
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showSelectedClassesList,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _accumulatedClasses.isEmpty
                          ? 'Seçilen sınıflar'
                          : 'Seçilen sınıflar (${_accumulatedClasses.fold<int>(0, (p, c) => p + c.ogrenciSayisi)} öğrenci)',
                      style: const TextStyle(
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
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
                    onPressed: _submit,
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpinnerRow(
    int value,
    TextEditingController controller,
    Function(int) onUpdate,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > 1 ? () => onUpdate(value - 1) : null,
          child: Container(
            width: 44, // Slightly smaller to fit 2 in row? Or just 50 as before
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
              color: value > 1 ? Colors.black : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 4), // Small gap
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(fontSize: 17, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 9),
              ),
              onChanged: (val) {
                if (val.isEmpty) return;
                final intValue = int.tryParse(val);
                if (intValue == null) return;
                if (intValue < 1) {
                  onUpdate(1);
                } else if (intValue > 9999) {
                  onUpdate(9999);
                } else {
                  onUpdate(intValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: value < 9999 ? () => onUpdate(value + 1) : null,
          child: Container(
            width: 44,
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
              color: value < 9999 ? Colors.black : Colors.grey.shade300,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSinifSecimBottomSheet() async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      _showBlockingLoadingDialog();
      // UI'nin dialog'u çizmesi için bir frame ver.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      setState(() {
        _classSheetLoading = true;
        _classSheetError = null;
      });

      if (!_hasInitialCache) {
        // Initial load: Get everything to populate initial lists
        final repo = ref.read(aracTalepRepositoryProvider);
        final result = await repo.ogrenciFiltrele();

        switch (result) {
          case Success(:final data):
            setState(() {
              _initialOkulKoduList = data.okulKodu; // All schools
              _initialSeviyeList = data.seviye; // All levels (initially)
              _initialSinifList = data.sinif; // All classes (initially)

              _okulKoduList = _initialOkulKoduList;
              _seviyeList = _initialSeviyeList;
              _sinifList = _initialSinifList;

              _classSheetLoading = false;
            });
          case Failure(:final message):
            setState(() {
              _classSheetLoading = false;
              _classSheetError = message;
            });
            _hideBlockingLoadingDialog();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Veri yüklenemedi: $message')),
              );
            }
            return;
          case Loading():
            _hideBlockingLoadingDialog();
            return;
        }
      }

      // Load current selections
      final localSelectedOkul = {..._selectedOkulKodu};
      final localSelectedSeviye = {..._selectedSeviye};
      final localSelectedSinif = {..._selectedSinif};
      int localStudentCount = _totalStudentCount;

      // Temp set for detail pages (Discard logic)
      final Set<String> tempSelectedItems = {};

      // Perform an initial hierarchical refresh to ensure lists are consistent with selections
      await _refreshClassFilterData(
        localSelectedOkul: localSelectedOkul,
        localSelectedSeviye: localSelectedSeviye,
        localSelectedSinif: localSelectedSinif,
        rebuild: (fn) =>
            fn(), // Execute synchronously without rebuilding main screen to prevent flicker
        updateSeviyeList: true,
        updateSinifList: true,
        onUpdateCount: (c) => localStudentCount = c,
      );

      _hideBlockingLoadingDialog();
      _currentFilterPage = '';

      if (!mounted) return;

      await showModalBottomSheet(
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Seçilen öğrenci sayısı: $localStudentCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: localStudentCount == 0
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
                      tempSelectedItems, // Use temp
                      localSelectedSeviye,
                      localSelectedSinif,
                      onUpdateCount: (c) =>
                          setModalState(() => localStudentCount = c),
                    );
                  case 'seviye':
                    return _buildSeviyeFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems, // Use temp
                      localSelectedOkul,
                      localSelectedSinif,
                      onUpdateCount: (c) =>
                          setModalState(() => localStudentCount = c),
                    );
                  case 'sinif':
                    return _buildSinifFilterPage(
                      setModalState,
                      scrollController,
                      tempSelectedItems, // Use temp
                      localSelectedOkul,
                      localSelectedSeviye,
                      onUpdateCount: (c) =>
                          setModalState(() => localStudentCount = c),
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
                                Icon(
                                  Icons.arrow_back_ios,
                                  size: 20,
                                  color: AppColors.gradientStart,
                                ),
                                Text(
                                  'Geri',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.gradientStart,
                                  ),
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

                              await _refreshClassFilterData(
                                localSelectedOkul: localSelectedOkul,
                                localSelectedSeviye: localSelectedSeviye,
                                localSelectedSinif: localSelectedSinif,
                                rebuild: setModalState,
                                onUpdateCount: (c) =>
                                    setModalState(() => localStudentCount = c),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 66),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_currentFilterPage.isEmpty) {
                              // Uygula
                              if (localSelectedOkul.isEmpty &&
                                  localSelectedSeviye.isEmpty &&
                                  localSelectedSinif.isEmpty) {
                                // No filters chosen; avoid selecting everyone
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Herhangi bir filtre seçilmedi, öğrenci eklenmedi.',
                                      ),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Fetch student counts for the current selection
                              final resp = await _fetchFilters(
                                localSelectedOkul,
                                localSelectedSeviye,
                                localSelectedSinif,
                              );

                              if (resp != null && mounted) {
                                // Build counts per "Okul - Sınıf"
                                final Map<String, int> counts = {};
                                for (final o in resp.ogrenci) {
                                  final key = '${o.okulKodu} - ${o.sinif}';
                                  counts[key] = (counts[key] ?? 0) + 1;
                                }

                                setState(() {
                                  for (final entry in counts.entries) {
                                    _upsertSelectedClass(
                                      entry.key,
                                      entry.value,
                                    );
                                  }

                                  // Seçim listesindeki ama count bulunmayanları da ekle (0 öğrenci ile)
                                  for (final sinif in localSelectedSinif) {
                                    final okullar = localSelectedOkul.isEmpty
                                        ? _initialOkulKoduList
                                        : localSelectedOkul;

                                    for (final okul in okullar) {
                                      final key = '$okul - $sinif';
                                      if (!counts.containsKey(key)) {
                                        _upsertSelectedClass(key, 0);
                                      }
                                    }
                                  }

                                  // Clear filters for next use
                                  _selectedOkulKodu.clear();
                                  _selectedSeviye.clear();
                                  _selectedSinif.clear();
                                  _totalStudentCount = 0;
                                });

                                Navigator.pop(context);
                              }
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
                              }

                              // Refresh downstream lists logic
                              final updateSeviye = _currentFilterPage == 'okul';
                              final updateSinif =
                                  _currentFilterPage == 'okul' ||
                                  _currentFilterPage == 'seviye';

                              await _refreshClassFilterData(
                                localSelectedOkul: localSelectedOkul,
                                localSelectedSeviye: localSelectedSeviye,
                                localSelectedSinif: localSelectedSinif,
                                rebuild: setModalState,
                                updateSeviyeList: updateSeviye,
                                updateSinifList: updateSinif,
                                onUpdateCount: (c) =>
                                    setModalState(() => localStudentCount = c),
                              );

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
    } catch (e) {
      debugPrint('Error in class sheet: $e');
      _hideBlockingLoadingDialog();
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<OgrenciFilterResponse?> _fetchFilters(
    Set<String> selectedOkulKodlari,
    Set<String> selectedSeviyeler,
    Set<String> selectedSiniflar,
  ) async {
    final repo = ref.read(aracTalepRepositoryProvider);
    // Convert empty sets to ["0"] for API wildcard behavior
    final apiOkul = selectedOkulKodlari.isEmpty ? {'0'} : selectedOkulKodlari;
    final apiSeviye = selectedSeviyeler.isEmpty ? {'0'} : selectedSeviyeler;
    final apiSinif = selectedSiniflar.isEmpty ? {'0'} : selectedSiniflar;

    final result = await repo.mobilOgrenciFiltrele(
      okulKodlari: apiOkul,
      seviyeler: apiSeviye,
      siniflar: apiSinif,
      kulupler: {'0'}, // Need to send 0 or empty? Based on req: "0"
      takimlar: {'0'},
    );

    switch (result) {
      case Success(:final data):
        return data;
      case Failure(:final message):
        debugPrint('Filtre hatası: $message');
        return null;
      case Loading():
        return null;
    }
  }

  void _showSelectedClassesList() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setStartModalState) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Seçilen Sınıflar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _accumulatedClasses.clear();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Tümünü Temizle',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final displayList = _accumulatedClasses
                              .where((e) => e.ogrenciSayisi > 0)
                              .toList();

                          if (displayList.isEmpty) {
                            return const Center(
                              child: Text('Görüntülenecek sınıf yok.'),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: displayList.length,
                            itemBuilder: (context, index) {
                              final item = displayList[index];
                              final label =
                                  '${item.okul} - ${item.sinif} (${item.ogrenciSayisi} öğrenci)';
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade100,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFF424242),
                                    ),
                                    onPressed: () {
                                      setStartModalState(() {
                                        _accumulatedClasses.remove(item);
                                      });
                                      // Also update main screen
                                      setState(() {});

                                      // If no visible items left, verify state
                                      final remainingVisible =
                                          _accumulatedClasses.where(
                                            (e) => e.ogrenciSayisi > 0,
                                          );
                                      if (remainingVisible.isEmpty) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 66),
                      child: SizedBox(
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
                              color: Colors.white,
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
            );
          },
        );
      },
    );
  }

  Future<void> _refreshClassFilterData({
    required Set<String> localSelectedOkul,
    required Set<String> localSelectedSeviye,
    required Set<String> localSelectedSinif,
    required StateSetter rebuild,
    bool updateSeviyeList = false,
    bool updateSinifList = false,
    Function(int)? onUpdateCount,
  }) async {
    // 1. Update Seviye List (Depends ONLY on School)
    if (updateSeviyeList) {
      final respSeviye = await _fetchFilters(
        localSelectedOkul, // Selected Schools
        {}, // No Level Filter
        {}, // No Class Filter
      );
      if (respSeviye != null) {
        rebuild(() {
          _seviyeList = respSeviye.seviye;
          localSelectedSeviye.retainAll(_seviyeList.toSet());
        });
      }
    }

    // 2. Update Sinif List (Depends on School AND Level)
    if (updateSinifList) {
      final respSinif = await _fetchFilters(
        localSelectedOkul,
        localSelectedSeviye,
        {}, // No Class Filter
      );
      if (respSinif != null) {
        rebuild(() {
          _sinifList = respSinif.sinif;
          localSelectedSinif.retainAll(_sinifList.toSet());
        });
      }
    }

    // 3. Always Calculate Student Count (Depends on School AND Level AND Class)
    // Check if all filters are empty
    final bool filtersEmpty =
        localSelectedOkul.isEmpty &&
        localSelectedSeviye.isEmpty &&
        localSelectedSinif.isEmpty;

    if (filtersEmpty) {
      rebuild(() {
        if (onUpdateCount != null) {
          onUpdateCount(0);
        } else {
          _totalStudentCount = 0;
        }
      });
    } else {
      final respCount = await _fetchFilters(
        localSelectedOkul,
        localSelectedSeviye,
        localSelectedSinif,
      );

      if (respCount != null) {
        rebuild(() {
          if (onUpdateCount != null) {
            onUpdateCount(respCount.ogrenci.length);
          } else {
            _totalStudentCount = respCount.ogrenci.length;
          }
        });
      }
    }
  }

  void _upsertSelectedClass(String key, int count) {
    final parts = key.split(' - ');
    final okul = parts.length >= 2 ? parts[0].trim() : 'Okul';
    final sinif = parts.length >= 2 ? parts[1].trim() : key.trim();

    final idx = _accumulatedClasses.indexWhere(
      (e) => e.okul == okul && e.sinif == sinif,
    );

    if (idx >= 0) {
      _accumulatedClasses[idx] = _accumulatedClasses[idx].copyWith(
        ogrenciSayisi: count,
      );
    } else {
      _accumulatedClasses.add(
        _SelectedClass(okul: okul, sinif: sinif, ogrenciSayisi: count),
      );
    }
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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

  Widget _buildOkulFilterPage(
    StateSetter setModalState,
    ScrollController scrollController,
    Set<String> localSelectedOkul,
    Set<String> localSelectedSeviye,
    Set<String> localSelectedSinif, {
    required ValueChanged<int> onUpdateCount,
  }) {
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedOkul
                    ..clear()
                    ..addAll(okulSource);
                  localSelectedSeviye.clear();
                  localSelectedSinif.clear();
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = localSelectedOkul.contains(item);
                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    onChanged: (val) {
                      innerSetState(() {
                        if (val == true) {
                          localSelectedOkul.add(item);
                        } else {
                          localSelectedOkul.remove(item);
                        }
                      });

                      _refreshClassFilterData(
                        localSelectedOkul: localSelectedOkul,
                        localSelectedSeviye: localSelectedSeviye,
                        localSelectedSinif: localSelectedSinif,
                        rebuild: innerSetState,
                        onUpdateCount: onUpdateCount,
                      );
                    },
                    title: Text(item),
                    activeColor: const Color(0xFF014B92),
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
    Set<String> localSelectedSinif, {
    required ValueChanged<int> onUpdateCount,
  }) {
    if (_seviyeList.isEmpty) {
      return const Center(child: Text('Seviye verisi bulunamadı'));
    }

    return StatefulBuilder(
      builder: (context, innerSetState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectActions(
              onClear: () {
                innerSetState(() {
                  localSelectedSeviye.clear();
                  localSelectedSinif.clear();
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedSeviye
                    ..clear()
                    ..addAll(_seviyeList);
                  localSelectedSinif.clear();
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _seviyeList.length,
                itemBuilder: (context, index) {
                  final item = _seviyeList[index];
                  final isSelected = localSelectedSeviye.contains(item);
                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    onChanged: (val) {
                      innerSetState(() {
                        if (val == true) {
                          localSelectedSeviye.add(item);
                        } else {
                          localSelectedSeviye.remove(item);
                        }
                      });

                      _refreshClassFilterData(
                        localSelectedOkul: localSelectedOkul,
                        localSelectedSeviye: localSelectedSeviye,
                        localSelectedSinif: localSelectedSinif,
                        rebuild: innerSetState,
                        onUpdateCount: onUpdateCount,
                      );
                    },
                    title: Text(item),
                    activeColor: const Color(0xFF014B92),
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
    Set<String> localSelectedSeviye, {
    required ValueChanged<int> onUpdateCount,
  }) {
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
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
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedSinif
                    ..clear()
                    ..addAll(filtered);
                });
                _refreshClassFilterData(
                  localSelectedOkul: localSelectedOkul,
                  localSelectedSeviye: localSelectedSeviye,
                  localSelectedSinif: localSelectedSinif,
                  rebuild: innerSetState,
                  onUpdateCount: onUpdateCount,
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isSelected = localSelectedSinif.contains(item);
                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    onChanged: (val) {
                      innerSetState(() {
                        if (val == true) {
                          localSelectedSinif.add(item);
                        } else {
                          localSelectedSinif.remove(item);
                        }
                      });

                      _refreshClassFilterData(
                        localSelectedOkul: localSelectedOkul,
                        localSelectedSeviye: localSelectedSeviye,
                        localSelectedSinif: localSelectedSinif,
                        rebuild: innerSetState,
                        onUpdateCount: onUpdateCount,
                      );
                    },
                    title: Text(item),
                    activeColor: const Color(0xFF014B92),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
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

  String _buildClassSelectionSummary() {
    if (_totalStudentCount > 0) {
      return '$_totalStudentCount öğrenci seçildi';
    }

    if (_selectedSinif.isNotEmpty) {
      if (_selectedSinif.length <= 2) return _selectedSinif.join(', ');
      return '${_selectedSinif.length} sınıf seçildi';
    }
    if (_selectedSeviye.isNotEmpty) {
      if (_selectedSeviye.length <= 2) return _selectedSeviye.join(', ');
      return '${_selectedSeviye.length} seviye seçildi';
    }
    if (_selectedOkulKodu.isNotEmpty) {
      if (_selectedOkulKodu.length <= 2) return _selectedOkulKodu.join(', ');
      return '${_selectedOkulKodu.length} okul seçildi';
    }
    return 'Sınıf Seçiniz';
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
                  if (!isError) {
                    context.go('/dokumantasyon_istek');
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
}

class _SelectedClass {
  final String okul;
  final String sinif;
  final int ogrenciSayisi;

  const _SelectedClass({
    required this.okul,
    required this.sinif,
    required this.ogrenciSayisi,
  });

  _SelectedClass copyWith({int? ogrenciSayisi}) {
    return _SelectedClass(
      okul: okul,
      sinif: sinif,
      ogrenciSayisi: ogrenciSayisi ?? this.ogrenciSayisi,
    );
  }
}

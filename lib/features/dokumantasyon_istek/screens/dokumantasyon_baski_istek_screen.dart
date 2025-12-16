import 'dart:io';


import 'package:file_picker/file_picker.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _teslimTarihi = DateTime.now().add(const Duration(days: 2));
    _aciklamaController = TextEditingController();
    _dosyaIcerikController = TextEditingController();
    _baskiAdediController = TextEditingController(text: _baskiAdedi.toString());
    _sayfaSayisiController =
        TextEditingController(text: _sayfaSayisi.toString());

    _fetchDokumanTurleri();
    _fetchBaskiBoyutlari();
  }

  @override
  void dispose() {
    _aciklamaController.dispose();
    _dosyaIcerikController.dispose();
    _baskiAdediController.dispose();
    _sayfaSayisiController.dispose();
    super.dispose();
  }

  Future<void> _fetchDokumanTurleri() async {
    setState(() {
      _isLoadingDokumanTurleri = true;
    });

    try {
      final dio = ref.read(dioProvider);
      final response =
          await dio.get('/DokumantasyonIstek/DokumanTuruGetir');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        setState(() {
          _dokumanTurleri =
              data.map((e) => DokumanTurModel.fromJson(e)).toList();
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
          'xlsx'
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya seçimi başarısız: $e')),
        );
      }
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingDokumanTurleri)
                const Center(child: CircularProgressIndicator())
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
                            ? const Icon(Icons.check,
                                color: AppColors.gradientStart)
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
            ],
          ),
        );
      },
    );
  }

  void _showBaskiBoyutuBottomSheet() {
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingBaskiBoyutlari)
                const Center(child: CircularProgressIndicator())
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
                            ? const Icon(Icons.check,
                                color: AppColors.gradientStart)
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
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    // Implement submit logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dokümantasyon baskı isteği hazırlandı (placeholder)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      fontSize: (Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.fontSize ??
                              14) +
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
                      fontSize: (Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.fontSize ??
                              14) +
                          1,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showDokumanTuruBottomSheet,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: (Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.fontSize ??
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
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: (Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.fontSize ??
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
                        fontSize: (Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.fontSize ??
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
                      fontSize: (Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.fontSize ??
                              14) +
                          1,
                    ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showBaskiBoyutuBottomSheet,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    child: Text('Arkalı Önlü Baskı', style: TextStyle(fontSize: 14)),
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
                    child: Text('Çoğaltılacak kopya elden teslim edilecektir', style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              if (!_isKopyaElden) ...[
                const SizedBox(height: 24),

                // Basılacak Dosya
                Text(
                  'Basılacak Dosya',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: (Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.fontSize ??
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
                        const Icon(Icons.cloud_upload_outlined,
                            size: 24, color: Colors.grey),
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
                            const Icon(Icons.insert_drive_file_outlined,
                                color: Colors.grey),
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
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 20),
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
                        fontSize: (Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.fontSize ??
                                14) +
                            1,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
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
                      fontSize: (Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.fontSize ??
                              14) +
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
                          _buildClassSelectionSummary(),
                          style: TextStyle(
                            color: _selectedSinif.isNotEmpty || _selectedSeviye.isNotEmpty || _selectedOkulKodu.isNotEmpty
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
  setState(() {
    _classSheetLoading = true;
    _classSheetError = null;
  });

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
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenemedi: $message')),
        );
      }
      return;
    case Loading():
      return;
  }

  // Load current selections
  final localSelectedOkul = {..._selectedOkulKodu};
  final localSelectedSeviye = {..._selectedSeviye};
  final localSelectedSinif = {..._selectedSinif};

   // Temp set for detail pages (Discard logic)
  final Set<String> tempSelectedItems = {};
  
  // Perform an initial hierarchical refresh to ensure lists are consistent with selections
  await _refreshClassFilterData(
    localSelectedOkul: localSelectedOkul,
    localSelectedSeviye: localSelectedSeviye,
    localSelectedSinif: localSelectedSinif,
    rebuild: setState, // Use main setState initially
    updateSeviyeList: true,
    updateSinifList: true,
  );

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    'Seçilen öğrenci sayısı: $_totalStudentCount',
                    style: TextStyle(
                      fontSize: 19,
                      color: _totalStudentCount == 0 ? Colors.red.shade700 : AppColors.gradientStart,
                      fontWeight: FontWeight.w500,
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
                );
              case 'seviye':
                return _buildSeviyeFilterPage(
                  setModalState,
                  scrollController,
                  tempSelectedItems, // Use temp
                  localSelectedOkul,
                  localSelectedSinif,
                );
              case 'sinif':
                return _buildSinifFilterPage(
                  setModalState,
                  scrollController,
                  tempSelectedItems, // Use temp
                  localSelectedOkul,
                  localSelectedSeviye,
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
                                Icon(Icons.arrow_back_ios, size: 20, color: AppColors.gradientStart),
                                Text(
                                  'Geri', 
                                  style: TextStyle(fontSize: 16, color: AppColors.gradientStart)
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_currentFilterPage.isEmpty) {
                             // Uygula
                            setState(() {
                              _selectedOkulKodu
                                ..clear()
                                ..addAll(localSelectedOkul);
                              _selectedSeviye
                                ..clear()
                                ..addAll(localSelectedSeviye);
                              _selectedSinif
                                ..clear()
                                ..addAll(localSelectedSinif);
                              
                              // Update expected values based on count? 
                              // Actually the doc print request uses _selectedSinif for logic elsewhere maybe?
                              // But we need to make sure state is updated.
                            });
                            Navigator.pop(context);
                          } else {
                            // But here "Tamam" acts like "Back" + "Apply Filter Logic".
                            
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
                ),
              ],
            );
          },
        ),
      ),
    );
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

  Future<void> _refreshClassFilterData({
    required Set<String> localSelectedOkul,
    required Set<String> localSelectedSeviye,
    required Set<String> localSelectedSinif,
    required StateSetter rebuild,
    bool updateSeviyeList = false,
    bool updateSinifList = false,
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
  final bool filtersEmpty = localSelectedOkul.isEmpty &&
      localSelectedSeviye.isEmpty &&
      localSelectedSinif.isEmpty;

  if (filtersEmpty) {
     rebuild(() {
      _totalStudentCount = 0;
    });
  } else {
    final respCount = await _fetchFilters(
      localSelectedOkul,
      localSelectedSeviye,
      localSelectedSinif,
    );
       
    if (respCount != null) {
      rebuild(() {
        _totalStudentCount = respCount.ogrenci.length;
      });
    }
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
                  ]
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
    Set<String> localSelectedSinif,
  ) {
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
    Set<String> localSelectedSinif,
  ) {
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
    Set<String> localSelectedSeviye,
  ) {
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
              },
              onSelectAll: () {
                innerSetState(() {
                  localSelectedSinif
                    ..clear()
                    ..addAll(filtered);
                });
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
}

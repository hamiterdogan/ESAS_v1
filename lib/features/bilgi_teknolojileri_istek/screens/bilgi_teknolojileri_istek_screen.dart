import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:image_picker/image_picker.dart';

import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/screens/bilgi_teknolojileri_hizmet_ekle_screen.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/bilgi_teknolojileri_hizmet_data.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/date_picker_bottom_sheet_widget.dart';
import 'package:esas_v1/common/widgets/aciklama_field_widget.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/common/widgets/file_photo_upload_widget.dart';

class BilgiTeknolojileriIstekScreen extends ConsumerStatefulWidget {
  final String destekTuru;
  final String baslik;

  const BilgiTeknolojileriIstekScreen({
    super.key,
    this.destekTuru = 'bilgiTek',
    this.baslik = 'Bilgi Teknolojileri İstek',
  });

  @override
  ConsumerState<BilgiTeknolojileriIstekScreen> createState() =>
      _BilgiTeknolojileriIstekScreenState();
}

class _BilgiTeknolojileriIstekScreenState
    extends ConsumerState<BilgiTeknolojileriIstekScreen> {
  final List<File> _selectedFiles = [];
  final TextEditingController _dosyaIcerikController = TextEditingController();
  final FocusNode _dosyaIcerikFocusNode = FocusNode();
  final List<BilgiTeknolojileriHizmetData> _addedHizmetler = [];

  // Yeni eklenen field'lar
  final Set<String> _selectedBinaKodlari = <String>{};
  final TextEditingController _searchBinaController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final FocusNode _aciklamaFocusNode = FocusNode();
  final FocusNode _okulFocusNode = FocusNode();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _dosyaIcerikController.dispose();
    _dosyaIcerikFocusNode.dispose();
    _searchBinaController.dispose();
    _aciklamaController.dispose();
    _aciklamaFocusNode.dispose();
    _okulFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
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

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var pickedFile in result.files) {
            if (pickedFile.path != null) {
              final file = File(pickedFile.path!);
              // Check if file already exists
              if (!_selectedFiles.any((f) => f.path == file.path)) {
                _selectedFiles.add(file);
              }
            }
          }
        });
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

  bool _hasFormData() {
    if (_selectedBinaKodlari.isNotEmpty) return true;
    if (_selectedDate != null) return true;
    if (_aciklamaController.text.trim().isNotEmpty) return true;
    if (_addedHizmetler.isNotEmpty) return true;
    if (_dosyaIcerikController.text.trim().isNotEmpty) return true;
    if (_selectedFiles.isNotEmpty) return true;
    return false;
  }

  Future<bool> _showExitConfirmationDialog() async {
    return AppDialogs.showFormExitConfirm(context);
  }

  Future<void> _pickFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          final file = File(image.path);
          if (!_selectedFiles.any((f) => f.path == file.path)) {
            _selectedFiles.add(file);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kamera açılamadı: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            final file = File(image.path);
            if (!_selectedFiles.any((f) => f.path == file.path)) {
              _selectedFiles.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Galeri açılamadı: $e')));
      }
    }
  }

  // Okul seçimi helper metodları
  void _toggleSelection(String binaKodu) {
    setState(() {
      if (_selectedBinaKodlari.contains(binaKodu)) {
        _selectedBinaKodlari.remove(binaKodu);
      } else {
        _selectedBinaKodlari.add(binaKodu);
      }
    });
  }

  String _buildSelectedText() {
    if (_selectedBinaKodlari.isEmpty) return 'Okul seçiniz';
    if (_selectedBinaKodlari.length <= 2) {
      return '${_selectedBinaKodlari.length} okul seçildi';
    }
    return '${_selectedBinaKodlari.length} okul seçildi';
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
        return Consumer(
          builder: (context, ref, _) {
            final binalarAsync = ref.watch(satinAlmaBinalarProvider);

            return binalarAsync.when(
              loading: () => const SizedBox(
                height: 300,
                child: Center(child: BrandedLoadingIndicator(size: 80)),
              ),
              error: (error, stack) => SizedBox(
                height: 300,
                child: Center(child: Text('Hata: $error')),
              ),
              data: (binalar) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    final filteredBinalar = _searchBinaController.text.isEmpty
                        ? binalar
                        : binalar
                              .where(
                                (b) => b.binaAdi.toLowerCase().contains(
                                  _searchBinaController.text.toLowerCase(),
                                ),
                              )
                              .toList();

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.75,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Okul Seçiniz',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchBinaController,
                              decoration: InputDecoration(
                                hintText: 'Okul ara...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => _selectedBinaKodlari.clear(),
                                    );
                                    setModalState(() {});
                                  },
                                  child: const Text('Temizle'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(
                                      () => _selectedBinaKodlari.addAll(
                                        filteredBinalar.map((e) => e.binaKodu),
                                      ),
                                    );
                                    setModalState(() {});
                                  },
                                  child: const Text('Tümünü seç'),
                                ),
                              ],
                            ),
                            Expanded(
                              child: filteredBinalar.isEmpty
                                  ? const Center(
                                      child: Text('Eşleşen okul bulunamadı'),
                                    )
                                  : ListView.builder(
                                      itemCount: filteredBinalar.length,
                                      itemBuilder: (context, index) {
                                        final item = filteredBinalar[index];
                                        final isSelected = _selectedBinaKodlari
                                            .contains(item.binaKodu);
                                        return CheckboxListTile(
                                          title: Text(item.binaAdi),
                                          value: isSelected,
                                          onChanged: (_) {
                                            _toggleSelection(item.binaKodu);
                                            setModalState(() {});
                                          },
                                        );
                                      },
                                    ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Tamam'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text(
              widget.baslik,
              style: const TextStyle(
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
                // İsteğin Yapılacağı Okul/Bina Seçiniz
                Text(
                  'İsteğin Yapılacağı Okul/Bina Seçiniz*',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  focusNode: _okulFocusNode,
                  onTap: _showBinaBottomSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _buildSelectedText(),
                            style: TextStyle(
                              color: _selectedBinaKodlari.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // İstenen Son Çözüm Tarihi
                DatePickerBottomSheetWidget(
                  label: 'İstenen Son Çözüm Tarihi',
                  labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.primaryLight,
                  ),
                  initialDate: _selectedDate,
                  minDate: DateTime.now(),
                  maxDate: DateTime.now().add(const Duration(days: 365)),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Eklenen Hizmetler Listesi
                if (_addedHizmetler.isNotEmpty) ...[
                  ..._addedHizmetler.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hizmet = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Slidable(
                        key: ValueKey(hizmet),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            CustomSlidableAction(
                              onPressed: (context) async {
                                final result =
                                    await Navigator.push<
                                      BilgiTeknolojileriHizmetData
                                    >(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BilgiTeknolojileriHizmetEkleScreen(
                                              existingData: hizmet,
                                              destekTuru: widget.destekTuru,
                                            ),
                                      ),
                                    );

                                if (result != null) {
                                  setState(() {
                                    _addedHizmetler[index] = result;
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
                                  _addedHizmetler.removeAt(index);
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
                                hizmet.kategori,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (hizmet.hizmetDetayi.isNotEmpty)
                                Text(
                                  hizmet.hizmetDetayi,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // Hizmet Ekle Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () async {
                      final result =
                          await Navigator.push<BilgiTeknolojileriHizmetData>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BilgiTeknolojileriHizmetEkleScreen(
                                    destekTuru: widget.destekTuru,
                                  ),
                            ),
                          );

                      if (result != null) {
                        setState(() {
                          _addedHizmetler.add(result);
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
                            'Hizmet Ekle',
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

                const SizedBox(height: 24),

                // Açıklama
                AciklamaFieldWidget(
                  controller: _aciklamaController,
                  hintText: 'Açıklama giriniz...',
                  maxLines: 4,
                ),

                const SizedBox(height: 24),

                // Dosya/Fotoğraf Yükle
                FilePhotoUploadWidget<File>(
                  title: 'Dosya/Fotoğraf Yükle',
                  buttonText: 'Dosya/Fotoğraf Yükle',
                  files: _selectedFiles,
                  fileNameBuilder: (file) =>
                      file.path.split(Platform.pathSeparator).last,
                  onRemoveFile: _removeFile,
                  onPickCamera: _pickFromCamera,
                  onPickGallery: _pickFromGallery,
                  onPickFile: _pickFiles,
                ),

                const SizedBox(height: 24),

                // Dosyaların İçeriğini Belirtiniz
                Text(
                  'Dosyaların İçeriğini Belirtiniz',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.titleSmall?.fontSize ??
                            14) +
                        1,
                    color: AppColors.primaryLight,
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
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 1,
                ),
              ],
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
                  onPressed: () {
                    // TODO: API'ye gönder
                  },
                  child: const Text(
                    'Gönder',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

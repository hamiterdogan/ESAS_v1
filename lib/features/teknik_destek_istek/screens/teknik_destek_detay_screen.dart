import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/onay_form_content.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/core/screens/image_viewer_screen.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_detay_model.dart';
import 'package:esas_v1/features/teknik_destek_istek/providers/teknik_destek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:esas_v1/common/widgets/file_photo_upload_widget.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';

class TeknikDestekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const TeknikDestekDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<TeknikDestekDetayScreen> createState() =>
      _TeknikDestekDetayScreenState();
}

class _TeknikDestekDetayScreenState
    extends ConsumerState<TeknikDestekDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _teknikDestekDetaylariExpanded = true;
  bool _hizmetBilgileriExpanded = true;
  bool _onaySureciExpanded = true;
  bool _onayFormExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  // File Upload State
  final List<(String path, String fileName)> _selectedFiles = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedFiles.add((photo.path, photo.name));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamera hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedFiles.add((image.path, image.name));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Galeri hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
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

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles.add((
            result.files.single.path!,
            result.files.single.name,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya seçme hatası: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final paralelAsync = ref.watch(
      teknikDestekDetayParalelProvider(widget.talepId),
    );

    final titleText = paralelAsync.maybeWhen(
      data: (paralelData) => _buildDetayTitle(paralelData.detay.hizmetTuru),
      orElse: () => _buildDetayTitle(null),
    );

    final isLoading = paralelAsync.isLoading;
    final body = paralelAsync.when(
      data: (paralelData) => _buildContent(
        context,
        paralelData.detay,
        AsyncValue.data(paralelData.personel),
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildError(context, error),
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                titleText,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textOnPrimary,
              ),
              onPressed: () {
                final router = GoRouter.of(context);
                if (router.canPop()) {
                  router.pop();
                } else {
                  context.go('/teknik_destek');
                }
              },
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
            elevation: 0,
          ),
          body: body,
        ),
        if (isLoading) const BrandedLoadingOverlay(),
      ],
    );
  }

  String _buildDetayTitle(String? hizmetTuru) {
    final normalized = (hizmetTuru ?? '').trim();
    final prefix = normalized.isNotEmpty ? normalized : 'Teknik Destek';
    return '$prefix İstek Detayı (${widget.talepId})';
  }

  Widget _buildContent(
    BuildContext context,
    TeknikDestekDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
  ) {
    final resolvedAdSoyad = _resolveAdSoyad(detay, personelAsync);
    final resolvedGorevYeri = detay.gorevYeri.isNotEmpty
        ? detay.gorevYeri
        : (personelAsync.value?.gorevYeri ?? '-');
    final resolvedGorevi = detay.gorevi.isNotEmpty
        ? detay.gorevi
        : (personelAsync.value?.gorev ?? '-');

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          60 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccordion(
              icon: Icons.person_outline,
              title: 'Personel Bilgileri',
              isExpanded: _personelBilgileriExpanded,
              onTap: () {
                setState(() {
                  _personelBilgileriExpanded = !_personelBilgileriExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Ad Soyad',
                    resolvedAdSoyad.isNotEmpty ? resolvedAdSoyad : '-',
                  ),
                  _buildInfoRow(
                    'Görev Yeri',
                    resolvedGorevYeri.isNotEmpty ? resolvedGorevYeri : '-',
                  ),
                  _buildInfoRow(
                    'Görevi',
                    resolvedGorevi.isNotEmpty ? resolvedGorevi : '-',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.build_outlined,
              title: 'Teknik Destek İstek Detayları',
              isExpanded: _teknikDestekDetaylariExpanded,
              onTap: () {
                setState(() {
                  _teknikDestekDetaylariExpanded =
                      !_teknikDestekDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildTeknikDestekDetayRows(detay),
              ),
            ),
            const SizedBox(height: 16),
            _buildHizmetBilgileriAccordion(detay),
            const SizedBox(height: 16),
            _buildOnaySureciAccordion(),
            _buildOnayFormAccordion(detay.cozumler, detay.surecTamamlandi),
            _buildBildirimGideceklerAccordion(),
          ],
        ),
      ),
    );
  }

  String _resolveAdSoyad(
    TeknikDestekDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
  ) {
    if (detay.adSoyad.isNotEmpty) return detay.adSoyad;
    final combined = '${detay.ad} ${detay.soyad}'.trim();
    if (combined.isNotEmpty) return combined;
    return personelAsync.value?.adSoyad ?? '-';
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Detay yüklenemedi\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(teknikDestekDetayProvider(widget.talepId));
                ref.invalidate(personelBilgiProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTeknikDestekDetayRows(TeknikDestekDetayResponse detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    items.add(MapEntry('Bina', detay.bina));
    items.add(MapEntry('Hizmet Türü', detay.hizmetTuru));
    items.add(MapEntry('Son Tarih', _formatDate(detay.sonTarih)));
    items.add(MapEntry('Açıklama', detay.aciklama));

    if (detay.dosyaAciklama != null && detay.dosyaAciklama!.isNotEmpty) {
      items.add(MapEntry('Dosya Açıklama', detay.dosyaAciklama!));
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast =
          i == items.length - 1 &&
          (detay.dosyaAdi == null || detay.dosyaAdi!.isEmpty);

      final multiLineFields = [
        'Açıklama',
        'Dosya Açıklama',
        'Bina',
        'Hizmet Türü',
      ];
      final multiLine = multiLineFields.contains(item.key);

      rows.add(
        _buildInfoRow(
          item.key,
          item.value,
          isLast: isLast,
          multiLine: multiLine,
        ),
      );
    }

    if (detay.dosyaAdi != null && detay.dosyaAdi!.isNotEmpty) {
      final dosyaListesi = detay.dosyaAdi!
          .split('|')
          .map((f) => f.trim())
          .toList();

      for (int i = 0; i < dosyaListesi.length; i++) {
        final fileName = dosyaListesi[i];
        if (fileName.isNotEmpty) {
          rows.add(
            _buildClickableFileRow(
              dosyaListesi.length > 1
                  ? 'Yüklenen Dosya ${i + 1}'
                  : 'Yüklenen Dosya',
              fileName,
              isLast: i == dosyaListesi.length - 1,
            ),
          );
        }
      }
    }

    return rows;
  }

  Widget _buildHizmetBilgileriAccordion(TeknikDestekDetayResponse detay) {
    if (detay.hizmetler.isEmpty) {
      return _buildAccordion(
        icon: Icons.list_alt_outlined,
        title: 'Hizmet Bilgileri',
        isExpanded: _hizmetBilgileriExpanded,
        onTap: () {
          setState(() {
            _hizmetBilgileriExpanded = !_hizmetBilgileriExpanded;
          });
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Hizmet bilgisi yüklenmedi',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return _buildAccordion(
      icon: Icons.list_alt_outlined,
      title: 'Hizmet Bilgileri',
      isExpanded: _hizmetBilgileriExpanded,
      onTap: () {
        setState(() {
          _hizmetBilgileriExpanded = !_hizmetBilgileriExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: detay.hizmetler.asMap().entries.map((entry) {
          final index = entry.key;
          final hizmet = entry.value;
          final isLast = index == detay.hizmetler.length - 1;

          final kategori = hizmet.hizmetKategori.isNotEmpty
              ? hizmet.hizmetKategori
              : '-';
          final detayStr = hizmet.hizmetDetay.isNotEmpty
              ? hizmet.hizmetDetay
              : '-';

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kategori,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detayStr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccordion({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon, color: AppColors.primary),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textTertiary,
            ),
            onTap: onTap,
          ),
          if (isExpanded) const Divider(height: 1, color: AppColors.border),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isLast = false,
    bool multiLine = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiLine) ...[
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildClickableFileRow(
    String label,
    String fileName, {
    bool isLast = false,
  }) {
    const String baseUrl =
        'https://esas.eyuboglu.k12.tr/TestDosyalar/TeknikDestek/';
    final String fileUrl = '$baseUrl$fileName';

    final displayFileName = fileName.contains('_')
        ? fileName.substring(fileName.indexOf('_') + 1)
        : fileName;

    final extension = fileName.toLowerCase().split('.').last;
    final isPdf = extension == 'pdf';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () async {
              final lowerFileName = fileName.toLowerCase();
              final isImage =
                  lowerFileName.endsWith('.png') ||
                  lowerFileName.endsWith('.jpg') ||
                  lowerFileName.endsWith('.jpeg') ||
                  lowerFileName.endsWith('.bmp');

              if (isPdf) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(title: fileName, pdfUrl: fileUrl),
                  ),
                );
              } else if (isImage) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ImageViewerScreen(title: fileName, imageUrl: fileUrl),
                  ),
                );
              } else {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                  size: 20,
                  color: AppColors.gradientStart,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayFileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gradientStart,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _buildOnaySureciAccordion() {
    const onayTipi = 'Teknik Destek';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: onayTipi)),
    );

    return onayDurumuAsync.when(
      data: (onayDurumu) => _buildAccordion(
        icon: Icons.approval_outlined,
        title: 'Onay Süreci',
        isExpanded: _onaySureciExpanded,
        onTap: () {
          setState(() {
            _onaySureciExpanded = !_onaySureciExpanded;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildOnaySureciContent(onayDurumu),
        ),
      ),
      loading: () => _buildAccordion(
        icon: Icons.approval_outlined,
        title: 'Onay Süreci',
        isExpanded: _onaySureciExpanded,
        onTap: () {
          setState(() {
            _onaySureciExpanded = !_onaySureciExpanded;
          });
        },
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
          ),
        ),
      ),
      error: (error, _) => _buildAccordion(
        icon: Icons.approval_outlined,
        title: 'Onay Süreci',
        isExpanded: _onaySureciExpanded,
        onTap: () {
          setState(() {
            _onaySureciExpanded = !_onaySureciExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Onay süreci yüklenemedi',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildOnayFormAccordion(
    List<TeknikDestekCozum> cozumler,
    bool surecTamamlandi,
  ) {
    const onayTipi = 'Teknik Destek';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: onayTipi)),
    );

    return onayDurumuAsync.when(
      data: (onayDurumu) {
        // Show if there exists history OR if we can act on the form
        if (cozumler.isEmpty && !onayDurumu.onayFormuGoster) {
          return const SizedBox(height: 16);
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Çözüm Süreci',
              isExpanded: _onayFormExpanded,
              onTap: () {
                setState(() {
                  _onayFormExpanded = !_onayFormExpanded;
                });
              },
              child: Column(
                children: [
                  // 1. History (Timeline)
                  if (cozumler.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cozumler.length,
                      itemBuilder: (context, index) {
                        final item = cozumler[index];
                        final dateStr = item.tarih != null
                            ? DateFormat('dd.MM.yyyy HH:mm').format(
                                DateTime.tryParse(item.tarih!) ??
                                    DateTime.now(),
                              )
                            : '-';
                        return Card(
                          color: AppColors.textOnPrimary,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date & Time
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Sender
                                Text(
                                  item.yazanKisi ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Message
                                Text(
                                  item.aciklama ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                // Attachments
                                if (item.ekliDosya != null &&
                                    item.ekliDosya!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.scaffoldBackground
                                              .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.attach_file,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            item.ekliDosya!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Action Form - Only if process is NOT COMPLETED and user HAS PERMISSION
                  if (!surecTamamlandi && onayDurumu.onayFormuGoster)
                    OnayFormContent(
                      descriptionLabel: 'Mesajınızı yazınız',
                      descriptionMaxLines: 2,
                      extraContent: FilePhotoUploadWidget(
                        title: 'Dosya / Fotoğraf Yükle',
                        buttonText: 'Dosya Seç veya Fotoğraf Çek',
                        files: _selectedFiles.map((e) => e.$2).toList(),
                        fileNameBuilder: (file) => file,
                        onRemoveFile: _removeFile,
                        onPickCamera: _pickCamera,
                        onPickGallery: _pickGallery,
                        onPickFile: _pickFile,
                      ),
                      sendOnlyMode: true,
                      onSend: (aciklama) async {
                        final onaySureciId = onayDurumu
                            .siradakiOnayVerecekPersonel
                            ?.onaySureciId;
                        if (onaySureciId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Onay süreci ID bulunamadı!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        try {
                          // Upload files first if any
                          if (_selectedFiles.isNotEmpty) {
                            final fileRepo = ref.read(
                              bilgiTeknolojileriIstekRepositoryProvider,
                            );
                            final uploadResult = await fileRepo.dosyaYukle(
                              onayKayitId: widget.talepId,
                              onayTipi: 'Teknik Destek',
                              files: _selectedFiles,
                              dosyaAciklama: aciklama,
                            );

                            if (uploadResult is Failure) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Dosya yükleme hatası: ${(uploadResult as Failure).message}',
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return; // Stop execution on upload failure
                            }
                          }

                          final repository = ref
                              .read(talepYonetimRepositoryProvider);
                          final request = OnayDurumuGuncelleRequest(
                            onayTipi: 'Teknik Destek',
                            onayKayitId: widget.talepId,
                            onaySureciId: onaySureciId,
                            onay: true,
                            beklet: false,
                            geriDon: false,
                            aciklama: aciklama,
                          );

                          final result =
                              await repository.onayDurumuGuncelle(request);

                          if (!context.mounted) return;

                          switch (result) {
                            case Success():
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'İşlem başarıyla gerçekleşti',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              ref
                                  .read(devamEdenGelenKutusuProvider.notifier)
                                  .refresh();
                              Navigator.pop(context);
                            case Failure(message: final message):
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Hata: $message'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            case Loading():
                              break;
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hata: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(height: 16),
      error: (_, __) => const SizedBox(height: 16),
    );
  }

  Widget _buildBildirimGideceklerAccordion() {
    const onayTipi = 'Teknik Destek';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: onayTipi)),
    );

    return onayDurumuAsync.when(
      data: (onayDurumu) => _buildAccordion(
        icon: Icons.notifications_outlined,
        title: 'Bildirim Gidecekler',
        isExpanded: _bildirimGideceklerExpanded,
        onTap: () {
          setState(() {
            _bildirimGideceklerExpanded = !_bildirimGideceklerExpanded;
          });
        },
        child: onayDurumu.bildirimGidecekler.isEmpty
            ? const Text(
                'Bildirim gidecek personel bulunmamaktadır.',
                style: TextStyle(color: AppColors.textPrimary),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: onayDurumu.bildirimGidecekler.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final p = entry.value;
                  final isLast =
                      index == onayDurumu.bildirimGidecekler.length - 1;
                  return _buildBildirimPersonelCard(
                    personelAdi: p.personelAdi,
                    gorevYeri: p.gorevYeri,
                    gorevi: p.gorevi,
                    isLast: isLast,
                  );
                }).toList(),
              ),
      ),
      loading: () => _buildAccordion(
        icon: Icons.notifications_outlined,
        title: 'Bildirim Gidecekler',
        isExpanded: _bildirimGideceklerExpanded,
        onTap: () {
          setState(() {
            _bildirimGideceklerExpanded = !_bildirimGideceklerExpanded;
          });
        },
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
          ),
        ),
      ),
      error: (error, _) => _buildAccordion(
        icon: Icons.notifications_outlined,
        title: 'Bildirim Gidecekler',
        isExpanded: _bildirimGideceklerExpanded,
        onTap: () {
          setState(() {
            _bildirimGideceklerExpanded = !_bildirimGideceklerExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Bildirim gidecekler yüklenemedi',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildBildirimPersonelCard({
    required String personelAdi,
    required String gorevYeri,
    required String gorevi,
    required bool isLast,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personelAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gorevi,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      gorevYeri,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 0.5, color: AppColors.border),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    final List<Widget> widgets = [];
    widgets.add(
      _buildTalepEdenCard(
        personelAdi: onayDurumu.talepEdenPerAdi,
        gorevYeri: onayDurumu.talepEdenPerGorevYeri,
        gorevi: onayDurumu.talepEdenPerGorev,
        tarih: onayDurumu.talepEdenTarih,
        isLast: onayDurumu.onayVerecekler.isEmpty,
      ),
    );

    for (int i = 0; i < onayDurumu.onayVerecekler.length; i++) {
      final personel = onayDurumu.onayVerecekler[i];
      IconData icon;
      Color iconColor;

      if (personel.onay == true) {
        icon = Icons.check_circle;
        iconColor = AppColors.success;
      } else if (personel.onay == false) {
        icon = Icons.cancel;
        iconColor = AppColors.error;
      } else if (personel.geriGonderildi) {
        icon = Icons.replay;
        iconColor = AppColors.warning;
      } else {
        icon = Icons.hourglass_empty;
        iconColor = AppColors.warning;
      }

      widgets.add(
        _buildOnaySureciCard(
          personelAdi: personel.personelAdi,
          gorevYeri: personel.gorevYeri,
          gorevi: personel.gorevi,
          tarih: personel.islemTarihi,
          durum: personel.onayDurumu,
          aciklama: personel.aciklama,
          icon: icon,
          iconColor: iconColor,
          isFirst: false,
          isLast: i == onayDurumu.onayVerecekler.length - 1,
        ),
      );
    }
    return widgets;
  }

  Widget _buildTalepEdenCard({
    required String personelAdi,
    required String gorevYeri,
    required String gorevi,
    DateTime? tarih,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gradientStart.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: AppColors.gradientStart,
                size: 22,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 70, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personelAdi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gradientStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_task,
                        size: 18,
                        color: AppColors.gradientStart,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Talep Oluşturuldu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.gradientStart,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(tarih),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnaySureciCard({
    required String personelAdi,
    required String gorevYeri,
    required String gorevi,
    DateTime? tarih,
    required String durum,
    String? aciklama,
    required IconData icon,
    required Color iconColor,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            if (!isLast)
              Container(width: 2, height: 80, color: AppColors.textTertiary),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      personelAdi,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (durum.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '($durum)',
                          style: TextStyle(
                            fontSize: 14,
                            color: iconColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (aciklama != null && aciklama.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      aciklama,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(tarih),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }
}

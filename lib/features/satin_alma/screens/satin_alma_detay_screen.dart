import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/onay_form_content.dart';
import 'package:esas_v1/common/widgets/app_dialogs.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/core/screens/image_viewer_screen.dart';
import 'dart:io';
import 'package:esas_v1/features/satin_alma/models/satin_alma_detay_model.dart';
import 'package:esas_v1/common/providers/file_attachment_provider.dart';
import 'package:esas_v1/common/widgets/file_photo_upload_widget.dart';



import 'package:esas_v1/common/widgets/numeric_spinner_widget.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_urun_ekle_screen.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_fiyat_gecmisi.dart';
import 'package:esas_v1/common/widgets/common_divider.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_fiyat_arastirma_personel.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';

final satinAlmaDosyaEklemeProvider =
    NotifierProvider<GenericFileAttachmentNotifier, FileAttachmentState>(
      GenericFileAttachmentNotifier.new,
    );

class SatinAlmaDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const SatinAlmaDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<SatinAlmaDetayScreen> createState() =>
      _SatinAlmaDetayScreenState();
}

class _SatinAlmaDetayScreenState extends ConsumerState<SatinAlmaDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _satinAlmaDetaylariExpanded = true;
  bool _urunBilgileriExpanded = true;
  bool _onaySureciExpanded = true;
  bool _onayFormExpanded = true;
  bool _bildirimGideceklerExpanded = true;
  List<SatinAlmaDetayUrunSatir>? _localUrunler;

  // Vendor Edit Controllers
  final TextEditingController _saticiFirmaController = TextEditingController();
  final TextEditingController _saticiTelefonController = TextEditingController();
  final TextEditingController _webSitesiController = TextEditingController();
  bool _vendorFieldsInitialized = false;

  // Payment Edit State
  int? _selectedOdemeSekliId;
  bool _isPesin = true;
  int _vadeGun = 30;
  SatinAlmaFiyatArastirmaPersonel? _selectedFiyatArastirmaPersonel;
  final TextEditingController _fiyatArastirmasiNotuController = TextEditingController();
  bool _paymentFieldsInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FileAttachmentState>(satinAlmaDosyaEklemeProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        AppDialogs.showError(context, next.errorMessage!);
        ref.read(satinAlmaDosyaEklemeProvider.notifier).clearError();
      }
    });

    // Note: The logic for satinAlmaDetayParalelProvider was established to load data in parallel.
    final paralelAsync = ref.watch(
      satinAlmaDetayParalelProvider(widget.talepId),
    );

    final isLoading = paralelAsync.isLoading;
    final body = paralelAsync.when(
      data: (paralelData) {
        _localUrunler ??= List.from(paralelData.detay.urunlerSatir);
        
        // Initialize vendor fields once
        if (!_vendorFieldsInitialized) {
          _saticiFirmaController.text = paralelData.detay.saticiFirma;
          _saticiTelefonController.text = paralelData.detay.saticiTel ?? '';
          _webSitesiController.text = paralelData.detay.webSitesi ?? '';
          _vendorFieldsInitialized = true;
        }

        // Initialize payment fields once
        if (!_paymentFieldsInitialized) {
          _selectedOdemeSekliId = paralelData.detay.odemeSekliId;
          _isPesin = paralelData.detay.pesin;
          _vadeGun = paralelData.detay.odemeVadesiGun ?? 30;
          if (_vadeGun == 0) _vadeGun = 30; // Default to 30 if 0 comes from API for non-pesin (safety)
          _paymentFieldsInitialized = true;
        }

        return _buildContent(
          context,
          paralelData.detay,
          AsyncValue.data(paralelData.personel),
          paralelData.binalar,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildError(context, error),
    );

    return Stack(
      children: [
        GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Satın Alma İstek Detayı (${widget.talepId})',
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
                    context.go('/satin_alma');
                  }
                },
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              ),
              elevation: 0,
            ),
            body: body,
          ),
        ),
        if (isLoading) const BrandedLoadingOverlay(),
      ],
    );
  }

  @override
  void dispose() {
    _saticiFirmaController.dispose();
    _saticiTelefonController.dispose();
    _webSitesiController.dispose();
    _fiyatArastirmasiNotuController.dispose();
    super.dispose();
  }

  Widget _buildContent(
    BuildContext context,
    SatinAlmaDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
    List<SatinAlmaBina> binalar,
  ) {
    final adSoyad = detay.adSoyad.isNotEmpty
        ? detay.adSoyad
        : (personelAsync.value?.adSoyad ?? '-');
    final gorevYeri = detay.gorevYeri.isNotEmpty
        ? detay.gorevYeri
        : (personelAsync.value?.gorevYeri ?? '-');
    final gorevi = detay.gorevi.isNotEmpty
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
                  _buildInfoRow('Ad Soyad', adSoyad.isNotEmpty ? adSoyad : '-'),
                  _buildInfoRow(
                    'Görev Yeri',
                    gorevYeri.isNotEmpty ? gorevYeri : '-',
                  ),
                  _buildInfoRow(
                    'Görevi',
                    gorevi.isNotEmpty ? gorevi : '-',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.shopping_cart_outlined,
              title: 'Satın Alma İstek Detayları',
              isExpanded: _satinAlmaDetaylariExpanded,
              onTap: () {
                setState(() {
                  _satinAlmaDetaylariExpanded = !_satinAlmaDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildSatinAlmaDetayRows(detay, binalar),
              ),
            ),
            const SizedBox(height: 16),
            _buildUrunBilgileriAccordion(detay),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement save logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text(
                        'Güncelle ve Kaydet',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        _showFiyatGecmisiBottomSheet(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2), // Standard Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text(
                        'Fiyat Geçmişi',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CommonDivider(),
            ),
            const SizedBox(height: 16),

            // Price Research Assignment Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Person Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fiyat Araştırması Yapacak Kişi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => _showFiyatArastirmaPersonelBottomSheet(context),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedFiyatArastirmaPersonel != null
                                          ? '${_selectedFiyatArastirmaPersonel!.adi} ${_selectedFiyatArastirmaPersonel!.soyadi}'
                                          : 'Seçiniz',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedFiyatArastirmaPersonel != null
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Note Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Not Ekle',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 48,
                            child: TextFormField(
                              controller: _fiyatArastirmasiNotuController,
                              decoration: InputDecoration(
                                hintText: 'Notunuzu buraya giriniz...',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedFiyatArastirmaPersonel == null) {
                          AppDialogs.showError(
                              context, 'Lütfen fiyat araştırması yapacak kişiyi seçiniz.');
                          return;
                        }

                        // Show confirmation before sending if needed, or just send directly.
                        // Ideally show loading.
                        BrandedLoadingDialog.show(context);

                        final result = await ref
                            .read(satinAlmaRepositoryProvider)
                            .fiyatArastir(
                              satinAlmaId: widget.talepId,
                              atanacakPersonelId:
                                  _selectedFiyatArastirmaPersonel!.personelId,
                              aciklama: _fiyatArastirmasiNotuController.text,
                            );

                        if (!context.mounted) return;
                        BrandedLoadingDialog.hide(context);

                        if (result is Success) {
                          AppDialogs.showSuccess(
                              context, 'Fiyat araştırması talebi başarıyla iletildi.', onOk: () {
                             // Clear selections or just stay? User didn't specify.
                             // Let's clear for now so they don't resend accidentally.
                             setState(() {
                               _selectedFiyatArastirmaPersonel = null;
                               _fiyatArastirmasiNotuController.clear();
                             });
                          });
                        } else if (result is Failure) {
                          AppDialogs.showError(context, result.message);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Gönder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildOnaySureciAccordion(),
            _buildOnayFormAccordion(),
            _buildBildirimGideceklerAccordion(),
          ],
        ),
      ),
    );
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
                ref.invalidate(satinAlmaDetayProvider(widget.talepId));
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

  List<Widget> _buildSatinAlmaDetayRows(
    SatinAlmaDetayResponse detay,
    List<SatinAlmaBina> binalar,
  ) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    // Okul bilgisi
    final okulIsimleri =
        detay.binaId
            .map((id) {
              final bina = binalar.firstWhere(
                (b) => b.id == id,
                orElse:
                    () =>
                        SatinAlmaBina(id: -1, binaAdi: 'Bilinmiyor', binaKodu: ''),
              );
              return bina.binaAdi;
            })
            .where((name) => name != 'Bilinmiyor')
            .join(', ');

    items.add(
      MapEntry('Hangi okul(lar) için', okulIsimleri.isNotEmpty ? okulIsimleri : '-'),
    );
    items.add(MapEntry('Alımın Amacı', detay.aliminAmaci));
    // Satıcı bilgileri artık editable olarak eklenecek, items listesinden çıkarıldı.

    // Date Formatting
    String teslimTarihiStr = detay.sonTeslimTarihi;
    try {
      final date = DateTime.tryParse(detay.sonTeslimTarihi);
      if (date != null) {
        teslimTarihiStr = DateFormat('dd.MM.yyyy').format(date);
      }
    } catch (_) {}
    items.add(MapEntry('Son Teslim Tarihi', teslimTarihiStr));



    final genelToplamStr = NumberFormat(
      '#,##0.00',
      'tr_TR',
    ).format(detay.genelToplam);
    items.add(MapEntry('Genel Toplam', '$genelToplamStr TL'));

    if (detay.dosyaAciklama != null && detay.dosyaAciklama!.isNotEmpty) {
      items.add(MapEntry('Dosya Açıklama', detay.dosyaAciklama!));
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      final multiLineFields = [
        'Alımın Amacı',
        'Web Sitesi',
        'Dosya Açıklama',
        'Hangi okul(lar) için',
        'Satıcı Firma',
      ];
      final multiLine = multiLineFields.contains(item.key);

      rows.add(
        _buildInfoRow(
          item.key,
          item.value,
          isLast: isLast && (detay.dosyaAdi == null || detay.dosyaAdi!.isEmpty),
          multiLine: multiLine,
        ),
      );

      // Alımın Amacı'ndan sonra editable alanları ekle
      if (item.key == 'Alımın Amacı') {
        rows.add(_buildEditableRow('Satıcı Firma', _saticiFirmaController));
        rows.add(const Divider(height: 1, color: AppColors.border));
        rows.add(_buildEditableRow('Satıcı Telefon', _saticiTelefonController));
        rows.add(const Divider(height: 1, color: AppColors.border));
        rows.add(_buildEditableRow('Web Sitesi', _webSitesiController));
        rows.add(const Divider(height: 1, color: AppColors.border));
        rows.add(const SizedBox(height: 12));
      }

      // Son Teslim Tarihi'nden sonra editable ödeme alanlarını ekle
      if (item.key == 'Son Teslim Tarihi') {
         rows.add(const SizedBox(height: 12));
         rows.add(_buildEditableOdemeSekliRow());
         rows.add(const Divider(height: 1, color: AppColors.border));
         rows.add(_buildEditableOdemeVadesiRow());
         rows.add(const Divider(height: 1, color: AppColors.border));
         rows.add(const SizedBox(height: 12));
      }
    }

    // Yüklenen dosya varsa göster
    if (detay.dosyaAdi != null && detay.dosyaAdi!.isNotEmpty) {
      // Birden fazla dosya "|" ile ayrılmış olabilir
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

    // Dosya Ekleme Bölümü
    final fileState = ref.watch(satinAlmaDosyaEklemeProvider);
    
    rows.add(
      Padding(
        padding: const EdgeInsets.only(top: 20),
        child: FilePhotoUploadWidget<File>(
          title: 'Dosya Ekleme (Fiyat Teklifi, Sözleşme vb.)',
          buttonText: 'Dosya Seç',
          files: fileState.files,
          fileNameBuilder: (file) => file.path.split(Platform.pathSeparator).last,
          onRemoveFile: (index) =>
              ref.read(satinAlmaDosyaEklemeProvider.notifier).removeFile(index),
          onPickCamera: () =>
              ref.read(satinAlmaDosyaEklemeProvider.notifier).pickFiles(),
          onPickGallery: () =>
              ref.read(satinAlmaDosyaEklemeProvider.notifier).pickFiles(),
          onPickFile: () =>
              ref.read(satinAlmaDosyaEklemeProvider.notifier).pickFiles(),

        ),
      ),
    );

    return rows;
  }

  Widget _buildUrunBilgileriAccordion(SatinAlmaDetayResponse detay) {
    // _localUrunler henüz initialize edilmediyse detaydan al (fail-safe)
    final urunler = _localUrunler ?? detay.urunlerSatir;

    if (urunler.isEmpty) {
      return _buildAccordion(
        icon: Icons.inventory_2_outlined,
        title: 'Ürün Bilgileri',
        isExpanded: _urunBilgileriExpanded,
        onTap: () {
          setState(() {
            _urunBilgileriExpanded = !_urunBilgileriExpanded;
          });
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Ürün bilgisi yüklenmedi',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return _buildAccordion(
      icon: Icons.inventory_2_outlined,
      title: 'Ürün Bilgileri',
      isExpanded: _urunBilgileriExpanded,
      onTap: () {
        setState(() {
          _urunBilgileriExpanded = !_urunBilgileriExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: urunler.asMap().entries.map((entry) {
          final index = entry.key;
          final urun = entry.value;
          final isLast = index == urunler.length - 1;

          final birimFiyatStr = NumberFormat(
            '#,##0.00',
            'tr_TR',
          ).format(urun.birimFiyati);

          final dovizKuruStr = NumberFormat(
            '#,##0.00',
            'tr_TR',
          ).format(urun.dovizKuru);

          final toplamFiyat = urun.miktar * urun.birimFiyati;
          final toplamFiyatStr = NumberFormat(
            '#,##0.00',
            'tr_TR',
          ).format(toplamFiyat);

          final toplamTLFiyat = toplamFiyat * urun.dovizKuru;
          final toplamTLFiyatStr = NumberFormat(
            '#,##0.00',
            'tr_TR',
          ).format(toplamTLFiyat);

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final initialBilgi = _toUrunBilgisi(urun);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SatinAlmaUrunEkleScreen(
                            initialBilgi: initialBilgi,
                          ),
                        ),
                      );

                      if (result != null && result is SatinAlmaUrunBilgisi) {
                        _updateUrunSatir(urun, result);
                      }
                    },
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Düzenle',
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori bilgisi
                          Text(
                            '${urun.satinAlmaAnaKategori} - ${urun.satinAlmaAltKategori}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Ürün Detayı
                          if (urun.urunDetay.isNotEmpty) ...[
                            Text(
                              urun.urunDetay,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Miktar x Birim Fiyat
                          Text(
                            '${urun.miktar.toInt()} ${() {
                              final birimler = ref.watch(satinAlmaOlcuBirimleriProvider).asData?.value;
                              if (birimler != null) {
                                try {
                                  return birimler.firstWhere((b) => b.id == urun.birimId).birimAdi;
                                } catch (_) {}
                              }
                              return 'Adet'; // Fallback
                            }()} x $birimFiyatStr ${urun.paraBirimi}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Hesaplama Satırı: Toplam Original x Kur = Toplam TL
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(text: '$toplamFiyatStr ${urun.paraBirimi}'),
                                const TextSpan(text: ' x '),
                                TextSpan(text: dovizKuruStr),
                                const TextSpan(text: ' = '),
                                TextSpan(
                                  text: '$toplamTLFiyatStr TL',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sürüklenebilir ikonu (Soft Double Arrow)
                    Container(
                      height: 28,
                      width: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
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
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
        'https://esas.eyuboglu.k12.tr/TestDosyalar/satinalma/';
    final String fileUrl = '$baseUrl$fileName';

    // Dosya ismini gösterirken ilk "_" karakterine kadar olan kısmı at
    final displayFileName = fileName.contains('_')
        ? fileName.substring(fileName.indexOf('_') + 1)
        : fileName;

    // Dosya uzantısını kontrol et
    final extension = fileName.toLowerCase().split('.').last;
    final isPdf = extension == 'pdf';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          // Tıklanabilir dosya adı
          GestureDetector(
            onTap: () async {
              final lowerFileName = fileName.toLowerCase();
              final isImage =
                  lowerFileName.endsWith('.png') ||
                  lowerFileName.endsWith('.jpg') ||
                  lowerFileName.endsWith('.jpeg') ||
                  lowerFileName.endsWith('.bmp');

              if (isPdf) {
                // PDF ise ortak PDF viewer'a yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(title: fileName, pdfUrl: fileUrl),
                  ),
                );
              } else if (isImage) {
                // Image dosyaları için image viewer'a yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ImageViewerScreen(title: fileName, imageUrl: fileUrl),
                  ),
                );
              } else {
                // Diğer dosyalar için tarayıcıda aç
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
    const onayTipi = 'Satın Alma'; // Using explicit approval type for Purchase
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

  Widget _buildBildirimGideceklerAccordion() {
    const onayTipi = 'Satın Alma';
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

  Widget _buildOnayFormAccordion() {
    const onayTipi = 'Satın Alma';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: onayTipi)),
    );

    return onayDurumuAsync.when(
      data: (onayDurumu) {
        if (!onayDurumu.onayFormuGoster) {
          return const SizedBox(height: 16);
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Onay',
              isExpanded: _onayFormExpanded,
              onTap: () {
                setState(() {
                  _onayFormExpanded = !_onayFormExpanded;
                });
              },
              child: OnayFormContent(
                onApprove: (aciklama) async {
                  final onaySureciId =
                      onayDurumu.siradakiOnayVerecekPersonel?.onaySureciId;
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
                    final repository = ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Satın Alma',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: true,
                      beklet: false,
                      geriDon: false,
                      aciklama: aciklama,
                    );

                    final result = await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        // Listeyi yenile ve geri dön
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                onReject: (aciklama) async {
                  final onaySureciId =
                      onayDurumu.siradakiOnayVerecekPersonel?.onaySureciId;
                  if (onaySureciId == null) return;

                  try {
                    final repository = ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Satın Alma',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: false,
                      geriDon: false,
                      aciklama: aciklama,
                    );

                    final result = await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
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
                onReturn: (aciklama) async {
                  final onaySureciId =
                      onayDurumu.siradakiOnayVerecekPersonel?.onaySureciId;
                  if (onaySureciId == null) return;

                  try {
                    final repository = ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Satın Alma',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: false,
                      geriDon: true,
                      aciklama: aciklama,
                    );

                    final result = await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
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
                onAssign: (aciklama, selectedPersonel) async {
                  if (selectedPersonel == null) return;
                  final onaySureciId =
                      onayDurumu.siradakiOnayVerecekPersonel?.onaySureciId;
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
                    final repository = ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Satın Alma',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: true,
                      beklet: false,
                      geriDon: false,
                      aciklama: aciklama,
                      atanacakPersonelId: selectedPersonel.personelId,
                    );

                    final result = await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Görev atama başarıyla gerçekleşti'),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                onHold: (aciklama, bekletKademe) async {
                  final onaySureciId =
                      onayDurumu.siradakiOnayVerecekPersonel?.onaySureciId;
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
                    final repository = ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Satın Alma',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: true,
                      geriDon: false,
                      aciklama: aciklama,
                      bekletKademe: bekletKademe,
                    );

                    final result = await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bekleme işlemi başarıyla gerçekleşti',
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                gorevAtamaEnabled: onayDurumu.atamaGoster,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gorevi,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      gorevYeri,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textTertiary,
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
          Divider(height: 1, thickness: 0.5, color: AppColors.border),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    // Reusing the exact logic from AracIstek...
    // (Copying generic parts for brevity - implementation mirroring AracIstekDetay logic)
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
    // (Standard Card Implementation)
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
    // (Standard Card Implementation)
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
                      color: AppColors.cardBackground,
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


  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableOdemeSekliRow() {
    final odemeSekliMap = {1: 'Nakit', 2: 'Kredi Kartı', 3: 'Havale/EFT'};
    final currentLabel = odemeSekliMap[_selectedOdemeSekliId] ?? 'Seçiniz';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Şekli',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Ödeme Şekli Seçiniz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...odemeSekliMap.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.value),
                            onTap: () {
                              setState(() {
                                _selectedOdemeSekliId = entry.key;
                              });
                              Navigator.pop(context);
                            },
                            trailing: _selectedOdemeSekliId == entry.key
                                ? const Icon(Icons.check, color: AppColors.primary)
                                : null,
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableOdemeVadesiRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Vadesi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                         const Text(
                          'Ödeme Vadesi Seçiniz',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Peşin'),
                          onTap: () {
                            setState(() {
                              _isPesin = true;
                            });
                            Navigator.pop(context);
                          },
                          trailing: _isPesin
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                        ),
                        ListTile(
                          title: const Text('Vadeli'),
                          onTap: () {
                            setState(() {
                              _isPesin = false;
                            });
                            Navigator.pop(context);
                          },
                          trailing: !_isPesin
                              ? const Icon(Icons.check, color: AppColors.primary)
                              : null,
                        ),
                       const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isPesin ? 'Peşin' : 'Vadeli',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (!_isPesin) ...[
            const SizedBox(height: 12),
            NumericSpinnerWidget(
              label: 'Vade Süresi (Gün)',
              initialValue: _vadeGun,
              minValue: 1,
              maxValue: 365,
              compact: true,
              onValueChanged: (val) {
                setState(() {
                  _vadeGun = val;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  SatinAlmaUrunBilgisi _toUrunBilgisi(SatinAlmaDetayUrunSatir satir) {
    // Fiyat ayrıştırma (Ana ve Küsurat)
    final parts = satir.birimFiyati.toStringAsFixed(2).split('.');
    final ana = parts[0];
    final kusurat = parts.length > 1 ? parts[1] : '00';

    // Toplam TL Fiyatı
    final toplamTl = satir.miktar * satir.birimFiyati * satir.dovizKuru;
    final topTlStr =
        '${NumberFormat('#,##0.00', 'tr_TR').format(toplamTl)} TL';

    return SatinAlmaUrunBilgisi(
      anaKategori: satir.satinAlmaAnaKategori,
      anaKategoriId: satir.satinAlmaAnaKategoriId,
      altKategori: satir.satinAlmaAltKategori,
      altKategoriId: satir.satinAlmaAltKategoriId,
      urunDetay: satir.urunDetay,
      miktar: satir.miktar,
      olcuBirimiId: satir.birimId,
      paraBirimi: satir.paraBirimi,
      dovizKuru: satir.dovizKuru,
      fiyatAna: ana,
      fiyatKusurat: kusurat,
      toplamTlFiyati: topTlStr,
    );
  }

  void _updateUrunSatir(
    SatinAlmaDetayUrunSatir oldSatir,
    SatinAlmaUrunBilgisi newBilgi,
  ) {
    // Parse price
    final fiyatAnaText = newBilgi.fiyatAna?.replaceAll('.', '') ?? '0';
    final fiyatAna = double.tryParse(fiyatAnaText) ?? 0;
    final fiyatKusurat = double.tryParse(newBilgi.fiyatKusurat ?? '0') ?? 0;
    final birimFiyat = fiyatAna + (fiyatKusurat / 100);

    final newSatir = SatinAlmaDetayUrunSatir(
      id: oldSatir.id,
      satinAlmaAnaKategoriId: oldSatir.satinAlmaAnaKategoriId,
      satinAlmaAltKategoriId: oldSatir.satinAlmaAltKategoriId,
      satinAlmaAnaKategori: oldSatir.satinAlmaAnaKategori,
      satinAlmaAltKategori: oldSatir.satinAlmaAltKategori,
      urunDetay: oldSatir.urunDetay,
      miktar: newBilgi.miktar ?? oldSatir.miktar,
      birimId: newBilgi.olcuBirimiId ?? oldSatir.birimId,
      paraBirimi:
          newBilgi.paraBirimiKod ?? newBilgi.paraBirimi ?? oldSatir.paraBirimi,
      digerUrun: oldSatir.digerUrun,
      birimFiyati: birimFiyat,
      dovizKuru: newBilgi.dovizKuru ?? oldSatir.dovizKuru,
    );

    setState(() {
      if (_localUrunler != null) {
        final index = _localUrunler!.indexOf(oldSatir);
        if (index != -1) {
          _localUrunler![index] = newSatir;
        }
      }
    });
  }

  void _showFiyatGecmisiBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F8), // Modern light grey-blue background
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.history_edu_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: const Text(
                              'Fiyat Geçmişi',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 24),
                            color: AppColors.textSecondary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FutureBuilder<List<SatinAlmaFiyatGecmisiItem>>(
                  future: ref
                      .read(satinAlmaRepositoryProvider)
                      .getFiyatGecmisi(widget.talepId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: BrandedLoadingIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 48, color: AppColors.error.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Bir hata oluştu',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Henüz kayıt bulunamadı',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final islemTarihiFormatted = item.islemTarihi.isNotEmpty
                            ? DateFormat('dd.MM.yyyy', 'tr_TR').format(
                                DateTime.tryParse(item.islemTarihi) ??
                                    DateTime.now())
                            : '-';
                        final islemSaatiFormatted = item.islemTarihi.isNotEmpty
                            ? DateFormat('HH:mm').format(
                                DateTime.tryParse(item.islemTarihi) ??
                                    DateTime.now())
                            : '';

                        String sonTeslimTarihiFormatted = '-';
                        if (item.sonTeslimTarihi.isNotEmpty) {
                          final date = DateTime.tryParse(item.sonTeslimTarihi);
                          if (date != null) {
                            sonTeslimTarihiFormatted =
                                DateFormat('dd.MM.yyyy').format(date);
                          }
                        }

                        final genelToplamFormatted = NumberFormat(
                          '#,##0.00',
                          'tr_TR',
                        ).format(item.genelToplam);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueGrey.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 14,
                                                color: AppColors.textTertiary,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$islemTarihiFormatted • $islemSaatiFormatted',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            item.saticiFirma,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$genelToplamFormatted ₺',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: item.odemeSekli == 'Nakit'
                                                ? const Color(0xFFE8F5E9)
                                                : const Color(0xFFE3F2FD),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.odemeSekli,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: item.odemeSekli == 'Nakit'
                                                  ? const Color(0xFF2E7D32)
                                                  : const Color(0xFF1565C0),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFBFC),
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[100]!),
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.white,
                                          child: const Icon(
                                              Icons.person_outline_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.adSoyad,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.sonTeslimTarihi.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.event_available_rounded,
                                              size: 14,
                                              color: AppColors.textTertiary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              sonTeslimTarihiFormatted,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
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

  void _showFiyatArastirmaPersonelBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Personel Seçiniz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<SatinAlmaFiyatArastirmaPersonel>>(
                  future: ref.read(satinAlmaRepositoryProvider).getFiyatArastirmaListesi(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: BrandedLoadingIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Hata oluştu',
                          style: TextStyle(color: AppColors.error),
                        ),
                      );
                    }

                    final allItems = snapshot.data ?? [];
                    // Filter out person with ID 4746 (EDA ALGÜLLÜ) as requested
                    final items = allItems.where((p) => p.personelId != 4746).toList();

                    if (items.isEmpty) {
                      return const Center(
                        child: Text('Personel bulunamadı'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey[200],
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = _selectedFiyatArastirmaPersonel?.personelId == item.personelId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          title: Text(
                            '${item.adi} ${item.soyadi}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedFiyatArastirmaPersonel = item;
                            });
                            Navigator.pop(context);
                          },
                        );
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
}

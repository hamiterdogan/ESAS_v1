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
import 'package:esas_v1/features/satin_alma/models/satin_alma_detay_model.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    // Note: The logic for satinAlmaDetayProvider was established in previous steps.
    final detayAsync = ref.watch(satinAlmaDetayProvider(widget.talepId));
    final personelAsync = ref.watch(personelBilgiProvider);

    final isLoading = detayAsync.isLoading;
    final body = detayAsync.when(
      data: (detay) => _buildContent(context, detay, personelAsync),
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
        if (isLoading) const BrandedLoadingOverlay(),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    SatinAlmaDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
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
              title: 'Satınalma İstek Detayları',
              isExpanded: _satinAlmaDetaylariExpanded,
              onTap: () {
                setState(() {
                  _satinAlmaDetaylariExpanded = !_satinAlmaDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildSatinAlmaDetayRows(detay),
              ),
            ),
            const SizedBox(height: 16),
            _buildUrunBilgileriAccordion(detay),
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

  List<Widget> _buildSatinAlmaDetayRows(SatinAlmaDetayResponse detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    items.add(MapEntry('Alımın Amacı', detay.aliminAmaci));
    items.add(MapEntry('Satıcı Firma', detay.saticiFirma));
    if (detay.saticiTel != null && detay.saticiTel!.isNotEmpty) {
      items.add(MapEntry('Satıcı Telefon', detay.saticiTel!));
    }
    if (detay.webSitesi != null && detay.webSitesi!.isNotEmpty) {
      items.add(MapEntry('Web Sitesi', detay.webSitesi!));
    }

    // Date Formatting
    String teslimTarihiStr = detay.sonTeslimTarihi;
    try {
      final date = DateTime.tryParse(detay.sonTeslimTarihi);
      if (date != null) {
        teslimTarihiStr = DateFormat('dd.MM.yyyy').format(date);
      }
    } catch (_) {}
    items.add(MapEntry('Son Teslim Tarihi', teslimTarihiStr));

    // Odeme Sekli - assuming 1: Nakit, 2: Kredi Kartı, 3: Havale/EFT based on previous knowledge or mocked map
    final odemeSekliMap = {1: 'Nakit', 2: 'Kredi Kartı', 3: 'Havale/EFT'};
    final odemeSekliStr = odemeSekliMap[detay.odemeSekliId] ?? 'Bilinmiyor';
    items.add(MapEntry('Ödeme Şekli', odemeSekliStr));

    if (!detay.pesin) {
      items.add(MapEntry('Ödeme Vadesi', '${detay.odemeVadesiGun} Gün'));
    } else {
      items.add(MapEntry('Ödeme Vadesi', 'Peşin'));
    }

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

      final multiLineFields = ['Alımın Amacı', 'Web Sitesi', 'Dosya Açıklama'];
      final multiLine = multiLineFields.contains(item.key);

      rows.add(
        _buildInfoRow(
          item.key,
          item.value,
          isLast: isLast && (detay.dosyaAdi == null || detay.dosyaAdi!.isEmpty),
          multiLine: multiLine,
        ),
      );
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

    return rows;
  }

  Widget _buildUrunBilgileriAccordion(SatinAlmaDetayResponse detay) {
    if (detay.urunlerSatir.isEmpty) {
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
        children: detay.urunlerSatir.asMap().entries.map((entry) {
          final index = entry.key;
          final urun = entry.value;
          final isLast = index == detay.urunlerSatir.length - 1;

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
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '${urun.miktar.toInt()} Adet',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' × '),
                        TextSpan(
                          text: '$birimFiyatStr ${urun.paraBirimi}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Toplam Fiyat = Toplam TL Fiyat
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(text: '$toplamFiyatStr ${urun.paraBirimi}'),
                        const TextSpan(
                          text: ' × ',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(text: dovizKuruStr),
                        const TextSpan(
                          text: ' = ',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: '$toplamTLFiyatStr TL',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ],
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
                onApprove: () {},
                onReject: () {},
                onReturn: () {},
                onAssign: () {},
                gorevAtamaEnabled: onayDurumu.gorevAtama,
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
}

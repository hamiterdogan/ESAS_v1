import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/core/screens/image_viewer_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_detay_model.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';

class SarfMalzemeDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const SarfMalzemeDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<SarfMalzemeDetayScreen> createState() =>
      _SarfMalzemeDetayScreenState();
}

class _SarfMalzemeDetayScreenState
    extends ConsumerState<SarfMalzemeDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _sarfMalzemeDetaylariExpanded = true;
  bool _urunBilgileriExpanded = true;
  bool _onaySureciExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(sarfMalzemeDetayProvider(widget.talepId));
    final personelAsync = ref.watch(personelBilgiProvider);
    final binalarAsync = ref.watch(satinAlmaBinalarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F5),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Sarf Malzeme İstek Detayı (${widget.talepId})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
        elevation: 0,
      ),
      body: detayAsync.when(
        data: (detay) =>
            _buildContent(context, detay, personelAsync, binalarAsync),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SarfMalzemeDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
    AsyncValue<List<SatinAlmaBina>> binalarAsync,
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
              icon: Icons.shopping_cart_outlined, // Same icon as SatinAlma
              title: 'Sarf Malzeme İstek Detayları',
              isExpanded: _sarfMalzemeDetaylariExpanded,
              onTap: () {
                setState(() {
                  _sarfMalzemeDetaylariExpanded =
                      !_sarfMalzemeDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildSarfMalzemeDetayRows(detay, binalarAsync),
              ),
            ),
            const SizedBox(height: 16),
            _buildUrunBilgileriAccordion(detay),
            const SizedBox(height: 16),
            _buildOnaySureciAccordion(),
            const SizedBox(height: 16),
            _buildBildirimGideceklerAccordion(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Container(
        width: 175,
        height: 175,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
        ),
        alignment: Alignment.center,
        child: const BrandedLoadingIndicator(size: 153, strokeWidth: 24),
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
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Detay yüklenemedi\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(sarfMalzemeDetayProvider(widget.talepId));
                ref.invalidate(personelBilgiProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSarfMalzemeDetayRows(
    SarfMalzemeDetayResponse detay,
    AsyncValue<List<SatinAlmaBina>> binalarAsync,
  ) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    // Bina Mapping
    String binalarStr = '-';
    if (binalarAsync.hasValue) {
      final binalar = binalarAsync.value!;
      final selectedNames = <String>[];

      for (final id in detay.binaId) {
        try {
          final bina = binalar.firstWhere(
            (b) => b.id == id,
            orElse: () => SatinAlmaBina(id: id, binaAdi: '', binaKodu: ''),
          );
          if (bina.binaAdi.isNotEmpty) {
            selectedNames.add(bina.binaAdi);
          } else {
            selectedNames.add(id.toString());
          }
        } catch (_) {
          selectedNames.add(id.toString());
        }
      }

      if (selectedNames.isNotEmpty) {
        binalarStr = selectedNames.join(', ');
      }
    } else {
      binalarStr = 'Yükleniyor...';
    }

    items.add(MapEntry('İstekte Bulunulan Okullar', binalarStr));
    items.add(MapEntry('Alımın Amacı', detay.talebinAmaci));

    if (detay.dosyaAciklama != null && detay.dosyaAciklama!.isNotEmpty) {
      items.add(MapEntry('Dosya Açıklama', detay.dosyaAciklama!));
    }

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast =
          i == items.length - 1 &&
          (detay.dosyaAdi == null || detay.dosyaAdi!.isEmpty);

      final multiLineFields = [
        'Alımın Amacı',
        'Dosya Açıklama',
        'İstekte Bulunulan Okullar',
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

  Widget _buildUrunBilgileriAccordion(SarfMalzemeDetayResponse detay) {
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
            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
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

          // Since we don't have unit name, just show quantity
          final miktarStr = '${urun.miktar.toInt()} Adet';

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50], // Very light background
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori bilgisi
                  Text(
                    '${urun.satinAlmaAnaKategori} - ${urun.satinAlmaAltKategori ?? ""}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Ürün Detayı
                  if (urun.urunDetay.isNotEmpty) ...[
                    Text(
                      urun.urunDetay,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A6B7A),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Miktar
                  Text(
                    'Miktar: $miktarStr',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon, color: const Color(0xFF014B92)),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF718096),
            ),
            onTap: onTap,
          ),
          if (isExpanded) const Divider(height: 1, color: Color(0xFFE2E8F0)),
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
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF2D3748),
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
                    color: Color(0xFF4A5568),
                  ),
                ),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? value : '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
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
        'https://esas.eyuboglu.k12.tr/TestDosyalar/SarfMalzemeIstek/';
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
              color: Color(0xFF4A5568),
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
            Container(height: 1, color: const Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }

  Widget _buildOnaySureciAccordion() {
    const onayTipi =
        'Satın Alma'; // Using 'Satın Alma' as confirmed by repository logic
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
            child: BrandedLoadingIndicator(size: 80, strokeWidth: 6),
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
            style: TextStyle(color: Colors.red[600]),
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
                style: TextStyle(color: Colors.black87),
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
            child: BrandedLoadingIndicator(size: 80, strokeWidth: 6),
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
            style: TextStyle(color: Colors.red[600]),
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
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.blue[700],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    personelAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$gorevi - $gorevYeri',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 24),
      ],
    );
  }

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    if (onayDurumu.onayVerecekler.isEmpty) {
      return [
        const Text(
          'Onay süreci bilgisi bulunmamaktadır.',
          style: TextStyle(color: Colors.black87),
        ),
      ];
    }

    return onayDurumu.onayVerecekler.asMap().entries.map((entry) {
      final index = entry.key;
      final personel = entry.value;
      final isLast = index == onayDurumu.onayVerecekler.length - 1;

      // Determine colors based on approval status
      Color statusColor;
      if (personel.onayDurumu == 'Onaylandı') {
        statusColor = Colors.green;
      } else if (personel.onayDurumu == 'Reddedildi') {
        statusColor = Colors.red;
      } else {
        statusColor = Colors.orange;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  personel.onayDurumu == 'Onaylandı'
                      ? Icons.check_circle
                      : personel.onayDurumu == 'Reddedildi'
                      ? Icons.cancel
                      : Icons.hourglass_top,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personel.personelAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (personel.gorevi.isNotEmpty)
                      Text(
                        '${personel.gorevi} - ${personel.gorevYeri}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      personel.onayDurumu,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (personel.islemTarihi != null)
                      Text(
                        DateFormat(
                          'dd.MM.yyyy HH:mm',
                        ).format(personel.islemTarihi!),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) const Divider(height: 24),
        ],
      );
    }).toList();
  }
}

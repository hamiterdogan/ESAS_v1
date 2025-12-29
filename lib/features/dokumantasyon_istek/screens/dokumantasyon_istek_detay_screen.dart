import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/core/screens/image_viewer_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_detay_model.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

class DokumantasyonIstekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;
  final String? onayTipi;

  const DokumantasyonIstekDetayScreen({
    super.key,
    required this.talepId,
    this.onayTipi,
  });

  @override
  ConsumerState<DokumantasyonIstekDetayScreen> createState() =>
      _DokumantasyonIstekDetayScreenState();
}

class _DokumantasyonIstekDetayScreenState
    extends ConsumerState<DokumantasyonIstekDetayScreen> {
  bool _personelExpanded = true;
  bool _detayExpanded = true;
  bool _onayExpanded = true;
  bool _bildirimExpanded = true;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(
      dokumantasyonIstekDetayProvider(widget.talepId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F5),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Dokümantasyon Detay (${widget.talepId})',
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
          onPressed: () => context.pop(),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        ),
        elevation: 0,
      ),
      body: detayAsync.when(
        data: (detay) => _buildContent(context, detay),
        loading: () => const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014B92)),
            ),
          ),
        ),
        error: (error, stack) => _buildError(context, error),
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
                ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId));
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

  Widget _buildContent(
    BuildContext context,
    DokumantasyonIstekDetayResponse detay,
  ) {
    final resolvedOnayTipi = (widget.onayTipi ?? '').trim().isNotEmpty
        ? widget.onayTipi!.trim()
        : 'Dokümantasyon İstek';

    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: resolvedOnayTipi)),
    );

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dokumantasyonIstekDetayProvider(widget.talepId));
        ref.invalidate(
          onayDurumuProvider((
            talepId: widget.talepId,
            onayTipi: resolvedOnayTipi,
          )),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 40),
        children: [
          _buildAccordion(
            icon: Icons.person_outline,
            title: 'Personel Bilgileri',
            isExpanded: _personelExpanded,
            onTap: () => setState(() => _personelExpanded = !_personelExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Ad Soyad',
                  detay.adSoyad.isNotEmpty ? detay.adSoyad : '-',
                ),
                _buildInfoRow(
                  'Görev Yeri',
                  detay.gorevYeri?.isNotEmpty == true ? detay.gorevYeri! : '-',
                ),
                _buildInfoRow(
                  'Görevi',
                  detay.gorevi?.isNotEmpty == true ? detay.gorevi! : '-',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAccordion(
            icon: Icons.description_outlined,
            title: 'Süreç Detayı',
            isExpanded: _detayExpanded,
            onTap: () => setState(() => _detayExpanded = !_detayExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildTalepDetayRows(detay),
            ),
          ),
          const SizedBox(height: 16),
          onayDurumuAsync.when(
            data: (onayDurumu) => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildOnaySureciContent(onayDurumu),
              ),
            ),
            loading: () => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (error, _) => _buildAccordion(
              icon: Icons.approval_outlined,
              title: 'Onay Süreci',
              isExpanded: _onayExpanded,
              onTap: () => setState(() => _onayExpanded = !_onayExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Onay süreci yüklenemedi',
                  style: TextStyle(color: Colors.red[600], fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          onayDurumuAsync.when(
            data: (onayDurumu) => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBildirimContent(onayDurumu),
              ),
            ),
            loading: () => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (error, _) => _buildAccordion(
              icon: Icons.notifications_outlined,
              title: 'Bildirim Gidecekler',
              isExpanded: _bildirimExpanded,
              onTap: () =>
                  setState(() => _bildirimExpanded = !_bildirimExpanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Bildirim gidecekler yüklenemedi',
                  style: TextStyle(color: Colors.red[600], fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTalepDetayRows(DokumantasyonIstekDetayResponse detay) {
    final items = <MapEntry<String, String>>[];
    final isA4 = detay.a4Talebi;

    items.add(
      MapEntry(
        'İstek Türü',
        isA4 ? 'A4 Kağıdı İstek' : 'Dokümantasyon Baskı İstek',
      ),
    );
    items.add(MapEntry('Teslim Tarihi', _formatDate(detay.teslimTarihi)));
    items.add(MapEntry('Oluşturma Tarihi', _formatDate(detay.olusturmaTarihi)));

    if (isA4) {
      items.add(MapEntry('Paket Adedi', (detay.paket ?? 0).toString()));
      items.add(
        MapEntry(
          'Kağıt Talebi',
          detay.kagitTalebi.isNotEmpty ? detay.kagitTalebi : '-',
        ),
      );
    } else {
      items.add(
        MapEntry(
          'Doküman Türü',
          (detay.dokumanTuru ?? '').isNotEmpty ? detay.dokumanTuru! : '-',
        ),
      );
      items.add(
        MapEntry(
          'Kağıt Talebi',
          detay.kagitTalebi.isNotEmpty ? detay.kagitTalebi : '-',
        ),
      );
      items.add(
        MapEntry(
          'Baskı Türü',
          detay.baskiTuru.isNotEmpty ? detay.baskiTuru : '-',
        ),
      );
      items.add(MapEntry('Arkalı Önlü', detay.onluArkali ? 'Evet' : 'Hayır'));
      items.add(
        MapEntry(
          'Teslim Şekli',
          detay.kopyaElden ? 'Kopya elden teslim' : 'Dosya yüklendi',
        ),
      );
      items.add(
        MapEntry(
          'Baskı Adedi',
          detay.baskiAdedi != null ? detay.baskiAdedi.toString() : '-',
        ),
      );
      items.add(
        MapEntry(
          'Sayfa Sayısı',
          detay.sayfaSayisi != null ? detay.sayfaSayisi.toString() : '-',
        ),
      );
      items.add(
        MapEntry(
          'Toplam Sayfa',
          detay.toplamSayfa != null ? detay.toplamSayfa.toString() : '-',
        ),
      );
      items.add(
        MapEntry(
          'Öğrenci Sayısı',
          detay.ogrenciSayisi != null ? detay.ogrenciSayisi.toString() : '-',
        ),
      );
    }

    // Açıklama (alt satıra yazılacak)
    if (detay.aciklama.isNotEmpty) {
      items.add(MapEntry('Açıklama', detay.aciklama));
    }

    // Dosya Açıklaması (alt satıra yazılacak)
    if ((detay.dosyaAciklama ?? '').isNotEmpty) {
      items.add(MapEntry('Dosya Açıklaması', detay.dosyaAciklama!));
    }

    // Dosyalar (tıklanabilir hale getir)
    if (detay.dosyaAdlari.isNotEmpty) {
      items.add(MapEntry('Dosyalar', '')); // Placeholder
    }

    // Seçilen Sınıflar (alt satıra yazılacak)
    if (detay.okullarSatir.isNotEmpty) {
      final siniflar = detay.okullarSatir
          .map((o) {
            final sinifLabel = (o.sinif ?? '').isNotEmpty ? o.sinif : '-';
            final okulLabel = (o.okulKodu ?? '').isNotEmpty ? o.okulKodu : '-';
            final seviye = (o.seviye ?? '').isNotEmpty ? ' (${o.seviye})' : '';
            final numara = (o.numara ?? '').isNotEmpty ? ' • ${o.numara}' : '';
            final isim =
                ((o.adi ?? '').isNotEmpty || (o.soyadi ?? '').isNotEmpty)
                ? ' • ${(o.adi ?? '').trim()} ${(o.soyadi ?? '').trim()}'
                : '';
            return '• $okulLabel - $sinifLabel$seviye$numara$isim';
          })
          .join('\n');
      items.add(MapEntry('Seçilen Sınıflar', siniflar));
    } else {
      items.add(MapEntry('Seçilen Sınıflar', '-'));
    }

    // Widgets oluştur
    final rows = <Widget>[];
    final multiLineFields = <String>{
      'Açıklama',
      'Dosya Açıklaması',
      'Seçilen Sınıflar',
    };

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;
      final multiLine = multiLineFields.contains(item.key);

      // Dosyalar kısmını özel olarak handle et
      if (item.key == 'Dosyalar') {
        // Dosya başlığını ekle
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Dosyalar:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
          ),
        );
        // Her dosya için tıklanabilir row ekle
        for (int j = 0; j < detay.dosyaAdlari.length; j++) {
          final fileName = detay.dosyaAdlari[j];
          rows.add(
            _buildClickableFileRow(
              detay.dosyaAdlari.length > 1 ? 'Dosya ${j + 1}' : 'Dosya',
              fileName,
              isLast: j == detay.dosyaAdlari.length - 1 && isLast,
            ),
          );
        }
      } else {
        rows.add(
          _buildInfoRow(
            item.key,
            item.value,
            isLast: isLast,
            multiLine: multiLine,
          ),
        );
      }
    }

    return rows;
  }

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    final List<Widget> widgets = [];

    // 1. Talep Eden Personel (En üstte)
    widgets.add(
      _buildTalepEdenCard(
        personelAdi: onayDurumu.talepEdenPerAdi,
        gorevYeri: onayDurumu.talepEdenPerGorevYeri,
        gorevi: onayDurumu.talepEdenPerGorev,
        tarih: onayDurumu.talepEdenTarih,
        isLast: onayDurumu.onayVerecekler.isEmpty,
      ),
    );

    // 2. Onay Verecekler listesi
    for (int i = 0; i < onayDurumu.onayVerecekler.length; i++) {
      final personel = onayDurumu.onayVerecekler[i];

      // Onay durumuna göre ikon ve renk belirle
      IconData icon;
      Color iconColor;

      if (personel.onay == true) {
        icon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (personel.onay == false) {
        icon = Icons.cancel;
        iconColor = Colors.red;
      } else if (personel.geriGonderildi) {
        icon = Icons.replay;
        iconColor = Colors.orange;
      } else {
        icon = Icons.hourglass_empty;
        iconColor = Colors.orange;
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
                color: const Color(0xFF014B92).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                color: Color(0xFF014B92),
                size: 22,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 70, color: Colors.grey[300]),
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
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF014B92).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_task,
                        size: 18,
                        color: Color(0xFF014B92),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Talep Oluşturuldu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF014B92),
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
                    color: Color(0xFF4A5568),
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(tarih),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF718096),
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
              Container(width: 2, height: 80, color: Colors.grey[300]),
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
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                  ),
                ),
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    durum,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                ),
                if (tarih != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(tarih),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
                if (aciklama != null && aciklama.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Not: $aciklama',
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBildirimContent(OnayDurumuResponse onayDurumu) {
    if (onayDurumu.bildirimGidecekler.isEmpty) {
      return [const Text('Bildirim bilgisi bulunamadı')];
    }

    return [
      ...onayDurumu.bildirimGidecekler.asMap().entries.map((entry) {
        final idx = entry.key;
        final personel = entry.value;
        final isLast = idx == onayDurumu.bildirimGidecekler.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                personel.personelAdi,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${personel.gorevYeri} - ${personel.gorevi}',
                style: const TextStyle(fontSize: 15, color: Color(0xFF718096)),
              ),
            ],
          ),
        );
      }),
    ];
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF014B92).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFF014B92), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF4A5568),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.06),
                    end: Offset.zero,
                  ).animate(curved),
                  child: SizeTransition(
                    sizeFactor: curved,
                    axisAlignment: -1,
                    child: child,
                  ),
                ),
              );
            },
            child: isExpanded
                ? Column(
                    key: const ValueKey('expanded'),
                    children: [
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF1F5F9),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: child,
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed')),
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
            // Alt satıra yazılacak format
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
            // İki nokta üst üsteden sonra boşluk bırakılıp yazılacak format
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final d = _formatDate(date);
    final time =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$d $time';
  }

  Widget _buildClickableFileRow(
    String label,
    String fileName, {
    bool isLast = false,
  }) {
    const String baseUrl =
        'https://esas.eyuboglu.k12.tr/TestDosyalar/DokumantasyonIstek/';
    final String fileUrl = '$baseUrl$fileName';

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
                    fileName,
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

  Color _statusColor(String status) {
    if (status.toLowerCase().contains('redd')) return Colors.red;
    if (status.toLowerCase().contains('onay')) return Colors.orange;
    if (status.toLowerCase().contains('kabul') ||
        status.toLowerCase().contains('tamam'))
      return Colors.green;
    return const Color(0xFF475569);
  }
}

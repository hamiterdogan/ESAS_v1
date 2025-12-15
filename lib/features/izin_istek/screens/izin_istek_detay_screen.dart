import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/screens/pdf_viewer_screen.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay_model.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';

class IzinIstekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;
  final String? onayTipi;

  const IzinIstekDetayScreen({super.key, required this.talepId, this.onayTipi});

  @override
  ConsumerState<IzinIstekDetayScreen> createState() =>
      _IzinIstekDetayScreenState();
}

class _IzinIstekDetayScreenState extends ConsumerState<IzinIstekDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _izinDetaylariExpanded = true;
  bool _onaySureciExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final izinDetayAsync = ref.watch(izinIstekDetayProvider(widget.talepId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'İzin Talep Detayı (${widget.talepId})',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
      body: izinDetayAsync.when(
        data: (detay) => _buildContent(context, detay),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF014B92)),
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
                ref.invalidate(izinIstekDetayProvider(widget.talepId));
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

  Widget _buildContent(BuildContext context, IzinIstekDetayResponse detay) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Accordion - Personel Bilgileri
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
                  detay.adSoyad.isNotEmpty ? detay.adSoyad : '-',
                ),
                _buildInfoRow(
                  'Görev Yeri',
                  detay.gorevYeri.isNotEmpty ? detay.gorevYeri : '-',
                ),
                _buildInfoRow(
                  'Görevi',
                  detay.gorevi.isNotEmpty ? detay.gorevi : '-',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2. Accordion - İzin Detayları
          _buildAccordion(
            icon: Icons.description_outlined,
            title: 'İzin Detayları',
            isExpanded: _izinDetaylariExpanded,
            onTap: () {
              setState(() {
                _izinDetaylariExpanded = !_izinDetaylariExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildIzinDetayRows(detay),
            ),
          ),
          const SizedBox(height: 16),
          // 3. Accordion - Onay Süreci
          _buildOnaySureciAccordion(),
          const SizedBox(height: 16),
          // 4. Accordion - Bildirim Gidecekler
          _buildBildirimGideceklerAccordion(),
        ],
      ),
    );
  }

  Widget _buildOnaySureciAccordion() {
    final resolvedOnayTipi = (widget.onayTipi ?? '').trim().isNotEmpty
        ? widget.onayTipi!.trim()
        : 'İzin İstek';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: resolvedOnayTipi)),
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
            style: TextStyle(color: Colors.red[600], fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildBildirimGideceklerAccordion() {
    final resolvedOnayTipi = (widget.onayTipi ?? '').trim().isNotEmpty
        ? widget.onayTipi!.trim()
        : 'İzin İstek';
    final onayDurumuAsync = ref.watch(
      onayDurumuProvider((talepId: widget.talepId, onayTipi: resolvedOnayTipi)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildBildirimGideceklerContent(onayDurumu),
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
            style: TextStyle(color: Colors.red[600], fontSize: 15),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBildirimGideceklerContent(OnayDurumuResponse onayDurumu) {
    final List<Widget> widgets = [];

    for (int i = 0; i < onayDurumu.bildirimGidecekler.length; i++) {
      final personel = onayDurumu.bildirimGidecekler[i];
      final isLast = i == onayDurumu.bildirimGidecekler.length - 1;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad Soyad
              Text(
                personel.personelAdi,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 4),
              // Görev Yeri ve Görevi
              Text(
                '${personel.gorevYeri} - ${personel.gorevi}',
                style: const TextStyle(fontSize: 15, color: Color(0xFF718096)),
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
              ],
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Bildirim gidecek kişi bulunmuyor',
            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
          ),
        ),
      );
    }

    return widgets;
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
        iconColor = Colors.orange; // Onay Bekliyor - turuncu renk
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
        // Sol taraf - İkon ve çizgi
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
              Container(width: 2, height: 70, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 12),
        // Sağ taraf - Bilgiler
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad Soyad
                Text(
                  personelAdi,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                // Talep Oluşturuldu badge
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
                // Görev Yeri
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                  ),
                ),
                // Görevi
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                // Tarih
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
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol taraf - İkon ve çizgi
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
        // Sağ taraf - Bilgiler
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad Soyad ve Durum
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        personelAdi,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Görev Yeri
                Text(
                  gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5568),
                  ),
                ),
                // Görevi
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 6),
                // Durum badge
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
                // Tarih
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
                // Açıklama
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

  /// İzin türüne göre gösterilecek detay satırlarını oluşturur
  /// izinSebebiId değerleri:
  /// 1: Yıllık İzin, 2: Evlilik İzni, 3: Vefat İzni, 4: Hastalık İzni,
  /// 5: Mazeret İzni, 6: Dini İzin, 7: Doğum İzni, 8: Kurum Görevlendirmesi
  List<Widget> _buildIzinDetayRows(IzinIstekDetayResponse detay) {
    final List<Widget> rows = [];
    final izinTuruId = detay.izinSebebiId;

    // Ortak alanlar - İzin Türü ve Açıklama her zaman gösterilir
    rows.add(
      _buildInfoRow(
        'İzin Türü',
        detay.izinSebebi.isNotEmpty ? detay.izinSebebi : '-',
      ),
    );
    rows.add(
      _buildInfoRow(
        'Açıklama',
        detay.aciklama.isNotEmpty ? detay.aciklama : '-',
        multiLine: true,
      ),
    );

    // Başlangıç ve Bitiş Tarihi - tüm izin türlerinde gösterilir
    rows.add(
      _buildInfoRow(
        'Başlangıç Tarihi',
        _formatDate(detay.izinBaslangicTarihi),
        multiLine: false,
      ),
    );
    rows.add(
      _buildInfoRow(
        'Bitiş Tarihi',
        _formatDate(detay.izinBitisTarihi),
        multiLine: false,
      ),
    );

    // Saat alanları - sadece belirli izin türlerinde gösterilir
    // Saat gösterilecek türler: 1 (Yıllık), 4 (Hastalık), 5 (Mazeret), 8 (Kurum Görevlendirmesi)
    final saatGosterilecekTurler = [1, 4, 5, 8];
    if (saatGosterilecekTurler.contains(izinTuruId)) {
      if (detay.izinBaslangicSaati != '00:00:00') {
        rows.add(
          _buildInfoRow(
            'Başlangıç Saati',
            _formatTime(detay.izinBaslangicSaati),
            multiLine: false,
          ),
        );
      }
      if (detay.izinBitisSaati != '00:00:00') {
        rows.add(
          _buildInfoRow(
            'Bitiş Saati',
            _formatTime(detay.izinBitisSaati),
            multiLine: false,
          ),
        );
      }
    }

    // İzin türüne özel alanlar
    switch (izinTuruId) {
      case 2: // Evlilik İzni
        if (detay.evlilikTarihi != null) {
          rows.add(
            _buildInfoRow('Evlilik Tarihi', _formatDate(detay.evlilikTarihi!)),
          );
        }
        if (detay.esAdi != null && detay.esAdi!.isNotEmpty) {
          rows.add(_buildInfoRow('Eş Adı', detay.esAdi!));
        }
        break;

      case 3: // Vefat İzni
        // Vefat izni için özel alan yok (yakınlık derecesi aciklama'da olabilir)
        break;

      case 4: // Hastalık İzni
        rows.add(
          _buildInfoRow('Doktor Raporu', detay.doktorRaporu ? 'Var' : 'Yok'),
        );
        if (detay.hastalik != null && detay.hastalik!.isNotEmpty) {
          rows.add(_buildInfoRow('Hastalık', detay.hastalik!));
        }
        if (detay.dosyaAdi != null && detay.dosyaAdi!.isNotEmpty) {
          rows.add(_buildClickableFileRow('Rapor Dosyası', detay.dosyaAdi!));
        }
        break;

      case 6: // Dini İzin
        if (detay.diniGun != null && detay.diniGun!.isNotEmpty) {
          rows.add(_buildInfoRow('Dini Gün', detay.diniGun!));
        }
        break;

      case 7: // Doğum İzni
        if (detay.dogumTarihi != null) {
          rows.add(
            _buildInfoRow(
              'Tahmini Doğum Tarihi',
              _formatDate(detay.dogumTarihi!),
            ),
          );
        }
        break;
    }

    // Girilmeyen Ders Saati - her zaman göster
    rows.add(
      _buildInfoRow(
        'Girilmeyen Toplam Ders Saati',
        (detay.izindeGirilmeyenToplamDersSaati ?? 0).toString(),
        multiLine: false,
      ),
    );

    // Hesaplanan İzin Günü - değer varsa göster
    if (detay.hesaplananIzinGunu != null && detay.hesaplananIzinGunu! > 0) {
      rows.add(
        _buildInfoRow(
          'Hesaplanan İzin Günü',
          detay.hesaplananIzinGunu.toString(),
        ),
      );
    }

    // İzinde Bulunacağı Adres - her zaman göster (son eleman)
    rows.add(
      _buildInfoRow(
        'İzinde Bulunacağı Adres',
        detay.izindeBulunacagiAdres.isNotEmpty
            ? detay.izindeBulunacagiAdres
            : '-',
        isLast: true,
        multiLine: true,
      ),
    );

    return rows;
  }

  Widget _buildAccordion({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Tıklanabilir
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gradientStart.withValues(alpha: 0.05),
                borderRadius: isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      )
                    : BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gradientStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 24, color: AppColors.gradientStart),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.gradientStart,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content - Animasyonlu açılma/kapanma (Fade efekti ile)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: isExpanded
                  ? Padding(padding: const EdgeInsets.all(16), child: child)
                  : const SizedBox.shrink(),
            ),
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
            // Çok satırlı görünüm - başlık ve değer ayrı satırda
            Text(
              '$label:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF2D3748),
              ),
            ),
          ] else ...[
            // Tek satırlı görünüm - başlık ve değer aynı satırda
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
                    value,
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
        'https://esas.eyuboglu.k12.tr/TestDosyalar/IzinIstek/';
    final String fileUrl = '$baseUrl$fileName';

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
              // Dosya uzantısını kontrol et
              final extension = fileName.split('.').last.toLowerCase();

              if (extension == 'pdf') {
                // PDF dosyası için uygulama içi görüntüleme
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      title: 'Rapor Dosyası',
                      pdfUrl: fileUrl,
                    ),
                  ),
                );
              } else {
                // Diğer dosyalar için tarayıcıda aç
                final uri = Uri.parse(fileUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    _showErrorBottomSheet('Dosya açılamadı: $e');
                  }
                }
              }
            },
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.gradientEnd,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  fileName.split('.').last.toLowerCase() == 'pdf'
                      ? Icons.picture_as_pdf
                      : Icons.open_in_new,
                  size: 16,
                  color: AppColors.gradientEnd,
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
  }

  String _formatTime(String time) {
    // "00:00:00" formatından "00:00" formatına dönüştür
    if (time.isEmpty) return '-';
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                onPressed: () => Navigator.pop(sheetContext),
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

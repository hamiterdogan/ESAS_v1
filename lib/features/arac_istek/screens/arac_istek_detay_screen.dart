import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_detay_model.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

class AracIstekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const AracIstekDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<AracIstekDetayScreen> createState() =>
      _AracIstekDetayScreenState();
}

class _AracIstekDetayScreenState extends ConsumerState<AracIstekDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _aracDetaylariExpanded = true;
  bool _onaySureciExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(aracIstekDetayProvider(widget.talepId));
    final personelAsync = ref.watch(personelBilgiProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Araç İstek Detayı (${widget.talepId})',
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
        ),
        elevation: 0,
      ),
      body: detayAsync.when(
        data: (detay) => _buildContent(context, detay, personelAsync),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AracIstekDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
  ) {
    final adSoyad = detay.adSoyad.isNotEmpty
        ? detay.adSoyad
        : (personelAsync.value?.adSoyad ?? '-');
    final gorevYeri = detay.gorevYeri.isNotEmpty
        ? detay.gorevYeri
        : (personelAsync.value?.gorevYeri ?? '-');
    final gorevi = detay.gorev.isNotEmpty
        ? detay.gorev
        : (personelAsync.value?.gorev ?? '-');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
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
            icon: Icons.directions_car_outlined,
            title: 'Araç İstek Detayları',
            isExpanded: _aracDetaylariExpanded,
            onTap: () {
              setState(() {
                _aracDetaylariExpanded = !_aracDetaylariExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildAracDetayRows(detay),
            ),
          ),
          const SizedBox(height: 16),
          _buildOnaySureciAccordion(),
          const SizedBox(height: 16),
          _buildBildirimGideceklerAccordion(),
        ],
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
                ref.invalidate(aracIstekDetayProvider(widget.talepId));
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

  List<Widget> _buildAracDetayRows(AracIstekDetayResponse detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    // Gidilecek Yer (alt satıra yazılacak)
    if (detay.gidilecekYerler.isNotEmpty) {
      items.add(MapEntry('Gidilecek Yer', detay.gidilecekYerler));
    }

    // Tahmini Mesafe (km) (iki nokta üst üsteden sonra boşluk bırakılıp yazılacak)
    if (detay.mesafe.isNotEmpty) {
      items.add(MapEntry('Tahmini Mesafe (km)', detay.mesafe));
    }

    // Gidilecek Tarih (iki nokta üst üsteden sonra boşluk bırakılıp yazılacak)
    if (detay.gidilecekTarih.isNotEmpty) {
      final tarihStr = _formatDateString(detay.gidilecekTarih);
      items.add(MapEntry('Gidilecek Tarih', tarihStr));
    }

    // Gidiş Saati (iki nokta üst üsteden sonra boşluk bırakılıp yazılacak)
    if (detay.gidisSaat.isNotEmpty) {
      final saatStr = _formatTimeString(detay.gidisSaat);
      items.add(MapEntry('Gidiş Saati', saatStr));
    }

    // Dönüş Saati (iki nokta üst üsteden sonra boşluk bırakılıp yazılacak)
    if (detay.donusSaat.isNotEmpty) {
      final saatStr = _formatTimeString(detay.donusSaat);
      items.add(MapEntry('Dönüş Saati', saatStr));
    }

    // Talep Edilen Araç Türü (alt satıra yazılacak)
    if (detay.aracTuru.isNotEmpty) {
      items.add(MapEntry('Talep Edilen Araç Türü', detay.aracTuru));
    }

    // Araç İstek Nedeni (alt satıra yazılacak)
    if (detay.istekNedeni.isNotEmpty && detay.istekNedeni != '0') {
      final nedeniStr = _getIstekNedeniText(detay.istekNedeni);
      items.add(MapEntry('Araç İstek Nedeni', nedeniStr));
    }

    // Diğer Neden (alt satıra yazılacak)
    if (detay.istekNedeniDiger.isNotEmpty) {
      items.add(MapEntry('Diğer Neden', detay.istekNedeniDiger));
    }

    // Widget'ları oluştur
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // Son eleman kontrolü: yolcu sayısı varsa o son eleman, yoksa bu eleman son
      final isLast = i == items.length - 1 && detay.yolcuSayisi.isEmpty;
      
      // Hangi alanlar alt satıra yazılacak?
      final multiLineFields = [
        'Gidilecek Yer',
        'Talep Edilen Araç Türü',
        'Araç İstek Nedeni',
        'Diğer Neden',
      ];
      final multiLine = multiLineFields.contains(item.key);
      
      rows.add(_buildInfoRow(item.key, item.value, isLast: isLast, multiLine: multiLine));
    }

    // Yolcu Listesi - özel widget olarak gösterilecek (items'tan sonra eklenir)
    final yolcuListesi = detay.yolcuIsimleri;
    if (yolcuListesi.isNotEmpty) {
      // Yolcu listesi, toplam yolcu sayısından önce gelir, bu yüzden son eleman değil
      final isLast = detay.yolcuSayisi.isEmpty;
      rows.add(_buildYolcuListesiWidget(yolcuListesi, isLast));
    }

    // Toplam Yolcu Sayısı (iki nokta üst üsteden sonra boşluk bırakılıp yazılacak) - en son
    if (detay.yolcuSayisi.isNotEmpty) {
      rows.add(_buildInfoRow('Toplam Yolcu Sayısı', detay.yolcuSayisi, isLast: true, multiLine: false));
    }

    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Detay bilgisi bulunamadı',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

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

  Widget _buildYolcuListesiWidget(List<Map<String, String>> yolcuListesi, bool isLast) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Text(
            'Yolcu Listesi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          // Yolcular
          ...yolcuListesi.asMap().entries.map((entry) {
            final index = entry.key;
            final yolcu = entry.value;
            final isLastYolcu = index == yolcuListesi.length - 1;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Yolcu Adı (bold)
                Text(
                  yolcu['ad'] ?? '-',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                // Görev Yeri
                if (yolcu['gorevYeri']?.isNotEmpty ?? false) ...[
                  Text(
                    yolcu['gorevYeri']!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                // Görevi
                if (yolcu['gorevi']?.isNotEmpty ?? false)
                  Text(
                    yolcu['gorevi']!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF718096),
                    ),
                  ),
                // Yolcular arası çizgi
                if (!isLastYolcu) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }).toList(),
          // Son eleman kontrolü için çizgi
          if (!isLast) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: const Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false, bool multiLine = true}) {
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

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeString(String timeStr) {
    // "07:50:00" formatından "07:50" formatına dönüştür
    if (timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  String _getIstekNedeniText(String nedeni) {
    // İstek nedeni kodlarını metne çevir
    final nedeniMap = {
      '0': 'Diğer',
      '1': 'Eğitim',
      '2': 'Toplantı',
      '3': 'Saha Çalışması',
      '4': 'Resmi İş',
      '5': 'Diğer',
    };
    return nedeniMap[nedeni] ?? nedeni;
  }

  Widget _buildOnaySureciAccordion() {
    const onayTipi = 'Araç İstek';
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

  Widget _buildBildirimGideceklerAccordion() {
    const onayTipi = 'Araç İstek';
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
    final widgets = <Widget>[];

    for (int i = 0; i < onayDurumu.bildirimGidecekler.length; i++) {
      final personel = onayDurumu.bildirimGidecekler[i];
      final isLast = i == onayDurumu.bildirimGidecekler.length - 1;

      widgets.add(
        Padding(
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

  static String _formatDateTime(DateTime dateTime) {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    final date =
        '${twoDigits(dateTime.day)}.${twoDigits(dateTime.month)}.${dateTime.year}';
    final time = '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
    return '$date $time';
  }
}

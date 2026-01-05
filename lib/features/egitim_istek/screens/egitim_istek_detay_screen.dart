import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_istek_detay_model.dart';
import 'package:esas_v1/features/egitim_istek/providers/egitim_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

class EgitimIstekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const EgitimIstekDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<EgitimIstekDetayScreen> createState() =>
      _EgitimIstekDetayScreenState();
}

class _EgitimIstekDetayScreenState
    extends ConsumerState<EgitimIstekDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _egitimDetaylariExpanded = true;
  bool _egitimAlacakPersonelExpanded = false;
  bool _paylasimYapilacakKisilerExpanded = false;
  bool _onaySureciExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(egitimIstekDetayProvider(widget.talepId));
    final personelAsync = ref.watch(personelBilgiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F5),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Eğitim İstek Detayı (${widget.talepId})',
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
        data: (detay) => _buildContent(context, detay, personelAsync),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EgitimIstekDetayResponse detay,
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

    final showEgitimAlacaklar =
        detay.topluIstek && detay.egitimAlacakPersoneller.isNotEmpty;

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
              icon: Icons.school_outlined,
              title: 'Eğitim İstek Detayları',
              isExpanded: _egitimDetaylariExpanded,
              onTap: () {
                setState(() {
                  _egitimDetaylariExpanded = !_egitimDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildEgitimDetayRows(detay),
              ),
            ),
            const SizedBox(height: 16),
            if (showEgitimAlacaklar)
              _buildAccordion(
                icon: Icons.groups_outlined,
                title: 'Eğitim Alacak Personel',
                isExpanded: _egitimAlacakPersonelExpanded,
                onTap: () {
                  setState(() {
                    _egitimAlacakPersonelExpanded =
                        !_egitimAlacakPersonelExpanded;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildPersonelListContent(
                    detay.egitimAlacakPersoneller,
                    emptyText: 'Eğitim alacak personel bulunmuyor',
                  ),
                ),
              ),
            if (showEgitimAlacaklar) const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.share_outlined,
              title: 'Paylaşım Yapılacak Kişiler',
              isExpanded: _paylasimYapilacakKisilerExpanded,
              onTap: () {
                setState(() {
                  _paylasimYapilacakKisilerExpanded =
                      !_paylasimYapilacakKisilerExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildPersonelListContent(
                  detay.paylasimYapilacakPersoneller,
                  emptyText: 'Paylaşım yapılacak kişi bulunmuyor',
                ),
              ),
            ),
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
    return const Center(
      child: SizedBox(
        width: 153,
        height: 153,
        child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
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
                ref.invalidate(egitimIstekDetayProvider(widget.talepId));
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

  List<Widget> _buildEgitimDetayRows(EgitimIstekDetayResponse detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    if (detay.egitiminAdi.isNotEmpty) {
      items.add(MapEntry('Eğitimin Adı', detay.egitiminAdi));
    }

    if (detay.egitiminAdiDiger.isNotEmpty) {
      items.add(MapEntry('Eğitimin Adı (Diğer)', detay.egitiminAdiDiger));
    }

    if (detay.departman.isNotEmpty) {
      items.add(MapEntry('Departman', detay.departman));
    }

    if (detay.egitimTuru.isNotEmpty) {
      items.add(MapEntry('Eğitim Türü', detay.egitimTuru));
    }

    if (detay.sirketAdi.isNotEmpty) {
      items.add(MapEntry('Şirket Adı', detay.sirketAdi));
    }

    if (detay.egitimIcerigi.isNotEmpty) {
      items.add(MapEntry('Eğitim İçeriği', detay.egitimIcerigi));
    }

    if (detay.webSitesi.isNotEmpty) {
      items.add(MapEntry('Web Sitesi', detay.webSitesi));
    }

    if (detay.egitimBaslangicTarihi.isNotEmpty) {
      items.add(
        MapEntry(
          'Eğitim Başlangıç Tarihi',
          _formatDateString(detay.egitimBaslangicTarihi),
        ),
      );
    }

    if (detay.egitimBitisTarihi.isNotEmpty) {
      items.add(
        MapEntry(
          'Eğitim Bitiş Tarihi',
          _formatDateString(detay.egitimBitisTarihi),
        ),
      );
    }

    if (detay.egitimBaslangicSaati.isNotEmpty) {
      items.add(
        MapEntry(
          'Eğitim Başlangıç Saati',
          _formatTimeString(detay.egitimBaslangicSaati),
        ),
      );
    }

    if (detay.egitimBitisSaati.isNotEmpty) {
      items.add(
        MapEntry(
          'Eğitim Bitiş Saati',
          _formatTimeString(detay.egitimBitisSaati),
        ),
      );
    }

    if (detay.egitimSuresiGun.isNotEmpty) {
      items.add(MapEntry('Eğitim Süresi (Gün)', detay.egitimSuresiGun));
    }

    if (detay.egitimSuresiSaat.isNotEmpty) {
      items.add(MapEntry('Eğitim Süresi (Saat)', detay.egitimSuresiSaat));
    }

    if (detay.girilmeyenToplamDersSaati > 0) {
      items.add(
        MapEntry(
          'Girilmeyen Toplam Ders Saati',
          '${detay.girilmeyenToplamDersSaati}',
        ),
      );
    }

    if (detay.egitimYeri.isNotEmpty) {
      items.add(MapEntry('Eğitim Yeri', detay.egitimYeri));
    }

    items.add(MapEntry('Online', detay.online ? 'Evet' : 'Hayır'));

    if (detay.ulke.isNotEmpty) {
      items.add(MapEntry('Ülke', detay.ulke));
    }

    if (detay.sehir.isNotEmpty) {
      items.add(MapEntry('Şehir', detay.sehir));
    }

    if (detay.adres.isNotEmpty) {
      items.add(MapEntry('Adres', detay.adres));
    }

    items.add(MapEntry('Ücretsiz', detay.ucretsiz ? 'Evet' : 'Hayır'));

    if (!detay.ucretsiz) {
      if (detay.egitimUcreti != 0) {
        items.add(MapEntry('Eğitim Ücreti', '${detay.egitimUcreti}'));
      }
      if (detay.ulasimUcreti != 0) {
        items.add(MapEntry('Ulaşım Ücreti', '${detay.ulasimUcreti}'));
      }
      if (detay.konaklamaUcreti != 0) {
        items.add(MapEntry('Konaklama Ücreti', '${detay.konaklamaUcreti}'));
      }
      if (detay.yemekUcreti != 0) {
        items.add(MapEntry('Yemek Ücreti', '${detay.yemekUcreti}'));
      }
      if (detay.toplamUcret != 0) {
        items.add(MapEntry('Toplam Ücret', '${detay.toplamUcret}'));
      }
      if (detay.genelToplamUcret != 0) {
        items.add(MapEntry('Genel Toplam Ücret', '${detay.genelToplamUcret}'));
      }
      if (detay.kurumunKarsiladigiUcret != 0) {
        items.add(
          MapEntry(
            'Kurumun Karşıladığı Ücret',
            '${detay.kurumunKarsiladigiUcret}',
          ),
        );
      }
    }

    if (detay.odemeSekli?.isNotEmpty == true) {
      items.add(MapEntry('Ödeme Şekli', detay.odemeSekli!));
    }

    items.add(MapEntry('Peşin', detay.pesin ? 'Evet' : 'Hayır'));

    if (!detay.pesin && detay.vadeGun > 0) {
      items.add(MapEntry('Vade (Gün)', '${detay.vadeGun}'));
    }

    if (detay.hesapNo.isNotEmpty) {
      items.add(MapEntry('Hesap No', detay.hesapNo));
    }

    if (detay.ekBilgi.isNotEmpty) {
      items.add(MapEntry('Ek Bilgi', detay.ekBilgi));
    }

    if (detay.paylasimBaslangicTarihi.isNotEmpty) {
      items.add(
        MapEntry(
          'Paylaşım Başlangıç Tarihi',
          _formatDateString(detay.paylasimBaslangicTarihi),
        ),
      );
    }

    if (detay.paylasimBitisTarihi.isNotEmpty) {
      items.add(
        MapEntry(
          'Paylaşım Bitiş Tarihi',
          _formatDateString(detay.paylasimBitisTarihi),
        ),
      );
    }

    if (detay.paylasimBaslangicSaati.isNotEmpty) {
      items.add(
        MapEntry(
          'Paylaşım Başlangıç Saati',
          _formatTimeString(detay.paylasimBaslangicSaati),
        ),
      );
    }

    if (detay.paylasimBitisSaati.isNotEmpty) {
      items.add(
        MapEntry(
          'Paylaşım Bitiş Saati',
          _formatTimeString(detay.paylasimBitisSaati),
        ),
      );
    }

    if (detay.paylasimYeri.isNotEmpty) {
      items.add(MapEntry('Paylaşım Yeri', detay.paylasimYeri));
    }

    items.add(MapEntry('Toplu İstek', detay.topluIstek ? 'Evet' : 'Hayır'));

    if (items.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Detay bilgisi bulunamadı',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
      return rows;
    }

    final multiLineFields = <String>{
      'Eğitimin Adı',
      'Eğitimin Adı (Diğer)',
      'Şirket Adı',
      'Eğitim İçeriği',
      'Adres',
      'Ek Bilgi',
      'Paylaşım Yeri',
      'Web Sitesi',
    };

    final singleLineFields = <String>{
      'Eğitim Başlangıç Tarihi',
      'Eğitim Bitiş Tarihi',
      'Eğitim Başlangıç Saati',
      'Eğitim Bitiş Saati',
      'Eğitim Süresi (Gün)',
      'Eğitim Süresi (Saat)',
      'Girilmeyen Toplam Ders Saati',
      'Online',
      'Ücretsiz',
      'Peşin',
      'Vade (Gün)',
      'Toplu İstek',
    };

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;
      final multiLine =
          multiLineFields.contains(item.key) &&
          !singleLineFields.contains(item.key);

      rows.add(
        _buildInfoRow(
          item.key,
          item.value,
          isLast: isLast,
          multiLine: multiLine,
        ),
      );
    }

    return rows;
  }

  List<Widget> _buildPersonelListContent(
    List<EgitimIstekPersonelItem> personeller, {
    required String emptyText,
  }) {
    final widgets = <Widget>[];

    for (int i = 0; i < personeller.length; i++) {
      final personel = personeller[i];
      final isLast = i == personeller.length - 1;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                personel.adiSoyadi.isNotEmpty ? personel.adiSoyadi : '-',
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
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            emptyText,
            style: const TextStyle(fontSize: 14, color: Color(0xFF718096)),
          ),
        ),
      );
    }

    return widgets;
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

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTimeString(String timeStr) {
    if (timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  Widget _buildOnaySureciAccordion() {
    const onayTipi = 'Eğitim İstek';
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
              width: 80,
              height: 80,
              child: BrandedLoadingIndicator(size: 80, strokeWidth: 6),
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
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: iconColor),
                      const SizedBox(width: 4),
                      Text(
                        durum,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                        ),
                      ),
                    ],
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
    const onayTipi = 'Eğitim İstek';
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
              width: 80,
              height: 80,
              child: BrandedLoadingIndicator(size: 80, strokeWidth: 6),
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

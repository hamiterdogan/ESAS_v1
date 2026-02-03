import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/onay_form_content.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_istek_detay_model.dart';
import 'package:esas_v1/features/egitim_istek/providers/egitim_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/features/egitim_istek/repositories/egitim_istek_repository.dart';

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
  bool _egitimBilgileriExpanded = true;
  bool _egitimAlacakPersonelExpanded = false;
  bool _ucretBilgisiExpanded = true;
  bool _paylasimBilgileriExpanded = true;
  bool _yuklenenDosyalarExpanded = true;
  bool _paylasimYapilacakKisilerExpanded = false;
  bool _onaySureciExpanded = true;
  bool _onayFormExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  late TextEditingController _kurumUcretController;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _kurumUcretController = TextEditingController();
  }

  @override
  void dispose() {
    _kurumUcretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(egitimIstekDetayProvider(widget.talepId));
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
                'Eğitim İstek Detayı (${widget.talepId})',
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
                  context.go('/egitim_istek');
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
    EgitimIstekDetayResponse detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
  ) {
    // Initialize controller only once when data is available
    if (!_isControllerInitialized) {
      _kurumUcretController.text =
          detay.kurumunKarsiladigiUcret > 0
              ? _formatNumber(detay.kurumunKarsiladigiUcret)
              : '';
      _isControllerInitialized = true;
    }

    final currentKullaniciAdi = ref.watch(currentKullaniciAdiProvider);
    final isAerbil = currentKullaniciAdi == 'AERBIL';

    final adSoyad =
        detay.adSoyad.isNotEmpty
            ? detay.adSoyad
            : (personelAsync.value?.adSoyad ?? '-');
    final gorevYeri =
        detay.gorevYeri.isNotEmpty
            ? detay.gorevYeri
            : (personelAsync.value?.gorevYeri ?? '-');
    final gorevi =
        detay.gorevi.isNotEmpty
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
              title: 'Eğitim Bilgileri',
              isExpanded: _egitimBilgileriExpanded,
              onTap: () {
                setState(() {
                  _egitimBilgileriExpanded = !_egitimBilgileriExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildEgitimBilgileriRows(detay),
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
            if (detay.egitimUcreti > 0)
              _buildAccordion(
                icon: Icons.payments_outlined,
                title: 'Kişi Başı Ücret Bilgisi',
                isExpanded: _ucretBilgisiExpanded,
                onTap: () {
                  setState(() {
                    _ucretBilgisiExpanded = !_ucretBilgisiExpanded;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildUcretBilgisiRows(detay, isAerbil),
                ),
              ),
            if (detay.egitimUcreti > 0) const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.share_location_outlined,
              title: 'Eğitim Sonrası Kurum İçi Paylaşım',
              isExpanded: _paylasimBilgileriExpanded,
              onTap: () {
                setState(() {
                  _paylasimBilgileriExpanded = !_paylasimBilgileriExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildPaylasimRows(detay),
              ),
            ),
            const SizedBox(height: 16),
            _buildAccordion(
              icon: Icons.attach_file_outlined,
              title: 'Yüklenen Dosyalar',
              isExpanded: _yuklenenDosyalarExpanded,
              onTap: () {
                setState(() {
                  _yuklenenDosyalarExpanded = !_yuklenenDosyalarExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildDosyalarRows(detay),
              ),
            ),
            const SizedBox(height: 16),
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
                ref.invalidate(egitimIstekDetayProvider(widget.talepId));
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

  List<Widget> _buildEgitimBilgileriRows(EgitimIstekDetayResponse detay) {
    final rows = <Widget>[
      _buildInfoRow(
        'Eğitim Başlangıç Tarihi',
        _formatDateString(detay.egitimBaslangicTarihi),
      ),
      _buildInfoRow(
        'Eğitim Bitiş Tarihi',
        _formatDateString(detay.egitimBitisTarihi),
      ),
      _buildInfoRow(
        'Eğitim Başlangıç Saati',
        _formatTimeString(detay.egitimBaslangicSaati),
      ),
      _buildInfoRow(
        'Eğitim Bitiş Saati',
        _formatTimeString(detay.egitimBitisSaati),
      ),
      if (detay.egitimSuresiGun.isNotEmpty ||
          detay.egitimSuresiSaat.isNotEmpty) ...[
        Builder(
          builder: (context) {
            final parts = <String>[];
            if (detay.egitimSuresiGun.isNotEmpty) {
              parts.add('${detay.egitimSuresiGun} Gün');
            }
            if (detay.egitimSuresiSaat.isNotEmpty) {
              parts.add('günde ${detay.egitimSuresiSaat} Saat');
            }
            return _buildInfoRow('Eğitimin Süresi', parts.join(', '));
          },
        ),
      ],
      if (detay.girilmeyenToplamDersSaati > 0)
        _buildInfoRow(
          'Girilmeyen Toplam Ders Saati',
          '${detay.girilmeyenToplamDersSaati}',
        ),
      _buildInfoRow('Eğitimin Adı', detay.egitiminAdi),
      if (detay.egitiminAdiDiger.isNotEmpty)
        _buildInfoRow('Eğitimin Adı (Diğer)', detay.egitiminAdiDiger),
      _buildInfoRow('Eğitim Türü', detay.egitimTuru),
      _buildInfoRow('Online', detay.online ? 'Evet' : 'Hayır'),
      _buildInfoRow('Eğitim Şirketinin Adı', detay.sirketAdi),
      _buildInfoRow('Eğitimin Konusu', detay.egitimIcerigi),
      _buildInfoRow(
        'Web Sitesi',
        detay.webSitesi.isNotEmpty ? detay.webSitesi : '-',
      ),
      _buildInfoRow('Eğitimin Yeri', detay.egitimYeri),
      _buildInfoRow('Şehir', detay.sehir),
      _buildInfoRow('Adres', detay.adres, isLast: true),
    ];

    return rows;
  }

  String _formatNumber(num value) {
    final formatter =
        NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);
    return formatter.format(value).trim();
  }

  double _parseCurrency(String value) {
    // 10.800,00 -> 10800.00
    // Remove dots, replace comma with dot
    if (value.isEmpty) return 0;
    String cleaned = value.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<void> _saveKurumUcret(int talepId) async {
    final valueStr = _kurumUcretController.text;
    final value = _parseCurrency(valueStr);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: BrandedLoadingIndicator()),
      );

      final repo = ref.read(egitimIstekRepositoryProvider);
      final result = await repo.egitimIstekGuncelle(
        id: talepId,
        kurumunKarsiladigiUcret: value,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ücret başarıyla güncellendi'),
              backgroundColor: AppColors.success,
            ),
          );
          // Refresh the page data
          ref.invalidate(egitimIstekDetayProvider(widget.talepId));
        case Failure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        case Loading():
          break;
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  String _formatCurrency(num value, String? symbol) {
    final s = symbol ?? (value == 0 ? '' : 'TL');
    final formattedValue = _formatNumber(value);
    return '$formattedValue $s';
  }

  List<Widget> _buildUcretBilgisiRows(
    EgitimIstekDetayResponse detay,
    bool isAerbil,
  ) {
    final rows = <Widget>[];

    // Eğitim Ücreti
    rows.add(
      _buildInfoRow(
        'Eğitimin Ücreti',
        _formatCurrency(detay.egitimUcreti, detay.egitimParaBirimiSembol),
      ),
    );

    // Ulaşım Ücreti
    rows.add(
      _buildInfoRow(
        'Ulaşım Ücreti',
        _formatCurrency(detay.ulasimUcreti, detay.ulasimParaBirimiSembol),
      ),
    );

    // Konaklama Ücreti
    rows.add(
      _buildInfoRow(
        'Konaklama Ücreti',
        _formatCurrency(detay.konaklamaUcreti, detay.konaklamaParaBirimiSembol),
      ),
    );

    // Yemek Ücreti
    rows.add(
      _buildInfoRow(
        'Yemek Ücreti',
        _formatCurrency(detay.yemekUcreti, detay.yemekParaBirimiSembol),
      ),
    );

    // Kişi Başı Toplam Ücret (TL)
    rows.add(
      _buildInfoRow(
        'Kişi Başı Toplam Ücret',
        _formatCurrency(detay.toplamUcret, 'TL'),
      ),
    );

    // Genel Toplam Ücret (TL)
    rows.add(
      _buildInfoRow(
        'Genel Toplam Ücret',
        _formatCurrency(detay.genelToplamUcret, 'TL'),
      ),
    );

    // Ödeme Şekli
    if (detay.odemeSekli?.isNotEmpty == true) {
      rows.add(_buildInfoRow('Ödeme Şekli', detay.odemeSekli!));
    }

    // Peşin / Vadeli
    rows.add(_buildInfoRow('Peşin / Vadeli', detay.pesin ? 'Peşin' : 'Vadeli'));
    if (!detay.pesin && detay.vadeGun > 0) {
      rows.add(_buildInfoRow('Vade (Gün)', '${detay.vadeGun}'));
    }

    // IBAN
    if (detay.hesapNo.isNotEmpty) {
      rows.add(_buildInfoRow('IBAN', detay.hesapNo));
    }

    // Hesap Adı (Using unvan as best guess)
    if (detay.unvan.isNotEmpty) {
      rows.add(_buildInfoRow('Hesap Adı', detay.unvan));
    }

    // Diğer Ek Bilgiler
    if (detay.ekBilgi.isNotEmpty) {
      rows.add(_buildInfoRow('Diğer Ek Bilgiler', detay.ekBilgi));
    }

    // Kurumun Karşıladığı Ücret
    if (isAerbil) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kurumun Karşıladığı Ücret (TL)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _kurumUcretController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        suffixText: 'TL',
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => _saveKurumUcret(detay.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      if (detay.kurumunKarsiladigiUcret > 0) {
        rows.add(
          _buildInfoRow(
            'Kurumun Karşıladığı Ücret',
            _formatCurrency(detay.kurumunKarsiladigiUcret, 'TL'),
          ),
        );
      }
    }

    return rows;
  }

  List<Widget> _buildPaylasimRows(EgitimIstekDetayResponse detay) {
    return [
      _buildInfoRow(
        'Başlangıç Tarihi',
        _formatDateString(detay.paylasimBaslangicTarihi),
      ),
      _buildInfoRow(
        'Bitiş Tarihi',
        _formatDateString(detay.paylasimBitisTarihi),
      ),
      _buildInfoRow(
        'Başlangıç Saati',
        _formatTimeString(detay.paylasimBaslangicSaati),
      ),
      _buildInfoRow(
        'Bitiş Saati',
        _formatTimeString(detay.paylasimBitisSaati),
      ),
      _buildInfoRow('Nerede yapılacak', detay.paylasimYeri, isLast: true),
    ];
  }

  List<Widget> _buildDosyalarRows(EgitimIstekDetayResponse detay) {
    // As per request: Ekli dosya 1, Ekli dosya 2...
    // The model currently has only one file field: dosyaAdi.
    // Use it if present.
    final rows = <Widget>[];

    if (detay.dosyaAdi != null && detay.dosyaAdi!.isNotEmpty) {
      rows.add(_buildInfoRow('Ekli Dosya', detay.dosyaAdi!));
    } else {
      rows.add(
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Dosya bulunamadı',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    if (detay.dosyaAciklama != null && detay.dosyaAciklama!.isNotEmpty) {
      rows.add(
        _buildInfoRow('Dosya İçeriği', detay.dosyaAciklama!, isLast: true),
      );
    }

    return rows;
  }

  List<Widget> _buildPersonelListContent(
    List<EgitimIstekPersonelItem> personeller, {
    required String emptyText,
  }) {
    final widgets = <Widget>[];

    // Personelleri isim sırasında sırala
    final sortedPersoneller = List<EgitimIstekPersonelItem>.from(personeller)
      ..sort((a, b) => a.adiSoyadi.compareTo(b.adiSoyadi));

    for (int i = 0; i < sortedPersoneller.length; i++) {
      final personel = sortedPersoneller[i];
      final isLast = i == sortedPersoneller.length - 1;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İsim (bold)
              Text(
                personel.adiSoyadi.isNotEmpty ? personel.adiSoyadi : '-',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Görevi
              Text(
                personel.gorevi.isNotEmpty ? personel.gorevi : '-',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              // Görev yeri
              Text(
                personel.gorevYeri.isNotEmpty ? personel.gorevYeri : '-',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              // Çalıştığı Süre
              Text(
                'Çalıştığı Süre: ${personel.calistigiSure} yıl',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textTertiary,
                ),
              ),
              if (!isLast) ...[
                const SizedBox(height: 10),
                Container(height: 1, color: AppColors.border),
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
            style: const TextStyle(fontSize: 14, color: AppColors.textTertiary),
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
    // Determine label color based on label text
    final bool isTimeLabel = label.contains('Saati');
    final labelColor = isTimeLabel
        ? AppColors.primaryDark
        : AppColors.textSecondary;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (multiLine) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: labelColor,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
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
              child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
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
            style: TextStyle(color: AppColors.error, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildOnayFormAccordion() {
    const onayTipi = 'Eğitim İstek';
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Eğitim İstek',
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
                        // Listeyi yenile ve geri dön
                        ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Eğitim İstek',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: false,
                      geriDon: false,
                      aciklama: aciklama,
                    );

                    final result =
                        await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Eğitim İstek',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: false,
                      geriDon: true,
                      aciklama: aciklama,
                    );

                    final result =
                        await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Eğitim İstek',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: true,
                      beklet: false,
                      geriDon: false,
                      aciklama: aciklama,
                      atanacakPersonelId: selectedPersonel.personelId,
                    );

                    final result =
                        await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Görev atama başarıyla gerçekleşti'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Eğitim İstek',
                      onayKayitId: widget.talepId,
                      onaySureciId: onaySureciId,
                      onay: false,
                      beklet: true,
                      geriDon: false,
                      aciklama: aciklama,
                      bekletKademe: bekletKademe,
                    );

                    final result =
                        await repository.onayDurumuGuncelle(request);

                    if (!context.mounted) return;

                    switch (result) {
                      case Success():
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bekleme işlemi başarıyla gerçekleşti'),
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
                        _formatDateTime(tarih),
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
                    Expanded(
                      child: Text(
                        personelAdi,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
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
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(tarih),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textTertiary,
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
                      color: AppColors.textSecondary,
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
        title: 'Bildirim Alacaklar',
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
        title: 'Bildirim Alacaklar',
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
              child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
            ),
          ),
        ),
      ),
      error: (error, _) => _buildAccordion(
        icon: Icons.notifications_outlined,
        title: 'Bildirim Alacaklar',
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
            style: TextStyle(color: AppColors.error, fontSize: 15),
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
          child: Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personel.personelAdi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  personel.gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  personel.gorevYeri,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 10),
                  Container(height: 0.5, color: AppColors.border),
                ],
              ],
            ),
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
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return widgets;
  }

  static String _formatDateTime(DateTime dateTime) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final date =
        '${twoDigits(dateTime.day)}.${twoDigits(dateTime.month)}.${dateTime.year}';
    final time = '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
    return '$date $time';
  }
}

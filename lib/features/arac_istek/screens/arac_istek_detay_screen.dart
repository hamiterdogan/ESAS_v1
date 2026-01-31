import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/onay_form_content.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_detay_model.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_istek_detay_provider.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/core/models/result.dart';
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
  bool _onayFormExpanded = true;
  bool _bildirimGideceklerExpanded = true;
  bool _yolcuListesiExpanded = false;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(aracIstekDetayProvider(widget.talepId));
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
                'Araç İstek Detayı (${widget.talepId})',
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
                  context.go('/arac_istek');
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
            if ((int.tryParse(detay.yolcuSayisi) ?? 0) > 0)
              _buildYolcuListesiAccordion(detay),
            if ((int.tryParse(detay.yolcuSayisi) ?? 0) > 0)
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
                ref.invalidate(aracIstekDetayProvider(widget.talepId));
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

  List<Widget> _buildAracDetayRows(AracIstekDetayResponse detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    // Gidilecek Yer (alt satıra yazılacak)
    items.add(
      MapEntry(
        'Gidilecek Yer',
        detay.gidilecekYerler.isNotEmpty ? detay.gidilecekYerler : '-',
      ),
    );

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

    // Araç İstek Nedeni (alt satıra yazılacak) - varsa göster
    if (detay.istekNedeni.isNotEmpty) {
      String nedeniStr = _getIstekNedeniText(detay.istekNedeni);
      if (detay.istekNedeniDiger.isNotEmpty) {
        nedeniStr = '$nedeniStr - ${detay.istekNedeniDiger}';
      }
      items.add(MapEntry('Araç İstek Nedeni', nedeniStr));
    }

    // Açıklama (alt satıra yazılacak)
    if (detay.aciklama.isNotEmpty) {
      items.add(MapEntry('Açıklama', detay.aciklama));
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
        'Açıklama',
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

    // Personel Sayısı
    if (detay.personelSayisi > 0) {
      rows.add(
        _buildInfoRow(
          'Personel Sayısı',
          '${detay.personelSayisi}',
          isLast: false,
          multiLine: false,
        ),
      );
    }

    // Öğrenci Sayısı
    if (detay.ogrenciSayisi > 0) {
      rows.add(
        _buildInfoRow(
          'Öğrenci Sayısı',
          '${detay.ogrenciSayisi}',
          isLast: true,
          multiLine: false,
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Detay bilgisi bulunamadı',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
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
    bool showLeading = true,
    double childLeftPadding = 16,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: showLeading ? Icon(icon, color: AppColors.primary) : null,
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
              padding: EdgeInsets.fromLTRB(childLeftPadding, 12, 16, 12),
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
            // Alt satıra yazılacak format
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
            // İki nokta üst üsteden sonra boşluk bırakılıp yazılacak format
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
    const onayTipi = 'Araç İstek';
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
                      onayTipi: 'Araç İstek',
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
                      onayTipi: 'Araç İstek',
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
                      onayTipi: 'Araç İstek',
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
                          onayTipi: onayTipi,
                          onayKayitId: widget.talepId,
                          onaySureciId: onaySureciId,
                          onay: true, // Görev atamada onay true mu gönderilmeli? Genelde onaylanmış gibi işlem görüp bir sonrakine geçmesi veya sadece atama yapılması backend mantığına bağlı.
                          // Varsayım: Görev atama bir nevi onayla birlikte havale işlemidir. 
                          // Ancak Request modelde atanacakPersonelId varsa backend bunu görev atama olarak algılayacaktır.
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
                    final repository =
                        ref.read(talepYonetimRepositoryProvider);
                    final request = OnayDurumuGuncelleRequest(
                      onayTipi: 'Araç İstek',
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
        iconColor = AppColors.success;
      } else if (personel.onay == false) {
        icon = Icons.cancel;
        iconColor = AppColors.error;
      } else if (personel.geriGonderildi) {
        icon = Icons.replay;
        iconColor = AppColors.warning;
      } else {
        icon = Icons.hourglass_empty;
        iconColor = AppColors.warning; // Onay Bekliyor - turuncu renk
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
              Container(width: 2, height: 70, color: AppColors.textTertiary),
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
                    color: AppColors.textPrimary,
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
                    color: AppColors.textSecondary,
                  ),
                ),
                // Görevi
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
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
              Container(width: 2, height: 80, color: AppColors.textTertiary),
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
                          color: AppColors.textPrimary,
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
                    color: AppColors.textSecondary,
                  ),
                ),
                // Görevi
                Text(
                  gorevi,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textTertiary,
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
                      color: AppColors.textTertiary,
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
        showLeading: false,
        childLeftPadding: 30,
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
              child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
            ),
          ),
        ),
        showLeading: false,
        childLeftPadding: 30,
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
            style: TextStyle(color: AppColors.error, fontSize: 15),
          ),
        ),
        showLeading: false,
        childLeftPadding: 30,
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

  Widget _buildYolcuListesiAccordion(AracIstekDetayResponse detay) {
    return _buildAccordion(
      icon: Icons.people_outline,
      title: 'Toplam Yolcu Sayısı: ${detay.yolcuSayisi}',
      isExpanded: _yolcuListesiExpanded,
      onTap: () {
        setState(() {
          _yolcuListesiExpanded = !_yolcuListesiExpanded;
        });
      },
      child: _buildYolcuListesiContent(detay),
    );
  }

  Widget _buildYolcuListesiContent(AracIstekDetayResponse detay) {
    final yolcuList = detay.yolcuIsimleri;

    String normalizeForMatch(String value) {
      return value
          .toLowerCase()
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ı', 'i')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c')
          .trim();
    }

    // Personel ve Öğrenci kategorize et
    final personeller = <Map<String, String>>[];
    final ogrenciler = <Map<String, String>>[];

    for (final yolcu in yolcuList) {
      final kisiTipi = normalizeForMatch(yolcu['kisiTipi'] ?? '');
      final gorevi = normalizeForMatch(yolcu['gorevi'] ?? '');
      final gorevYeri = normalizeForMatch(yolcu['gorevYeri'] ?? '');

      final isOgrenci =
          kisiTipi.contains('ogrenci') ||
          kisiTipi.contains('student') ||
          gorevi.contains('ogrenci') ||
          gorevi.contains('student');
      final isPersonel =
          kisiTipi.contains('personel') || kisiTipi.contains('staff');

      if (isOgrenci) {
        ogrenciler.add(yolcu);
        continue;
      }

      // `kisiTipi` alanı gelmiyorsa (API'de yok / boş) yolcuları kaybetmeyelim:
      // görev/görev yeri bilgisi olanları varsayılan olarak personel kabul ediyoruz.
      if (isPersonel || gorevi.isNotEmpty || gorevYeri.isNotEmpty) {
        personeller.add(yolcu);
      } else {
        personeller.add(yolcu);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personel Başlığı
        if (personeller.isNotEmpty) ...[
          Text(
            'Personel (${personeller.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...personeller.asMap().entries.map((entry) {
            final index = entry.key;
            final personel = entry.value;
            final isLastPersonel = index == personeller.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    personel['ad'] ?? '-',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (personel['gorevYeri']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      personel['gorevYeri']!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (personel['gorevi']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      personel['gorevi']!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (!isLastPersonel) const SizedBox(height: 12),
              ],
            );
          }),
          if (ogrenciler.isNotEmpty) const SizedBox(height: 20),
        ],
        // Öğrenci Başlığı
        if (ogrenciler.isNotEmpty) ...[
          Text(
            'Öğrenci (${ogrenciler.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...ogrenciler.asMap().entries.map((entry) {
            final index = entry.key;
            final ogrenci = entry.value;
            final isLastOgrenci = index == ogrenciler.length - 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ogrenci['ad'] ?? '-',
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (ogrenci['gorevYeri']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ogrenci['gorevYeri']!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (ogrenci['gorevi']?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ogrenci['gorevi']!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
                if (!isLastOgrenci) const SizedBox(height: 12),
              ],
            );
          }),
        ],
        if (personeller.isEmpty && ogrenciler.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Yolcu listesi bulunamadı',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ),
          ),
      ],
    );
  }
}

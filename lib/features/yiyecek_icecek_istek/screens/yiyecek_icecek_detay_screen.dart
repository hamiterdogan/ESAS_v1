import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_istek_detay_model.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';

class YiyecekIcecekDetayScreen extends ConsumerStatefulWidget {
  final int talepId;

  const YiyecekIcecekDetayScreen({super.key, required this.talepId});

  @override
  ConsumerState<YiyecekIcecekDetayScreen> createState() =>
      _YiyecekIcecekDetayScreenState();
}

class _YiyecekIcecekDetayScreenState
    extends ConsumerState<YiyecekIcecekDetayScreen> {
  bool _personelBilgileriExpanded = true;
  bool _yiyecekIcecekDetaylariExpanded = true;
  bool _ikramBilgileriExpanded = true;
  bool _onaySureciExpanded = true;
  bool _bildirimGideceklerExpanded = true;

  @override
  Widget build(BuildContext context) {
    final detayAsync = ref.watch(yiyecekIstekDetayProvider(widget.talepId));
    final personelAsync = ref.watch(personelBilgiProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Yiyecek İçecek İstek Detayı (${widget.talepId})',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
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
    YiyecekIcecekIstekDetayRes detay,
    AsyncValue<PersonelBilgiResponse> personelAsync,
  ) {
    // API returns empty details for staff sometimes, fallback to logged in user info if matching or just show from detail
    // Actually the detail response has adSoyad, gorevYeri etc. Use those first.
    final adSoyad = detay.adSoyad.isNotEmpty ? detay.adSoyad : '-';
    final gorevYeri = detay.gorevYeri.isNotEmpty ? detay.gorevYeri : '-';
    final gorevi = detay.gorevi.isNotEmpty ? detay.gorevi : '-';

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
                  _buildInfoRow('Ad Soyad', adSoyad),
                  _buildInfoRow('Görev Yeri', gorevYeri),
                  _buildInfoRow('Görevi', gorevi, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAccordion(
              icon:
                  Icons.restaurant_menu, // Appropriate icon for Food & Beverage
              title: 'Yiyecek İçecek İstek Detayları',
              isExpanded: _yiyecekIcecekDetaylariExpanded,
              onTap: () {
                setState(() {
                  _yiyecekIcecekDetaylariExpanded =
                      !_yiyecekIcecekDetaylariExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildIstekDetayRows(detay),
              ),
            ),
            const SizedBox(height: 16),
            _buildIkramBilgileriAccordion(detay),
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
          color: AppColors.textOnPrimary.withValues(alpha: 0.05),
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
                ref.invalidate(yiyecekIstekDetayProvider(widget.talepId));
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

  List<Widget> _buildIstekDetayRows(YiyecekIcecekIstekDetayRes detay) {
    final rows = <Widget>[];
    final items = <MapEntry<String, String>>[];

    items.add(MapEntry('Etkinlik Adı', detay.etkinlikAdi));
    if (detay.etkinlikAdiDiger != null && detay.etkinlikAdiDiger!.isNotEmpty) {
      items.add(MapEntry('Etkinlik Adı (Diğer)', detay.etkinlikAdiDiger!));
    }

    // Format Date
    String tarihStr = detay.etkinlikTarihi;
    try {
      final date = DateTime.tryParse(detay.etkinlikTarihi);
      if (date != null) {
        tarihStr = DateFormat('dd.MM.yyyy').format(date);
      }
    } catch (_) {}
    items.add(MapEntry('Etkinlik Tarihi', tarihStr));

    items.add(MapEntry('Dönem', detay.donem));
    items.add(MapEntry('İkram Yeri', detay.ikramYeri));
    items.add(MapEntry('Alınan Yer', detay.alinanYer));
    items.add(MapEntry('Açıklama', detay.aciklama));

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      // Assumption: Description might be long
      final multiLine = item.key == 'Açıklama' || item.key == 'İkram Yeri';

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

  Widget _buildIkramBilgileriAccordion(YiyecekIcecekIstekDetayRes detay) {
    if (detay.ikramSatir.isEmpty) {
      return _buildAccordion(
        icon: Icons.local_cafe_outlined, // Icon for Treats
        title: 'İkram Bilgileri',
        isExpanded: _ikramBilgileriExpanded,
        onTap: () {
          setState(() {
            _ikramBilgileriExpanded = !_ikramBilgileriExpanded;
          });
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'İkram bilgisi bulunamadı',
            style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return _buildAccordion(
      icon: Icons.local_cafe_outlined,
      title: 'İkram Bilgileri',
      isExpanded: _ikramBilgileriExpanded,
      onTap: () {
        setState(() {
          _ikramBilgileriExpanded = !_ikramBilgileriExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: detay.ikramSatir.asMap().entries.map((entry) {
          final index = entry.key;
          final ikram = entry.value;
          final isLast = index == detay.ikramSatir.length - 1;

          // Construct Treat String
          final List<String> treats = [];
          if (ikram.cay) treats.add('Çay');
          if (ikram.kahve) treats.add('Kahve');
          if (ikram.mesrubat) treats.add('Meşrubat');
          if (ikram.kasarliSimit) treats.add('Kaşarlı Simit');
          if (ikram.kruvasan) treats.add('Kruvasan');
          if (ikram.kurabiye) treats.add('Kurabiye');
          if (ikram.ogleYemegi) treats.add('Öğle Yemeği');
          if (ikram.kokteyl) treats.add('Kokteyl');
          if (ikram.aksamYemegi) treats.add('Akşam Yemeği');
          if (ikram.kumanya) treats.add('Kumanya');
          if (ikram.diger && ikram.digerIkram != null) {
            treats.add('Diğer (${ikram.digerIkram})');
          }
          final treatStr = treats.join(', ');

          // Format Time
          String timeRange = '${ikram.baslangicSaati} - ${ikram.bitisSaati}';
          try {
            // Basic formatting if needed, assuming HH:mm:ss from API
            final start = ikram.baslangicSaati.substring(0, 5);
            final end = ikram.bitisSaati.substring(0, 5);
            timeRange = '$start - $end';
          } catch (_) {}

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saat Aralığı Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.gradientStart,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeRange,
                          style: const TextStyle(
                            color: AppColors.gradientStart,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // İkramlar
                  _buildInnerRow('İkramlar', treatStr),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),

                  // Katılımcı Sayıları (Grid like structure)
                  Row(
                    children: [
                      Expanded(
                        child: _buildCountColumn(
                          'Kurum İçi',
                          ikram.kiKatilimci,
                        ),
                      ),
                      Expanded(
                        child: _buildCountColumn(
                          'Kurum Dışı',
                          ikram.kdKatilimci,
                        ),
                      ),
                      Expanded(
                        child: _buildCountColumn(
                          'Toplam',
                          ikram.toplamKatilimci,
                          isTotal: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInnerRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCountColumn(String label, int count, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isTotal ? AppColors.gradientStart : AppColors.textTertiary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.gradientStart : AppColors.textPrimary,
          ),
        ),
      ],
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

  Widget _buildOnaySureciAccordion() {
    const onayTipi = 'Yiyecek İçecek İstek';
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
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  // Reuse logic from SatinAlma or similar screens.
  // Since we don't inherit from a common base or have a shared widget for this content yet (it's inside SatinAlma screen private methods),
  // we must duplicate the rendering logic for OnaySureci content here or move it to a shared widget.
  // For safety and speed matching the "exact same" request, I will duplicate the layout logic found in shared patterns.

  List<Widget> _buildOnaySureciContent(OnayDurumuResponse onayDurumu) {
    if (onayDurumu.onayVerecekler.isEmpty) {
      return [const Text('Onay süreci bulunmamaktadır.')];
    }

    return onayDurumu.onayVerecekler.asMap().entries.map((entry) {
      final index = entry.key;
      final p = entry.value;
      final isLast = index == onayDurumu.onayVerecekler.length - 1;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Line
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getOnayColor(p.onayDurumu).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getOnayColor(p.onayDurumu),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getOnayColor(p.onayDurumu),
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60, // approximate height
                      color: AppColors.textTertiary,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.personelAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${p.gorevYeri} - ${p.gorevi}',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getOnayColor(
                          p.onayDurumu,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.onayDurumu,
                        style: TextStyle(
                          color: _getOnayColor(p.onayDurumu),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (p.islemTarihi != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          DateFormat('dd.MM.yyyy HH:mm').format(p.islemTarihi!),
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (p.aciklama != null && p.aciklama!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Açıklama: ${p.aciklama}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }).toList();
  }

  Color _getOnayColor(String durum) {
    if (durum.toLowerCase().contains('onaylandı')) return AppColors.success;
    if (durum.toLowerCase().contains('red')) return AppColors.error;
    if (durum.toLowerCase().contains('bekliyor')) return AppColors.warning;
    return Colors.grey;
  }

  Widget _buildBildirimGideceklerAccordion() {
    const onayTipi = 'Yiyecek İçecek İstek';
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
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_outline, color: AppColors.primary),
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
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$gorevYeri - $gorevi',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 4),
      ],
    );
  }
}

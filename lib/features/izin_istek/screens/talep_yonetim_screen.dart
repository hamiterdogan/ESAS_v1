import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// İzin talep yönetim ekranı.
///
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// FAB gösterilmez çünkü izin isteği ayrı bir akıştan oluşturulur.
class TalepYonetimScreen extends ConsumerWidget {
  const TalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<Talep>(
      config: TalepYonetimConfig<Talep>(
        title: 'İzin İsteklerini Yönet',
        addRoute: '/izin_istek/ekle', // Kullanılmayacak
        showFab: false, // İzin için FAB yok
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
              return _IzinTalepListesi(
                taleplerAsync: ref.watch(devamEdenIsteklerimProvider),
                onRefresh: () {
                  ref.invalidate(devamEdenIsteklerimProvider);
                  return Future.value();
                },
                helper: helper,
              );
            },
        tamamlananBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
              return _IzinTalepListesi(
                taleplerAsync: ref.watch(tamamlananIsteklerimProvider),
                onRefresh: () {
                  ref.invalidate(tamamlananIsteklerimProvider);
                  return Future.value();
                },
                helper: helper,
              );
            },
      ),
    );
  }
}

class _IzinTalepListesi extends ConsumerWidget {
  const _IzinTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
  });

  final AsyncValue<TalepYonetimResponse> taleplerAsync;
  final Future<void> Function() onRefresh;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (talepResponse) {
        if (talepResponse.talepler.isEmpty) {
          return helper.buildEmptyState(onRefresh: onRefresh);
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: talepResponse.talepler.length,
            itemBuilder: (context, index) {
              final talep = talepResponse.talepler[index];
              return _IzinTalepCard(talep: talep);
            },
          ),
        );
      },
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: onRefresh),
    );
  }
}

class _IzinTalepCard extends StatelessWidget {
  const _IzinTalepCard({required this.talep});

  final Talep talep;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.textOnPrimary,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          talep.olusturanKisi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oluşturma Tarihi',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        _formatTarih(talep.olusturmaTarihi),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(talep.onayDurumu),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          talep.onayDurumu,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kayıt ID: ${talep.onayKayitId}',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textTertiary,
        ),
        onTap: () => _showTalepDetay(context, talep),
      ),
    );
  }

  void _showTalepDetay(BuildContext context, Talep talep) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _IzinTalepDetaySheet(talep: talep),
    );
  }

  String _formatTarih(String tarihi) {
    try {
      final date = DateTime.parse(tarihi);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return tarihi;
    }
  }

  Color _getStatusColor(String durum) {
    switch (durum.toLowerCase()) {
      case 'onaylandı':
        return AppColors.success;
      case 'reddedildi':
        return AppColors.error;
      case 'bekleniyor':
        return AppColors.warning;
      case 'taslak':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
}

/// İzin talep detay bottom sheet
class _IzinTalepDetaySheet extends StatelessWidget {
  const _IzinTalepDetaySheet({required this.talep});

  final Talep talep;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.textOnPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetaySection(
                      icon: Icons.person_outline,
                      title: 'Talep Eden Kişi',
                      items: [
                        _DetayItem(
                          label: 'Ad Soyad',
                          value: talep.olusturanKisi,
                        ),
                        if (talep.gorevYeri != null &&
                            talep.gorevYeri!.isNotEmpty)
                          _DetayItem(
                            label: 'Görev Yeri',
                            value: talep.gorevYeri!,
                          ),
                        if (talep.gorevi != null && talep.gorevi!.isNotEmpty)
                          _DetayItem(label: 'Görevi', value: talep.gorevi!),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetaySection(
                      icon: Icons.info_outline,
                      title: 'Talep Bilgileri',
                      items: [
                        _DetayItem(label: 'Talep Türü', value: talep.onayTipi),
                        _DetayItem(
                          label: 'Kayıt ID',
                          value: talep.onayKayitId.toString(),
                        ),
                        _DetayItem(
                          label: 'Oluşturma Tarihi',
                          value: _formatTarihDetay(talep.olusturmaTarihi),
                        ),
                        _DetayItem(
                          label: 'İşlem Tarihi',
                          value: _formatTarihDetay(talep.islemTarihi),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetaySection(
                      icon: Icons.check_circle_outline,
                      title: 'Onay Durumu',
                      items: [
                        _DetayItem(label: 'Durum', value: talep.onayDurumu),
                        if (talep.beklemeDurumu != null &&
                            talep.beklemeDurumu!.isNotEmpty)
                          _DetayItem(
                            label: 'Bekleme Durumu',
                            value: talep.beklemeDurumu!,
                          ),
                        _DetayItem(
                          label: 'Onay Sırası',
                          value: talep.onaySirasi.toString(),
                        ),
                        if (talep.cevapVeren != null &&
                            talep.cevapVeren!.isNotEmpty)
                          _DetayItem(
                            label: 'Cevap Veren',
                            value: talep.cevapVeren!,
                          ),
                        if (talep.bekletKademe != null &&
                            talep.bekletKademe!.isNotEmpty)
                          _DetayItem(
                            label: 'Beklet Kademe',
                            value: talep.bekletKademe!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetaySection(
                      icon: Icons.more_horiz,
                      title: 'Ek Bilgiler',
                      items: [
                        _DetayItem(
                          label: 'Arşiv',
                          value: talep.arsiv ? 'Evet' : 'Hayır',
                        ),
                        _DetayItem(
                          label: 'Geri Gönderildi',
                          value: talep.geriGonderildi ? 'Evet' : 'Hayır',
                        ),
                        if (talep.actionAdi != null &&
                            talep.actionAdi!.isNotEmpty)
                          _DetayItem(label: 'Aksiyon', value: talep.actionAdi!),
                        if (talep.toplamTutar > 0)
                          _DetayItem(
                            label: 'Toplam Tutar',
                            value: '${talep.toplamTutar} ₺',
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.textOnPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İzin Talep Detayı',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(talep.onayDurumu),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    talep.onayDurumu,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildDetaySection({
    required IconData icon,
    required String title,
    required List<_DetayItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gradientStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.gradientStart),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => _buildDetayItemWidget(item))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetayItemWidget(_DetayItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Text(
              item.value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTarihDetay(String tarihi) {
    try {
      final date = DateTime.parse(tarihi);
      final gun = date.day.toString().padLeft(2, '0');
      final ay = date.month.toString().padLeft(2, '0');
      final yil = date.year;
      final saat = date.hour.toString().padLeft(2, '0');
      final dakika = date.minute.toString().padLeft(2, '0');
      return '$gun.$ay.$yil $saat:$dakika';
    } catch (e) {
      return tarihi;
    }
  }

  Color _getStatusColor(String durum) {
    switch (durum.toLowerCase()) {
      case 'onaylandı':
        return AppColors.success;
      case 'reddedildi':
        return AppColors.error;
      case 'bekleniyor':
        return AppColors.warning;
      case 'taslak':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }
}

class _DetayItem {
  const _DetayItem({required this.label, required this.value});
  final String label;
  final String value;
}

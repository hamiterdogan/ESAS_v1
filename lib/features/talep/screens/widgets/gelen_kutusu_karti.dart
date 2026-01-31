import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/common/widgets/swipeable_detay_wrapper.dart';

/// Gelen Kutusu kartı widget'ı - Gelen Kutusu listesindeki kartlar
class GelenKutusuKarti extends ConsumerWidget {
  final Talep talep;
  final String? displayOnayTipi;
  final List<Talep>? talepList;
  final int? indexInList;

  const GelenKutusuKarti({
    super.key,
    required this.talep,
    this.displayOnayTipi,
    this.talepList,
    this.indexInList,
  });

  String _formatTarih(String tarihStr) {
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Color _getOnayDurumuRengi(String durum) {
    final lower = durum.toLowerCase();
    if (lower.contains('onay bekliyor') ||
        lower.contains('beklemede') ||
        lower.contains('bekliyor') ||
        lower.contains('devam')) {
      return AppColors.warning;
    }
    if (lower.contains('tamam')) {
      return AppColors.success;
    }
    switch (lower) {
      case 'onaylandı':
        return AppColors.success;
      case 'reddedildi':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getOnayDurumuIkonu(String durum) {
    final lower = durum.toLowerCase();
    if (lower.contains('onay bekliyor') ||
        lower.contains('beklemede') ||
        lower.contains('bekliyor') ||
        lower.contains('devam')) {
      return Icons.schedule;
    }
    if (lower.contains('tamam')) {
      return Icons.check_circle;
    }
    switch (lower) {
      case 'onaylandı':
        return Icons.check_circle;
      case 'reddedildi':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getDisplayDurum(String durum) {
    return durum;
  }

  /// Satın Alma kartları için toplamTutar'a göre renk döndürür
  /// 0-10.000 TL: Açık yeşil
  /// 10.001-50.000 TL: Turuncu
  /// 50.001+ TL: Açık kırmızı
  Color _getSatinAlmaCardColor(BuildContext context) {
    final toplamTutar = talep.toplamTutar;

    if (toplamTutar <= 10000) {
      // Açık yeşil
      return const Color(0xFFE8F5E9); // Light Green 50
    } else if (toplamTutar <= 50000) {
      // Turuncu
      return const Color(0xFFFFF3E0); // Orange 50
    } else {
      // Açık kırmızı
      return const Color(0xFFFFEBEE); // Red 50
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onayTipiText = displayOnayTipi ?? talep.onayTipi;

    // Check if unread (API sends boolean but model converts to String "false"/"true")
    final isUnread = talep.okundu?.toLowerCase() == 'false';

    // Satın Alma kartları için toplam tutar rengi
    final isSatinAlma =
        talep.onayTipi.toLowerCase().contains('satın') ||
        talep.onayTipi.toLowerCase().contains('satin');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            AppColors.textOnPrimary,
            0.65,
          ) ??
          AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread
            ? BorderSide(
                color: AppColors.primaryDark.withValues(alpha: 0.2),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          // Eğer okunmamışsa, okundu olarak işaretle
          if (isUnread) {
            try {
              final repository = ref.read(talepYonetimRepositoryProvider);
              await repository.okunduIsaretle(
                onayKayitId: talep.onayKayitId,
                onayTipi: talep.onayTipi,
              );
              // Hata olsa bile sessizce devam et, kullanıcı akışını bozma
            } catch (e) {
              debugPrint('Okundu işaretleme hatası: $e');
            }
          }

          if (!context.mounted) return;

          // Eğer talepList ve indexInList varsa SwipeableDetayWrapper kullan
          if (talepList != null && indexInList != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SwipeableDetayWrapper(
                  talepList: talepList!,
                  initialIndex: indexInList!,
                  isGelenKutusu: true,
                ),
              ),
            );
          }

          // Detay sayfasından dönüldüğünde listeyi ve badge sayısını yenile
          // Sadece okunmamış bir talebe tıklandıysa yenileme yap
          if (isUnread) {
            ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
            ref.invalidate(okunmayanTalepSayisiProvider);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Süreç No ve Durum
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unread Indicator - Clean Dot
                  if (isUnread) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Süreç No: ',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isUnread
                                ? Colors.black
                                : Colors.black, // Color reverted to standard
                          ),
                        ),
                        Text(
                          '${talep.onayKayitId}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isUnread
                                ? AppColors.primary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Durum rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    constraints: const BoxConstraints(maxWidth: 110),
                    decoration: BoxDecoration(
                      color: _getOnayDurumuRengi(
                        talep.onayDurumu,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getOnayDurumuIkonu(talep.onayDurumu),
                          size: 14,
                          color: _getOnayDurumuRengi(talep.onayDurumu),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _getDisplayDurum(talep.onayDurumu),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _getOnayDurumuRengi(talep.onayDurumu),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Talep Türü
              Text(
                onayTipiText,
                style: TextStyle(
                  fontSize: isUnread ? 18 : 17,
                  color: isUnread ? AppColors.primary : Colors.black,
                  fontWeight: isUnread
                      ? FontWeight.w700
                      : FontWeight.normal, // Increased weight for unread
                ),
              ),
              const SizedBox(height: 4),
              // Talep Eden
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Talep Eden: ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: talep.olusturanKisi,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal, // Bold if unread
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Görev Yeri ve Görevi
              Text(
                '${talep.gorevYeri ?? '-'} - ${talep.gorevi ?? '-'}',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              // Satın Alma için Toplam Tutar
              if (isSatinAlma && talep.toplamTutar > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getSatinAlmaCardColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Toplam: ${NumberFormat('#,##0.00', 'tr_TR').format(talep.toplamTutar)} ₺',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Tarih
              Text(
                _formatTarih(talep.olusturmaTarihi),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

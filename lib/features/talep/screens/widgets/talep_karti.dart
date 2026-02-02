import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/common/widgets/swipeable_detay_wrapper.dart';

/// Talep kartı widget'ı - İsteklerim listesindeki kartlar
class TalepKarti extends StatelessWidget {
  final Talep talep;
  final String? displayOnayTipi;
  final List<Talep>? talepList;
  final int? indexInList;
  final ValueChanged<int>? onReturnIndex;

  // PERFORMANCE: Pre-computed değerler - build'da hesaplama yerine constructor'da hesaplanıyor
  late final Color _statusColor;
  late final IconData _statusIcon;
  late final String _formattedDate;

  TalepKarti({
    super.key,
    required this.talep,
    this.displayOnayTipi,
    this.talepList,
    this.indexInList,
    this.onReturnIndex,
  }) {
    // Pre-compute status color, icon ve formatted date
    _statusColor = _computeOnayDurumuRengi(talep.onayDurumu);
    _statusIcon = _computeOnayDurumuIkonu(talep.onayDurumu);
    _formattedDate = _formatTarih(talep.olusturmaTarihi);
  }

  String _formatTarih(String tarihStr) {
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Color _computeOnayDurumuRengi(String durum) {
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

  IconData _computeOnayDurumuIkonu(String durum) {
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

  String _getOnayDurumuText(String durum) {
    return durum;
  }

  @override
  Widget build(BuildContext context) {
    final onayTipiText = displayOnayTipi ?? talep.onayTipi;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      // PERFORMANCE: Sabit renk kullan, withValues her build'da yeni Color nesnesi oluşturur
      shadowColor: const Color(
        0x1F000000,
      ), // Colors.black.withValues(alpha: 0.12) equivalent
      color: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          if (!context.mounted) return;

          // Eğer talepList ve indexInList varsa SwipeableDetayWrapper kullan
          if (talepList != null && indexInList != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SwipeableDetayWrapper(
                  talepList: talepList!,
                  initialIndex: indexInList!,
                  isGelenKutusu: false,
                ),
              ),
            );

            if (result is int) {
              onReturnIndex?.call(result);
            }
            return;
          }

          // Fallback: Eski davranış (talepList yoksa) - SwipeableDetayWrapper kullan
          // Bu durumda talepList None olduğu için normal şekilde açamayız
          // Ancak belki talepList her zaman sağlanmıştır
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          // PERFORMANCE: IntrinsicHeight kaldırıldı - double render pass yerine
          // sabit boyutlu Container kullanılarak performans artırıldı
          child: SizedBox(
            height:
                88, // Sabit yükseklik - IntrinsicHeight'ın double render'ını önler
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol taraf - Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Süreç No
                      Row(
                        children: [
                          Text(
                            'Süreç No: ',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${talep.onayKayitId}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      // Talep Türü
                      Text(
                        onayTipiText,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Tarih - PERFORMANCE: pre-formatted değer
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sağ taraf - Durum ve Chevron
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Durum rozeti - PERFORMANCE: pre-computed renk/icon kullanıyor
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      constraints: const BoxConstraints(maxWidth: 110),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, size: 14, color: _statusColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _getOnayDurumuText(talep.onayDurumu),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron - dikey merkezde
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 28,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/common/widgets/swipeable_detay_wrapper.dart';

/// Gelen Kutusu kartı widget'ı - Gelen Kutusu listesindeki kartlar
class GelenKutusuKarti extends StatelessWidget {
  final Talep talep;
  final String? displayOnayTipi;
  final List<Talep>? talepList;
  final int? indexInList;
  final ValueChanged<int>? onReturnIndex;

  // PERFORMANCE: Pre-computed değerler - build'da hesaplama yerine constructor'da hesaplanıyor
  late final bool _isUnread;
  late final bool _isSatinAlma;
  late final Color _statusColor;
  late final IconData _statusIcon;
  late final String _formattedDate;
  late final Color _satinAlmaCardColor;

  GelenKutusuKarti({
    super.key,
    required this.talep,
    this.displayOnayTipi,
    this.talepList,
    this.indexInList,
    this.onReturnIndex,
  }) {
    // Pre-compute all display values
    _isUnread = talep.okundu?.toLowerCase() == 'false';
    _isSatinAlma =
        talep.onayTipi.toLowerCase().contains('satın') ||
        talep.onayTipi.toLowerCase().contains('satin');
    _statusColor = _computeOnayDurumuRengi(talep.onayDurumu);
    _statusIcon = _computeOnayDurumuIkonu(talep.onayDurumu);
    _formattedDate = _formatTarih(talep.olusturmaTarihi);
    _satinAlmaCardColor = _computeSatinAlmaCardColor();
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

  String _getDisplayDurum(String durum) {
    return durum;
  }

  /// Satın Alma kartları için toplamTutar'a göre renk döndürür
  /// 0-10.000 TL: Açık yeşil
  /// 10.001-50.000 TL: Turuncu
  /// 50.001+ TL: Açık kırmızı
  Color _computeSatinAlmaCardColor() {
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
  Widget build(BuildContext context) {
    final onayTipiText = displayOnayTipi ?? talep.onayTipi;

    // PERFORMANCE: Consumer sadece okundu işaretleme için kullanılıyor
    return Consumer(
      builder: (context, ref, child) {
        // Child hiç rebuild olmayacak, sadece onTap'te ref'e erişmek için Consumer kullanılıyor
        return child!;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        // PERFORMANCE: Sabit renk kullan, withValues her build'da yeni Color nesnesi oluşturur
        shadowColor: const Color(
          0x1F000000,
        ), // Colors.black.withValues(alpha: 0.12)
        color: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _isUnread
              ? const BorderSide(
                  color: Color(
                    0x33004D40,
                  ), // AppColors.primaryDark.withValues(alpha: 0.2)
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        child: Builder(
          // Builder widget için ref erişimi - okundu işaretleme
          builder: (context) {
            return InkWell(
              onTap: () async {
                // Safe ref access: Capture container before async gaps
                final container = ProviderScope.containerOf(context);

                // Eğer okunmamışsa, okundu olarak işaretle
                if (_isUnread) {
                  try {
                    final repository = container.read(
                      talepYonetimRepositoryProvider,
                    );
                    await repository.okunduIsaretle(
                      onayKayitId: talep.onayKayitId,
                      onayTipi: talep.onayTipi,
                    );
                    // Hata olsa bile sessizce devam et
                  } catch (e) {
                    debugPrint('Okundu işaretleme hatası: $e');
                  }
                }

                if (!context.mounted) return;

                // Eğer talepList ve indexInList varsa SwipeableDetayWrapper kullan
                if (talepList != null && indexInList != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => SwipeableDetayWrapper(
                        talepList: talepList!,
                        initialIndex: indexInList!,
                        isGelenKutusu: true,
                      ),
                    ),
                  );

                  if (result is int) {
                    onReturnIndex?.call(result);
                  }
                }

                // Detay sayfasından dönüldüğünde listeyi ve badge sayısını yenile
                // Sadece okunmamış bir talebe tıklandıysa yenileme yap
                if (_isUnread) {
                  // Use captured container instead of context
                  container
                      .read(devamEdenGelenKutusuProvider.notifier)
                      .refresh();
                  container
                      .read(tamamlananGelenKutusuProvider.notifier)
                      .refresh();
                  container.invalidate(okunmayanTalepSayisiProvider);
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
                        // Unread Indicator - Clean Dot - PERFORMANCE: pre-computed _isUnread
                        if (_isUnread) ...[
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
                              const Text(
                                'Süreç No: ',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${talep.onayKayitId}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _isUnread
                                      ? AppColors.primary
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Durum rozeti - PERFORMANCE: pre-computed color/icon
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
                                    _getDisplayDurum(talep.onayDurumu),
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Talep Türü - PERFORMANCE: pre-computed _isUnread kullanılıyor
                    Text(
                      onayTipiText,
                      style: TextStyle(
                        fontSize: _isUnread ? 18 : 17,
                        color: _isUnread ? AppColors.primary : Colors.black,
                        fontWeight: _isUnread
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Talep Eden
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Talep Eden: ',
                            style: TextStyle(
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
                              fontWeight: _isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                    // Satın Alma için Toplam Tutar - PERFORMANCE: pre-computed renk
                    if (_isSatinAlma && talep.toplamTutar > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _satinAlmaCardColor,
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
            );
          },
        ),
      ),
    );
  }
}

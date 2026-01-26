import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_detay_screen.dart';
import 'package:esas_v1/features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_detay_screen.dart';

/// Talep kartı widget'ı - İsteklerim listesindeki kartlar
class TalepKarti extends StatelessWidget {
  final Talep talep;
  final String? displayOnayTipi;

  const TalepKarti({super.key, required this.talep, this.displayOnayTipi});

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
    final lower = durum.toLowerCase();
    if (lower.contains('onay bekliyor') ||
        lower.contains('beklemede') ||
        lower.contains('bekliyor')) {
      return 'Devam Ediyor';
    }
    return durum;
  }

  @override
  Widget build(BuildContext context) {
    final onayTipiText = displayOnayTipi ?? talep.onayTipi;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            AppColors.textOnPrimary,
            0.65,
          ) ??
          AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // İzin İstek tipleri için detay sayfasına git
          if (talep.onayTipi.toLowerCase().contains('izin')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => IzinIstekDetayScreen(
                  talepId: talep.onayKayitId,
                  onayTipi: talep.onayTipi,
                ),
              ),
            );
          }
          // Araç İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('araç') ||
              talep.onayTipi.toLowerCase().contains('arac')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    AracIstekDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          }
          // Dokümantasyon İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('dok')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DokumantasyonIstekDetayScreen(
                  talepId: talep.onayKayitId,
                  onayTipi: talep.onayTipi,
                ),
              ),
            );
          }
          // Satın Alma İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('satın') ||
              talep.onayTipi.toLowerCase().contains('satin')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    SatinAlmaDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          }
          // Teknik Destek / Bilgi Teknolojileri İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('teknik destek')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    TeknikDestekDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          }
          // Sarf Malzeme İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('sarf malzeme')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    SarfMalzemeDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          }
          // Yiyecek İçecek İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('yiyecek') ||
              talep.onayTipi.toLowerCase().contains('içecek') ||
              talep.onayTipi.toLowerCase().contains('icecek')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) =>
                    YiyecekIcecekDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          }
          // Diğer süreç türleri için şimdilik tepki verme
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sol taraf - Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 4),
                      // Talep Türü
                      Text(
                        onayTipiText,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
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
                // Sağ taraf - Durum ve Chevron
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                                _getOnayDurumuText(talep.onayDurumu),
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
                    // Chevron (dikey ortalaması biraz daha aşağıda kalabilir, IntrinsicHeight ve Spacer ile yönetiyoruz)
                    // Ortada olması için Spacer kullanılabilir ancak üst tarafın hizası önemli.
                    // IntrinsicHeight olduğu için, içerik kadar yer kaplamaz, en yüksek kadar kaplar.
                    // Üstte durum var, altta bir şey yoksa sadece durum olur. SpaceAround işe yaramaz.
                    // Ortalamadan ziyade en alta koysak? Hayır son karakterler hizalı demiş.
                    // "yazıların son karakterleri dikeyde chevron ile aynı hizada olsun" -> Vertical alignment?
                    // "Süreç No: X yazısı ile aynı hizada ama sağa dayalı olsun" -> Horizontal alignment with first row.
                    // Durum widget'ı zaten ilk row hizasında.
                    // Chevron dikeyde ortada mı yoksa altta mı? "yazıların son karakterleri dikeyde chevron ile aynı hizada olsun"
                    // Bu ifade biraz karışık. "Yazıların son karakterleri" -> Durum yazısı?
                    // "dikeyde chevron ile aynı hizada olsun" -> Muhtemelen sağa dayalı demek istiyor (Alignment.centerRight).
                    // Yani Durum ve Chevron sağ kenara dayalı olacak (CrossAxisAlignment.end).
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 28,
                    ),
                    // Chevron'u biraz yukarı itmek gerekebilir mi? Tam orta için Spacer yeterli.
                    // Üstteki boşluk kadar alttan boşluk bırakmak gerekebilir, ama Spacer bunu dinamik yapar.
                    const Spacer(),
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

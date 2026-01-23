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

/// Gelen Kutusu kartı widget'ı - Gelen Kutusu listesindeki kartlar
class GelenKutusuKarti extends StatelessWidget {
  final Talep talep;
  final String? displayOnayTipi;

  const GelenKutusuKarti({
    super.key,
    required this.talep,
    this.displayOnayTipi,
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
    switch (lower) {
      case 'onaylandı':
        return AppColors.success;
      case 'reddedildi':
        return AppColors.error;
      case 'tamamlandı':
        return AppColors.success;
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
      case 'tamamlandı':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _getDisplayDurum(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return 'Devam Ediyor';
      case 'onaylandı':
        return 'Onaylandı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'tamamlandı':
        return 'Tamamlandı';
      default:
        return durum;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onayTipiText = displayOnayTipi ?? talep.onayTipi;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır - Süreç No ve Durum
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
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
                  ),
                  // Durum rozeti
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
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
                        FittedBox(
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Talep Türü
              Text(
                onayTipiText,
                style: const TextStyle(fontSize: 17, color: Colors.black),
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
                      style: const TextStyle(fontSize: 14, color: Colors.black),
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

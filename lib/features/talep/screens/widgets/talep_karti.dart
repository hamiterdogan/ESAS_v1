import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart';

/// Talep kartı widget'ı - İsteklerim listesindeki kartlar
class TalepKarti extends StatelessWidget {
  final Talep talep;

  const TalepKarti({super.key, required this.talep});

  String _formatTarih(String tarihStr) {
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Color _getOnayDurumuRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Colors.orange;
      case 'onaylandı':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOnayDurumuIkonu(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Icons.schedule;
      case 'onaylandı':
        return Icons.check_circle;
      case 'reddedildi':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            Colors.white,
            0.65,
          ) ??
          Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // İzin İstek tipleri için detay sayfasına git
          if (talep.onayTipi.toLowerCase().contains('izin')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => IzinIstekDetayScreen(
                  talepId: talep.onayKayitID,
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
                    AracIstekDetayScreen(talepId: talep.onayKayitID),
              ),
            );
          }
          // Dokümantasyon İstek tipleri için detay sayfasına git
          else if (talep.onayTipi.toLowerCase().contains('dok')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => DokumantasyonIstekDetayScreen(
                  talepId: talep.onayKayitID,
                  onayTipi: talep.onayTipi,
                ),
              ),
            );
          }
          // Diğer süreç türleri için şimdilik tepki verme
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${talep.onayKayitID}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gradientStart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Talep Türü
                    Text(
                      talep.onayTipi,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gradientStart,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tarih ve Onay Durumu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTarih(talep.olusturmaTarihi),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
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
                                size: 16,
                                color: _getOnayDurumuRengi(talep.onayDurumu),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                talep.onayDurumu,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getOnayDurumuRengi(talep.onayDurumu),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Sağ taraf - Büyüktür ikonu
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/common/widgets/swipeable_detay_wrapper.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart'; // Result tipi için import
import 'package:go_router/go_router.dart';

/// Gelen Kutusu kartı widget'ı - Gelen Kutusu listesindeki kartlar
class GelenKutusuKarti extends ConsumerStatefulWidget {
  final Talep talep;
  final String? displayOnayTipi;
  final bool isTamamlanan;
  final List<Talep>? talepList;
  final int? indexInList;
  final Function(int)? onReturnIndex;

  const GelenKutusuKarti({
    super.key,
    required this.talep,
    this.displayOnayTipi,
    this.talepList,
    this.indexInList,
    this.onReturnIndex,
    this.isTamamlanan = false,
  });

  @override
  ConsumerState<GelenKutusuKarti> createState() => _GelenKutusuKartiState();
}

class _GelenKutusuKartiState extends ConsumerState<GelenKutusuKarti> {
  // Computed values
  late bool _isUnread;
  late bool _isSatinAlma;
  late Color _statusColor;
  late IconData _statusIcon;
  late String _formattedDate;
  late Color _satinAlmaCardColor;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _computeValues();
  }

  @override
  void didUpdateWidget(GelenKutusuKarti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.talep != widget.talep) {
      _computeValues();
    }
  }

  void _computeValues() {
    _isUnread = widget.talep.okundu?.toLowerCase() == 'false';
    _isSatinAlma =
        widget.talep.onayTipi.toLowerCase().contains('satın') ||
        widget.talep.onayTipi.toLowerCase().contains('satin');
    _statusColor = _computeOnayDurumuRengi(widget.talep.onayDurumu);
    _statusIcon = _computeOnayDurumuIkonu(widget.talep.onayDurumu);
    _formattedDate = _formatTarih(widget.talep.olusturmaTarihi);
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
  Color _computeSatinAlmaCardColor() {
    final toplamTutar = widget.talep.toplamTutar;

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

  Future<void> _handleQuickAction(bool isApprove) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApprove ? 'Onayla' : 'Reddet'),
        content: Text(
          isApprove
              ? 'Bu talebi onaylamak istediğinize emin misiniz?'
              : 'Bu talebi reddetmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isApprove ? 'Onayla' : 'Reddet',
              style: TextStyle(
                color: isApprove ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(talepYonetimRepositoryProvider);
      
      // OnayDurumuGuncelleRequest oluştur
      // Not: Beklet kademe vs. şuan varsayılan null/false
      final request = OnayDurumuGuncelleRequest(
        onayTipi: widget.talep.onayTipi,
        onayKayitId: widget.talep.onayKayitId,
        onaySureciId: widget.talep.onaySureciId,
        onay: isApprove, // true: Onay, false: Red
        beklet: false,
        geriDon: false,
        aciklama: '', // Hızlı onayda açıklama boş gidiyor
      );

      final result = await repository.onayDurumuGuncelle(request);

      if (!mounted) return;

      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isApprove ? 'Talep başarıyla onaylandı.' : 'Talep reddedildi.',
              ),
              backgroundColor: isApprove ? AppColors.success : AppColors.error,
            ),
          );
          // Listeyi yenile
          ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
          ref.read(tamamlananGelenKutusuProvider.notifier).refresh();
          ref.invalidate(okunmayanTalepSayisiProvider);
          break;
        case Failure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İşlem başarısız: $message'),
              backgroundColor: AppColors.error,
            ),
          );
          break;
        case Loading():
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _shouldShowQuickActions() {
    final currentUser = ref.watch(currentKullaniciAdiProvider);
    
    // 1. Kullanıcı CEYUBOGLU mu?
    if (currentUser != 'CEYUBOGLU') return false;

    // 2. Tamamlanan tabında ise gösterme
    if (widget.isTamamlanan) return false;

    // 3. Onay bekleyen bir durum mu? (Basitçe 'Onay Bekliyor' içerenler)
    final durumLower = widget.talep.onayDurumu.toLowerCase();
    if (!durumLower.contains('onay bekliyor') && !durumLower.contains('devam eden')) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final onayTipiText = widget.displayOnayTipi ?? widget.talep.onayTipi;
    final showActions = _shouldShowQuickActions();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: const Color(0x1F000000),
      color: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isUnread
            ? const BorderSide(
                color: Color(0x33004D40),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          // Eğer okunmamışsa, okundu olarak işaretle
          if (_isUnread) {
            try {
              final repository = ref.read(talepYonetimRepositoryProvider);
              await repository.okunduIsaretle(
                onayKayitId: widget.talep.onayKayitId,
                onayTipi: widget.talep.onayTipi,
              );
            } catch (e) {
              if (kDebugMode) debugPrint('Okundu işaretleme hatası: $e');
            }
          }

          if (!context.mounted) return;

          // Detay sayfasına git
          if (widget.talepList != null && widget.indexInList != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => SwipeableDetayWrapper(
                  talepList: widget.talepList!,
                  initialIndex: widget.indexInList!,
                  isGelenKutusu: true,
                  isTamamlanan: widget.isTamamlanan,
                ),
              ),
            );

            if (result is int) {
              widget.onReturnIndex?.call(result);
            }
          }

          // Dönüşte refresh
          if (_isUnread) {
            ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
            ref.read(tamamlananGelenKutusuProvider.notifier).refresh();
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
                          '${widget.talep.onayKayitId}',
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
                              _getDisplayDurum(widget.talep.onayDurumu),
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
              // Talep Türü
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
                      text: widget.talep.olusturanKisi,
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
                '${widget.talep.gorevYeri ?? '-'} - ${widget.talep.gorevi ?? '-'}',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              if (_isSatinAlma && widget.talep.toplamTutar > 0) ...[
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
                    'Toplam: ${NumberFormat('#,##0.00', 'tr_TR').format(widget.talep.toplamTutar)} ₺',
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
                _formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTertiary,
                ),
              ),
              
              // Hızlı Aksiyon Butonları (Sadece CEYUBOGLU & Devam Eden)
              if (showActions) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(
                    child: SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleQuickAction(true), // Onayla
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Onayla',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleQuickAction(false), // Reddet
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Reddet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

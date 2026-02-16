import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bildirim/models/notification_model.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';

/// Bildirimler ekranı - tüm kullanıcı bildirimlerini listeler
class BildirimScreen extends ConsumerStatefulWidget {
  const BildirimScreen({super.key});

  @override
  ConsumerState<BildirimScreen> createState() => _BildirimScreenState();
}

class _BildirimScreenState extends ConsumerState<BildirimScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(bildirimListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bildirimState = ref.watch(bildirimListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (bildirimState.bildirimler.any((b) => !b.okundu))
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.textOnPrimary),
              tooltip: 'Tümünü okundu işaretle',
              onPressed: () async {
                await ref
                    .read(bildirimListProvider.notifier)
                    .tumunuOkunduIsaretle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm bildirimler okundu olarak işaretlendi'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: bildirimState.isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : bildirimState.bildirimler.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(bildirimListProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    itemCount: bildirimState.bildirimler.length +
                        (bildirimState.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= bildirimState.bildirimler.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildBildirimCard(
                          bildirimState.bildirimler[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildiriminiz yok',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBildirimCard(BildirimModel bildirim) {
    final timeAgo = _formatTimeAgo(bildirim.olusturmaTarihi);
    final icon = _getIconForType(bildirim.bildirimTipi);
    final iconColor = _getColorForType(bildirim.aksiyonTipi);

    return GestureDetector(
      onTap: () => _onBildirimTap(bildirim),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bildirim.okundu
              ? Colors.white
              : AppColors.primaryLight.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bildirim.okundu
                ? AppColors.borderLight
                : AppColors.primaryLight.withValues(alpha: 0.3),
            width: bildirim.okundu ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İkon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bildirim.baslik,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: bildirim.okundu
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Okunmadı göstergesi
                            if (!bildirim.okundu)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bildirim.mesaj,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: bildirim.okundu
                                ? FontWeight.w400
                                : FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Zaman ve gönderen
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 13,
                              color: AppColors.textSecondary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withValues(alpha: 0.6),
                              ),
                            ),
                            if (bildirim.gonderenAd != null) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: AppColors.textSecondary.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  bildirim.gonderenAd!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Aksiyon butonları (onay_bekliyor durumunda)
              if (bildirim.isActionable) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAksiyon(bildirim, 'reddet'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reddet'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAksiyon(bildirim, 'onayla'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Onayla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  /// Bildirime tıklanınca
  void _onBildirimTap(BildirimModel bildirim) {
    // Okundu olarak işaretle
    if (!bildirim.okundu) {
      ref.read(bildirimListProvider.notifier).bildirimOkunduIsaretle(bildirim.id);
    }

    // Deep link varsa git
    final route = bildirim.deepLinkRoute;
    if (route != null) {
      context.push(route);
    }
  }

  /// Onay/Red aksiyonu
  Future<void> _handleAksiyon(BildirimModel bildirim, String aksiyon) async {
    if (bildirim.onayKayitId == null || bildirim.onayTipi == null) return;

    // Onay diyalogu göster
    final confirmed = await _showConfirmationDialog(aksiyon);
    if (confirmed != true) return;

    final repo = ref.read(notificationRepositoryProvider);
    final result = await repo.bildirimAksiyon(
      bildirimId: bildirim.id,
      onayKayitId: bildirim.onayKayitId!,
      onayTipi: bildirim.onayTipi!,
      aksiyon: aksiyon,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data.mesaj ?? (aksiyon == 'onayla'
                ? 'Talep onaylandı'
                : 'Talep reddedildi')),
            backgroundColor:
                aksiyon == 'onayla' ? AppColors.success : AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
        // Listeyi yenile
        ref.read(bildirimListProvider.notifier).refresh();
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $message'),
            backgroundColor: AppColors.error,
          ),
        );
      case Loading():
        break;
    }
  }

  /// Onay/Red doğrulama dialogu
  Future<bool?> _showConfirmationDialog(String aksiyon) async {
    final isApproval = aksiyon == 'onayla';
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 60),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApproval ? Icons.check_circle : Icons.cancel,
                  color: isApproval ? AppColors.success : AppColors.error,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text(
                  isApproval
                      ? 'Bu talebi onaylamak istediğinize emin misiniz?'
                      : 'Bu talebi reddetmek istediğinize emin misiniz?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: AppColors.primaryDark,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isApproval ? AppColors.success : AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isApproval ? 'Onayla' : 'Reddet',
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bildirim tipi ikonu
  IconData _getIconForType(String bildirimTipi) {
    switch (bildirimTipi) {
      case 'satin_alma':
        return Icons.shopping_cart;
      case 'arac_istek':
        return Icons.directions_car;
      case 'izin_istek':
        return Icons.calendar_today;
      case 'dokumantasyon_istek':
        return Icons.description;
      case 'egitim_istek':
        return Icons.school;
      case 'yiyecek_icecek_istek':
        return Icons.restaurant;
      case 'bilgi_teknolojileri':
        return Icons.computer;
      case 'teknik_destek':
        return Icons.build;
      case 'sarf_malzeme_istek':
        return Icons.inventory;
      default:
        return Icons.notifications;
    }
  }

  /// Aksiyon tipi rengi
  Color _getColorForType(String aksiyonTipi) {
    switch (aksiyonTipi) {
      case 'onay_bekliyor':
        return AppColors.warning;
      case 'gorev_atama':
        return AppColors.primaryDark;
      case 'bilgilendirme':
      default:
        return AppColors.info;
    }
  }

  /// Zaman biçimlendirme
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm', 'tr').format(dateTime);
    }
  }
}

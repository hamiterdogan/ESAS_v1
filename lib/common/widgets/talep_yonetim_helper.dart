import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';

/// Talep yönetim ekranları için yardımcı sınıf.
///
/// Bu sınıf, talep yönetim ekranlarının ortak widget ve fonksiyonlarını sağlar:
/// - AppBar builder
/// - FloatingActionButton builder
/// - Loading, error ve empty state widget'ları
/// - Info bottom sheet
/// - Delete confirm dialog
/// - Tarih formatlama ve durum renkleri
///
/// Kullanım:
/// ```dart
/// final helper = TalepYonetimHelper(context: context, ref: ref);
///
/// // AppBar oluştur
/// helper.buildAppBar(
///   title: 'Yiyecek İçecek İsteklerini Yönet',
///   tabController: _tabController,
/// );
/// ```
class TalepYonetimHelper {
  final BuildContext context;
  final WidgetRef ref;

  TalepYonetimHelper({required this.context, required this.ref});

  // ============ APPBAR ============

  /// Standart talep yönetim AppBar'ı oluşturur
  PreferredSizeWidget buildAppBar({
    required String title,
    required TabController tabController,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: AppColors.gradientStart,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
        onPressed: onBackPressed ?? () => context.go('/'),
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      ),
      actions: actions,
      elevation: 0,
      bottom: TabBar(
        controller: tabController,
        indicatorColor: AppColors.textOnPrimary,
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.textOnPrimaryMuted,
        labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Devam Eden'),
          Tab(text: 'Tamamlanan'),
        ],
      ),
    );
  }

  // ============ FLOATING ACTION BUTTON ============

  /// Standart "Yeni İstek" FAB'ı oluşturur
  Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    String label = 'Yeni İstek',
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.gradientStart,
      icon: Container(
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: const Icon(Icons.add, color: AppColors.textOnPrimary, size: 24),
      ),
      label: Text(
        label,
        style: const TextStyle(color: AppColors.textOnPrimary),
      ),
    );
  }

  // ============ LIST STATES ============

  /// Boş liste durumu widget'ı
  Widget buildEmptyState({
    String message = 'Talep bulunamadı.',
    Future<void> Function()? onRefresh,
  }) {
    final content = const SizedBox.shrink();

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  /// Yükleme durumu widget'ı
  Widget buildLoadingState() {
    return const Center(
      child: SizedBox(
        width: 153,
        height: 153,
        child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
      ),
    );
  }

  /// Hata durumu widget'ı
  Widget buildErrorState({
    required Object error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ DIALOGS & BOTTOM SHEETS ============

  /// Bilgi/Hata bottom sheet göster
  void showInfoBottomSheet(String message, {bool isError = false}) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: AppColors.textPrimary54,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.textOnPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                size: 64,
                color: isError ? AppColors.error : AppColors.success,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Silme onay dialog'u göster
  Future<bool> showDeleteConfirmDialog({
    String title = 'Talebi Sil',
    required String content,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return shouldDelete ?? false;
  }

  // ============ UTILITY METHODS ============

  /// Tarih formatlama yardımcısı (ISO format -> dd.MM.yyyy)
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Durum rengini belirle
  static Color getStatusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('redd') || lower.contains('iptal')) {
      return AppColors.error;
    }
    if (lower.contains('onay bekliyor') || lower.contains('beklemede')) {
      return AppColors.warning; // Amber
    }
    if (lower.contains('onaylandı') || lower.contains('tamamlandı')) {
      return AppColors.success;
    }
    return AppColors.primaryGrey;
  }

  /// Durum arka plan rengini belirle
  static Color getStatusBackgroundColor(String status) {
    final color = getStatusColor(status);
    return color.withValues(alpha: 0.1);
  }

  /// Durum ikonunu belirle
  static IconData getStatusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('redd') || lower.contains('iptal')) {
      return Icons.cancel_outlined;
    }
    if (lower.contains('onay bekliyor') || lower.contains('beklemede')) {
      return Icons.access_time_rounded;
    }
    if (lower.contains('onaylandı') || lower.contains('tamamlandı')) {
      return Icons.check_circle_outline;
    }
    return Icons.info_outline;
  }

  /// Durum badge widget'ı oluşturur
  static Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);
    final bgColor = getStatusBackgroundColor(status);
    final icon = getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.isEmpty ? 'Durum Bilinmiyor' : status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

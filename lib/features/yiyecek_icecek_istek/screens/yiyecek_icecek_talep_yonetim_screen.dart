import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/repositories/yiyecek_icecek_repository.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_taleplerimi_getir_models.dart';

class YiyecekIcecekTalepYonetimScreen extends ConsumerStatefulWidget {
  const YiyecekIcecekTalepYonetimScreen({super.key});

  @override
  ConsumerState<YiyecekIcecekTalepYonetimScreen> createState() =>
      _YiyecekIcecekTalepYonetimScreenState();
}

class _YiyecekIcecekTalepYonetimScreenState
    extends ConsumerState<YiyecekIcecekTalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Refresh providers on build to ensure fresh data if needed, or rely on cache.
    // Since we want "fresh" data on entry, we can opt to invalidate or just rely on the future firing.
    // For now, removing the manual dialog management is key.

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: const Text(
            'Yiyecek İçecek İsteklerini Yönet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.gradientStart,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Devam Eden'),
              Tab(text: 'Tamamlanan'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTalepListesi(
              ref.watch(yiyecekIstekDevamEdenTaleplerProvider),
              () => ref.refresh(yiyecekIstekDevamEdenTaleplerProvider.future),
              tamamlanan: false,
            ),
            _buildTalepListesi(
              ref.watch(yiyecekIstekTamamlananTaleplerProvider),
              () => ref.refresh(yiyecekIstekTamamlananTaleplerProvider.future),
              tamamlanan: true,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/yiyecek_icecek_istek/ekle');
            // Refresh list on return
            ref.refresh(yiyecekIstekDevamEdenTaleplerProvider);
          },
          backgroundColor: AppColors.gradientStart,
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          label: const Text(
            'Yeni İstek',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTalepListesi(
    AsyncValue<List<YiyecekIstekTalep>> taleplerAsync,
    Future<List<YiyecekIstekTalep>> Function() onRefresh, {
    required bool tamamlanan,
  }) {
    return taleplerAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => onRefresh().then((_) {}),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(child: Text('Talep bulunamadı.')),
              ),
            ),
          );
        }

        // Sort by date descending
        final sorted = [...items]..sort((a, b) {
            final aDate = DateTime.tryParse(a.olusturmaTarihi);
            final bDate = DateTime.tryParse(b.olusturmaTarihi);
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

        return RefreshIndicator(
          onRefresh: () => onRefresh().then((_) {}),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final talep = sorted[index];
              return _buildTalepCard(talep);
            },
          ),
        );
      },
      // Use standard loading indicator (centered) instead of global dialog
      loading: () => const Center(child: BrandedLoadingIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hata: $error'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalepCard(YiyecekIstekTalep talep) {
    Color statusColor = Colors.blueGrey;
    Color statusBgColor = Colors.grey.withValues(alpha: 0.1);
    
    if (talep.onayDurumu.toLowerCase().contains('redd')) {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withValues(alpha: 0.1);
    }
    if (talep.onayDurumu.toLowerCase().contains('onay bekliyor')) {
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFFFF7ED);
    }
    if (talep.onayDurumu.toLowerCase().contains('onaylandı')) {
      statusColor = Colors.green;
      statusBgColor = Colors.green.withValues(alpha: 0.1);
    }

    String tarihStr = talep.olusturmaTarihi;
    try {
      final date = DateTime.parse(talep.olusturmaTarihi);
      tarihStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {}

    final card = Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Süreç No: ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${talep.onayKayitId}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF014B92),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              talep.etkinlikAdi,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              talep.aciklama.isEmpty ? 'Açıklama yok' : talep.aciklama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: tarihStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const TextSpan(
                        text: ' - ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: talep.donem,
                        style: const TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        talep.onayDurumu.toLowerCase().contains('onay bekliyor')
                            ? Icons.access_time_rounded
                            : talep.onayDurumu.toLowerCase().contains('redd')
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        talep.onayDurumu,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
    );

    // Only allow delete if status is "Onay Bekliyor"
    final isDeleteAvailable = talep.onayDurumu.toLowerCase().contains('onay bekliyor');

    return Slidable(
      key: ValueKey(talep.onayKayitId),
      enabled: isDeleteAvailable,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) => _deleteTalep(talep.onayKayitId),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 28),
                SizedBox(height: 4),
                Text('Sil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          context.push('/yiyecek_icecek_istek/detay/${talep.onayKayitId}');
        },
        child: card,
      ),
    );
  }

  Future<void> _deleteTalep(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu yiyecek içecek talebini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final repo = ref.read(yiyecekIcecekRepositoryProvider);
      final result = await repo.deleteTalep(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(yiyecekIstekDevamEdenTaleplerProvider);
        ref.invalidate(yiyecekIstekTamamlananTaleplerProvider);

        _showInfoBottomSheet('Talep başarıyla silindi', onSuccess: true);
      } else if (result is Failure) {
        _showInfoBottomSheet(
          'Silme başarısız: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showInfoBottomSheet('Hata: $e', isError: true);
    }
  }

  void _showInfoBottomSheet(String message, {bool isError = false, bool onSuccess = false}) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: Colors.black54,
       backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                 color: isError ? Colors.red : Colors.green,
               ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
                       color: Colors.white,
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
}

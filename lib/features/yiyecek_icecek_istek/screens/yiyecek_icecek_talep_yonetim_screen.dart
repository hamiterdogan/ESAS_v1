import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_taleplerimi_getir_models.dart';

class YiyecekIcecekTalepYonetimScreen extends ConsumerWidget {
  const YiyecekIcecekTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<YiyecekIstekTalep>(
      config: TalepYonetimConfig<YiyecekIstekTalep>(
        title: 'Yiyecek İçecek İsteklerini Yönet',
        addRoute: '/yiyecek_icecek_istek/ekle',
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _YiyecekIcecekTalepListesi(
            taleplerAsync: ref.watch(yiyecekIstekDevamEdenTaleplerProvider),
            onRefresh: () => ref.refresh(yiyecekIstekDevamEdenTaleplerProvider.future),
            helper: helper,
          ),
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) => 
          _YiyecekIcecekTalepListesi(
            taleplerAsync: ref.watch(yiyecekIstekTamamlananTaleplerProvider),
            onRefresh: () => ref.refresh(yiyecekIstekTamamlananTaleplerProvider.future),
            helper: helper,
          ),
      ),
    );
  }
}

class _YiyecekIcecekTalepListesi extends ConsumerWidget {
  const _YiyecekIcecekTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
  });

  final AsyncValue<List<YiyecekIstekTalep>> taleplerAsync;
  final Future<List<YiyecekIstekTalep>> Function() onRefresh;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) => _YiyecekIcecekTalepCard(
              talep: sorted[index],
              helper: helper,
            ),
          ),
        );
      },
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: () => onRefresh()),
    );
  }
}

class _YiyecekIcecekTalepCard extends ConsumerWidget {
  const _YiyecekIcecekTalepCard({
    required this.talep,
    required this.helper,
  });

  final YiyecekIstekTalep talep;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarihStr = TalepYonetimHelper.formatDate(talep.olusturmaTarihi);
    final isDeleteAvailable = talep.onayDurumu.toLowerCase().contains('onay bekliyor');

    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AppColors.textOnPrimary,
      shadowColor: AppColors.cardShadow,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${talep.onayKayitId}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              talep.aciklama.isEmpty ? 'Açıklama yok' : talep.aciklama,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const TextSpan(
                        text: ' - ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: talep.donem,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                TalepYonetimHelper.buildStatusBadge(talep.onayDurumu),
              ],
            ),
          ],
        ),
      ),
    );

    return Slidable(
      key: ValueKey(talep.onayKayitId),
      enabled: isDeleteAvailable,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) => _deleteTalep(context, ref),
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 28),
                SizedBox(height: 4),
                Text(
                  'Sil',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => context.push('/yiyecek_icecek_istek/detay/${talep.onayKayitId}'),
        child: card,
      ),
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await helper.showDeleteConfirmDialog(
      content: 'Bu yiyecek içecek talebini silmek istediğinize emin misiniz?',
    );

    if (!shouldDelete) return;

    try {
      final repo = ref.read(yiyecekIcecekRepositoryProvider);
      final result = await repo.deleteTalep(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(yiyecekIstekDevamEdenTaleplerProvider);
        ref.invalidate(yiyecekIstekTamamlananTaleplerProvider);
        helper.showInfoBottomSheet('Talep başarıyla silindi');
      } else if (result is Failure) {
        helper.showInfoBottomSheet(
          'Silme başarısız: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      helper.showInfoBottomSheet('Hata: $e', isError: true);
    }
  }
}

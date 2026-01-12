import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';

class SarfMalzemeTalepYonetimScreen extends ConsumerWidget {
  const SarfMalzemeTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<SarfMalzemeTalep>(
      config: TalepYonetimConfig<SarfMalzemeTalep>(
        title: 'Sarf Malzeme İsteklerini Yönet',
        addRoute: '/sarf_malzeme_istek/tur-secim',
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _SarfMalzemeTalepListesi(
                  taleplerAsync: ref.watch(
                    sarfMalzemeDevamEdenTaleplerProvider,
                  ),
                  onRefresh: () =>
                      ref.refresh(sarfMalzemeDevamEdenTaleplerProvider.future),
                  helper: helper,
                ),
        tamamlananBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _SarfMalzemeTalepListesi(
                  taleplerAsync: ref.watch(
                    sarfMalzemeTamamlananTaleplerProvider,
                  ),
                  onRefresh: () =>
                      ref.refresh(sarfMalzemeTamamlananTaleplerProvider.future),
                  helper: helper,
                ),
      ),
    );
  }
}

class _SarfMalzemeTalepListesi extends ConsumerWidget {
  const _SarfMalzemeTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
  });

  final AsyncValue<List<SarfMalzemeTalep>> taleplerAsync;
  final Future<List<SarfMalzemeTalep>> Function() onRefresh;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: () => onRefresh()),
      data: (talepler) {
        if (talepler.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        return RefreshIndicator(
          onRefresh: () => onRefresh().then((_) {}),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 50,
            ),
            itemCount: talepler.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) =>
                _SarfMalzemeTalepCard(talep: talepler[index], helper: helper),
          ),
        );
      },
    );
  }
}

class _SarfMalzemeTalepCard extends ConsumerWidget {
  const _SarfMalzemeTalepCard({required this.talep, required this.helper});

  final SarfMalzemeTalep talep;
  final TalepYonetimHelper helper;

  String _formatDate(DateTime date) {
    if (date.year == 1) return '-';
    try {
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarihStr = _formatDate(talep.olusturmaTarihi);

    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: AppColors.textOnPrimary,
      shadowColor: AppColors.cardShadow,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'Sarf Malzemesi: ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          talep.sarfMalzemeTuru.isEmpty
                              ? '-'
                              : talep.sarfMalzemeTuru,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    talep.aciklama.isEmpty ? '(...)' : talep.aciklama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tarihStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 30),
          ],
        ),
      ),
    );

    return Slidable(
      key: ValueKey(talep.onayKayitId),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SarfMalzemeDetayScreen(talepId: talep.onayKayitId),
            ),
          );
        },
        child: card,
      ),
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await helper.showDeleteConfirmDialog(
      content: 'Bu sarf malzeme talebini silmek istediğinize emin misiniz?',
    );

    if (!shouldDelete) return;

    try {
      final repository = ref.read(sarfMalzemeRepositoryProvider);
      final result = await repository.sarfMalzemeSil(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(sarfMalzemeDevamEdenTaleplerProvider);
        ref.invalidate(sarfMalzemeTamamlananTaleplerProvider);
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

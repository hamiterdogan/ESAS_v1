import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// Araç talep yönetim ekranı.
/// 
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// Filtreleme desteği aktiftir.
class AracTalepYonetimScreen extends ConsumerWidget {
  const AracTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<Talep>(
      config: TalepYonetimConfig<Talep>(
        title: 'Araç İsteklerini Yönet',
        addRoute: '/arac/turu_secim',
        enableFilter: true,
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _AracTalepListesi(
            taleplerAsync: ref.watch(aracDevamEdenTaleplerProvider),
            onRefresh: () => ref.refresh(aracDevamEdenTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
          );
        },
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _AracTalepListesi(
            taleplerAsync: ref.watch(aracTamamlananTaleplerProvider),
            onRefresh: () => ref.refresh(aracTamamlananTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
          );
        },
      ),
    );
  }
}

class _AracTalepListesi extends ConsumerWidget {
  const _AracTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
    this.filterPredicate,
    this.onDurumlarUpdated,
  });

  final AsyncValue<TalepYonetimResponse> taleplerAsync;
  final Future<TalepYonetimResponse> Function() onRefresh;
  final TalepYonetimHelper helper;
  final bool Function(String durum)? filterPredicate;
  final void Function(List<String> durumlar)? onDurumlarUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (data) {
        // Update available durumlar for filter
        if (onDurumlarUpdated != null) {
          final durumlar = data.talepler
              .map((t) => t.onayDurumu)
              .where((d) => d.isNotEmpty)
              .toList();
          onDurumlarUpdated!(durumlar);
        }

        // Apply filter
        final filtered = filterPredicate != null
            ? data.talepler.where((t) => filterPredicate!(t.onayDurumu)).toList()
            : data.talepler;

        if (filtered.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        // Sort by date descending
        final sorted = [...filtered]..sort((a, b) {
          final aDate = DateTime.tryParse(a.olusturmaTarihi) ?? DateTime(0);
          final bDate = DateTime.tryParse(b.olusturmaTarihi) ?? DateTime(0);
          return bDate.compareTo(aDate);
        });

        return RefreshIndicator(
          onRefresh: () => onRefresh().then((_) {}),
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 50),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => _AracTalepCard(
              talep: sorted[index],
              helper: helper,
            ),
          ),
        );
      },
      loading: () => helper.buildLoadingState(),
      error: (error, stack) => helper.buildErrorState(
        error: error,
        onRetry: () => onRefresh(),
      ),
    );
  }
}

class _AracTalepCard extends ConsumerWidget {
  const _AracTalepCard({
    required this.talep,
    required this.helper,
  });

  final Talep talep;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepCard(
      onayKayitId: talep.onayKayitId,
      onayDurumu: talep.onayDurumu,
      tarih: talep.olusturmaTarihi,
      title: 'Araç Türü: ${talep.aracTuru?.isNotEmpty == true ? talep.aracTuru! : "Bilinmiyor"}',
      onTap: () => context.push('/arac/detay/${talep.onayKayitId}'),
      onDelete: () => _deleteTalep(context, ref),
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await helper.showDeleteConfirmDialog(
      title: 'Talebi Sil',
      content: 'Bu araç isteğini silmek istediğinize emin misiniz?',
    );
    if (shouldDelete != true) return;

    try {
      final repo = ref.read(aracTalepRepositoryProvider);
      final result = await repo.aracIstekSil(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(aracDevamEdenTaleplerProvider);
        ref.invalidate(aracTamamlananTaleplerProvider);
        helper.showInfoBottomSheet('Talep başarıyla silindi');
      } else if (result is Failure) {
        helper.showInfoBottomSheet('Hata: ${result.message}', isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      helper.showInfoBottomSheet('Hata: $e', isError: true);
    }
  }
}

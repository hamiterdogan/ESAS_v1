import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// Dokümantasyon talep yönetim ekranı.
/// 
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// Filtreleme desteği aktiftir.
class DokumantasyonTalepYonetimScreen extends ConsumerWidget {
  const DokumantasyonTalepYonetimScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepYonetimScreen<Talep>(
      config: TalepYonetimConfig<Talep>(
        title: 'Dokümantasyon İsteklerini Yönet',
        addRoute: '/dokumantasyon/turu_secim',
        enableFilter: true,
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _DokumantasyonTalepListesi(
            taleplerAsync: ref.watch(dokumantasyonDevamEdenTaleplerProvider),
            onRefresh: () => ref.refresh(dokumantasyonDevamEdenTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
          );
        },
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _DokumantasyonTalepListesi(
            taleplerAsync: ref.watch(dokumantasyonTamamlananTaleplerProvider),
            onRefresh: () => ref.refresh(dokumantasyonTamamlananTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
          );
        },
      ),
    );
  }
}

class _DokumantasyonTalepListesi extends ConsumerWidget {
  const _DokumantasyonTalepListesi({
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
            itemBuilder: (context, index) => _DokumantasyonTalepCard(
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

class _DokumantasyonTalepCard extends ConsumerWidget {
  const _DokumantasyonTalepCard({
    required this.talep,
    required this.helper,
  });

  final Talep talep;
  final TalepYonetimHelper helper;

  String get _talepTuru {
    if (talep.dokumanTuru == null || talep.dokumanTuru!.isEmpty) {
      return 'A4 Kağıdı İstek';
    }
    return 'Dokümantasyon Baskı İstek';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepCard(
      onayKayitId: talep.onayKayitId,
      onayDurumu: talep.onayDurumu,
      tarih: talep.olusturmaTarihi,
      title: _talepTuru,
      onTap: () => context.push(
        '/dokumantasyon/detay/${talep.onayKayitId}',
        extra: talep.onayTipi,
      ),
      onDelete: () => _deleteTalep(context, ref),
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await helper.showDeleteConfirmDialog(
      title: 'Talebi Sil',
      content: 'Bu dokümantasyon talebini silmek istediğinize emin misiniz?',
    );
    if (shouldDelete != true) return;

    try {
      final repo = ref.read(dokumantasyonIstekRepositoryProvider);
      final result = await repo.dokumantasyonIstekSil(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(dokumantasyonDevamEdenTaleplerProvider);
        ref.invalidate(dokumantasyonTamamlananTaleplerProvider);
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

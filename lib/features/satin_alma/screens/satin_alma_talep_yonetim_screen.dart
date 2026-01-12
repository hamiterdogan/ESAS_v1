import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_talep.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';

/// Satın Alma talep yönetim ekranı.
/// 
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// Filtreleme desteği ve kategori cache'leme içerir.
class SatinAlmaTalepYonetimScreen extends ConsumerStatefulWidget {
  const SatinAlmaTalepYonetimScreen({super.key});

  @override
  ConsumerState<SatinAlmaTalepYonetimScreen> createState() =>
      _SatinAlmaTalepYonetimScreenState();
}

class _SatinAlmaTalepYonetimScreenState
    extends ConsumerState<SatinAlmaTalepYonetimScreen> {
  // Kategori isimleri cache
  Map<int, String> _anaKategoriAdlari = {};
  final Map<int, String> _altKategoriAdlari = {};
  bool _anaKategoriYuklendi = false;
  final Set<int> _yuklenenAltAnaIds = {};

  @override
  void initState() {
    super.initState();
    _loadAnaKategoriAdlariOnce();
  }

  Future<void> _loadAnaKategoriAdlariOnce() async {
    if (_anaKategoriYuklendi) return;
    try {
      final liste = await ref.read(satinAlmaAnaKategorilerProvider.future);
      if (!mounted) return;
      setState(() {
        _anaKategoriAdlari = {for (final k in liste) k.id: k.kategori};
        _anaKategoriYuklendi = true;
      });
    } catch (_) {
      // Sessiz başarısızlık
    }
  }

  Future<void> _ensureAltKategoriAdlariFor(Set<int> anaIds) async {
    final toLoad = anaIds.where((id) => !_yuklenenAltAnaIds.contains(id));
    for (final anaId in toLoad) {
      try {
        final liste = await ref.read(satinAlmaAltKategorilerProvider(anaId).future);
        if (!mounted) return;
        setState(() {
          for (final alt in liste) {
            _altKategoriAdlari[alt.id] = alt.altKategori;
          }
          _yuklenenAltAnaIds.add(anaId);
        });
      } catch (_) {
        // Sessiz geç
      }
    }
  }

  void _primeKategoriAdlari(List<SatinAlmaTalep> items) {
    final anaIds = <int>{};
    for (final talep in items) {
      if (talep.satinAlmaAnaKategoriId > 0) {
        anaIds.add(talep.satinAlmaAnaKategoriId);
      }
    }
    if (!_anaKategoriYuklendi) {
      unawaited(_loadAnaKategoriAdlariOnce());
    }
    if (anaIds.isNotEmpty) {
      unawaited(_ensureAltKategoriAdlariFor(anaIds));
    }
  }

  String _getKategoriLabel(SatinAlmaTalep talep) {
    final kategori = _anaKategoriAdlari[talep.satinAlmaAnaKategoriId]?.trim() ??
        talep.urunKategori.trim();
    final altKategori = _altKategoriAdlari[talep.satinAlmaAltKategoriId]?.trim() ??
        talep.urunAltKategori.trim();
    return [kategori, altKategori].where((e) => e.isNotEmpty).join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return GenericTalepYonetimScreen<SatinAlmaTalep>(
      config: TalepYonetimConfig<SatinAlmaTalep>(
        title: 'Satın Alma İsteklerini Yönet',
        addRoute: '/satin_alma/ekle',
        enableFilter: true,
        devamEdenBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _SatinAlmaTalepListesi(
            taleplerAsync: ref.watch(satinAlmaDevamEdenTaleplerProvider),
            onRefresh: () => ref.refresh(satinAlmaDevamEdenTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
            onItemsLoaded: _primeKategoriAdlari,
            getKategoriLabel: _getKategoriLabel,
            tamamlanan: false,
          );
        },
        tamamlananBuilder: (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
          return _SatinAlmaTalepListesi(
            taleplerAsync: ref.watch(satinAlmaTamamlananTaleplerProvider),
            onRefresh: () => ref.refresh(satinAlmaTamamlananTaleplerProvider.future),
            helper: helper,
            filterPredicate: filterPredicate,
            onDurumlarUpdated: onDurumlarUpdated,
            onItemsLoaded: _primeKategoriAdlari,
            getKategoriLabel: _getKategoriLabel,
            tamamlanan: true,
          );
        },
      ),
    );
  }
}

class _SatinAlmaTalepListesi extends ConsumerWidget {
  const _SatinAlmaTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
    required this.getKategoriLabel,
    required this.tamamlanan,
    this.filterPredicate,
    this.onDurumlarUpdated,
    this.onItemsLoaded,
  });

  final AsyncValue<List<SatinAlmaTalep>> taleplerAsync;
  final Future<List<SatinAlmaTalep>> Function() onRefresh;
  final TalepYonetimHelper helper;
  final bool Function(String durum)? filterPredicate;
  final void Function(List<String> durumlar)? onDurumlarUpdated;
  final void Function(List<SatinAlmaTalep> items)? onItemsLoaded;
  final String Function(SatinAlmaTalep talep) getKategoriLabel;
  final bool tamamlanan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (items) {
        // Prime kategori cache
        onItemsLoaded?.call(items);

        // Update available durumlar for filter
        if (onDurumlarUpdated != null) {
          final durumlar = items
              .map((t) => t.onayDurumu)
              .where((d) => d.isNotEmpty)
              .toList();
          onDurumlarUpdated!(durumlar);
        }

        // Apply filter
        final filtered = filterPredicate != null
            ? items.where((t) => filterPredicate!(t.onayDurumu)).toList()
            : items;

        if (filtered.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        // Sort by date descending
        final sorted = [...filtered]..sort((a, b) {
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
            padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 50),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) => _SatinAlmaTalepCard(
              talep: sorted[index],
              helper: helper,
              kategoriLabel: getKategoriLabel(sorted[index]),
              tamamlanan: tamamlanan,
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

class _SatinAlmaTalepCard extends ConsumerWidget {
  const _SatinAlmaTalepCard({
    required this.talep,
    required this.helper,
    required this.kategoriLabel,
    required this.tamamlanan,
  });

  final SatinAlmaTalep talep;
  final TalepYonetimHelper helper;
  final String kategoriLabel;
  final bool tamamlanan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleteAvailable = !tamamlanan && 
        talep.onayDurumu.toLowerCase().contains('onay bekliyor');

    return GenericTalepCard(
      onayKayitId: talep.onayKayitId,
      onayDurumu: talep.onayDurumu,
      tarih: talep.olusturmaTarihi,
      subtitle: talep.aciklama.isEmpty ? '(...)' : talep.aciklama,
      extraInfo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kategoriLabel.isNotEmpty)
            Text(
              kategoriLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary54,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            talep.saticiFirma.isEmpty ? '-' : talep.saticiFirma,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      onTap: () => context.push('/satin_alma/detay/${talep.onayKayitId}'),
      onDelete: isDeleteAvailable ? () => _deleteTalep(context, ref) : null,
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await helper.showDeleteConfirmDialog(
      title: 'Talebi Sil',
      content: 'Bu satın alma talebini silmek istediğinize emin misiniz?',
    );
    if (shouldDelete != true) return;

    try {
      final repo = ref.read(satinAlmaRepositoryProvider);
      final result = await repo.deleteTalep(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(satinAlmaDevamEdenTaleplerProvider);
        ref.invalidate(satinAlmaTamamlananTaleplerProvider);
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

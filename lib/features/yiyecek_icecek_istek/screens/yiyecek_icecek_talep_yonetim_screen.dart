import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_taleplerimi_getir_models.dart';

class YiyecekIcecekTalepYonetimScreen extends ConsumerStatefulWidget {
  const YiyecekIcecekTalepYonetimScreen({super.key});

  @override
  ConsumerState<YiyecekIcecekTalepYonetimScreen> createState() =>
      _YiyecekIcecekTalepYonetimScreenState();
}

class _YiyecekIcecekTalepYonetimScreenState
    extends ConsumerState<YiyecekIcecekTalepYonetimScreen> {
  String _selectedDuration = 'Tümü';
  final Set<String> _selectedRequestTypes = {};
  final Set<String> _selectedStatuses = {};

  List<String> _availableRequestTypes = [];
  List<String> _availableStatuses = [];

  final List<String> _durationOptions = const [
    'Tümü',
    '1 Hafta',
    '1 Ay',
    '3 Ay',
    '1 Yıl',
  ];

  void _updateAvailableStatuses(List<String> statuses) {
    final normalized = statuses.toSet().toList()..sort();
    if (normalized.toString() != _availableStatuses.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _availableStatuses = normalized);
      });
    }
  }

  void _updateAvailableRequestTypes(List<String> types) {
    final normalized = types.toSet().toList()..sort();
    if (normalized.toString() != _availableRequestTypes.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _availableRequestTypes = normalized);
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TalepFilterBottomSheet(
        durationOptions: _durationOptions,
        initialSelectedDuration: _selectedDuration,
        requestTypeOptions: _availableRequestTypes,
        initialSelectedRequestTypes: _selectedRequestTypes,
        requestTypeTitle: 'Etkinlik',
        requestTypeEmptyLabel: 'Henüz etkinlik bilgisi yok',
        statusOptions: _availableStatuses,
        initialSelectedStatuses: _selectedStatuses,
        onApply: (selections) {
          setState(() {
            _selectedDuration = selections.selectedDuration;
            _selectedRequestTypes
              ..clear()
              ..addAll(selections.selectedRequestTypes);
            _selectedStatuses
              ..clear()
              ..addAll(selections.selectedStatuses);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return GenericTalepYonetimScreen<YiyecekIstekTalep>(
      config: TalepYonetimConfig<YiyecekIstekTalep>(
        title: 'Yiyecek İçecek İsteklerini Yönet',
        addRoute: '/yiyecek_icecek_istek/ekle',
        enableFilter: true,
        onFilterTap: _showFilterBottomSheet,
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _YiyecekIcecekTalepListesi(
                  taleplerAsync: ref.watch(
                    yiyecekIstekDevamEdenTaleplerProvider,
                  ),
                  onRefresh: () =>
                      ref.refresh(yiyecekIstekDevamEdenTaleplerProvider.future),
                  helper: helper,
                  applyFilters: false,
                  selectedDuration: _selectedDuration,
                  selectedRequestTypes: _selectedRequestTypes,
                  selectedStatuses: _selectedStatuses,
                  onDurumlarUpdated: _updateAvailableStatuses,
                  onRequestTypesUpdated: _updateAvailableRequestTypes,
                ),
        tamamlananBuilder:
            (
              ctx,
              ref,
              helper, {
              filterPredicate,
              onDurumlarUpdated,
            }) => _YiyecekIcecekTalepListesi(
              taleplerAsync: ref.watch(yiyecekIstekTamamlananTaleplerProvider),
              onRefresh: () =>
                  ref.refresh(yiyecekIstekTamamlananTaleplerProvider.future),
              helper: helper,
              applyFilters: true,
              selectedDuration: _selectedDuration,
              selectedRequestTypes: _selectedRequestTypes,
              selectedStatuses: _selectedStatuses,
              onDurumlarUpdated: _updateAvailableStatuses,
              onRequestTypesUpdated: _updateAvailableRequestTypes,
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
    required this.applyFilters,
    required this.selectedDuration,
    required this.selectedRequestTypes,
    required this.selectedStatuses,
    this.onDurumlarUpdated,
    this.onRequestTypesUpdated,
  });

  final AsyncValue<List<YiyecekIstekTalep>> taleplerAsync;
  final Future<List<YiyecekIstekTalep>> Function() onRefresh;
  final TalepYonetimHelper helper;
  final bool applyFilters;
  final String selectedDuration;
  final Set<String> selectedRequestTypes;
  final Set<String> selectedStatuses;
  final void Function(List<String> durumlar)? onDurumlarUpdated;
  final void Function(List<String> requestTypes)? onRequestTypesUpdated;

  bool _sureFiltresindenGeciyorMu(String olusturmaTarihi) {
    if (selectedDuration == 'Tümü') return true;

    try {
      final tarih = DateTime.parse(olusturmaTarihi);
      final simdi = DateTime.now();
      final fark = simdi.difference(tarih);

      switch (selectedDuration) {
        case '1 Hafta':
          return fark.inDays <= 7;
        case '1 Ay':
          return fark.inDays <= 30;
        case '3 Ay':
          return fark.inDays <= 90;
        case '1 Yıl':
          return fark.inDays <= 365;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  bool _istekTuruFiltresindenGeciyorMu(String etkinlikAdi) {
    if (selectedRequestTypes.isEmpty) return true;
    final value = etkinlikAdi.toLowerCase();
    return selectedRequestTypes.any((tur) => value.contains(tur.toLowerCase()));
  }

  bool _talepDurumuFiltresindenGeciyorMu(String onayDurumu) {
    if (selectedStatuses.isEmpty) return true;
    final value = onayDurumu.toLowerCase();
    return selectedStatuses.any((durum) => value.contains(durum.toLowerCase()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (items) {
        if (applyFilters && onDurumlarUpdated != null) {
          final durumlar = items
              .map((t) => t.onayDurumu)
              .where((d) => d.isNotEmpty)
              .toList();
          onDurumlarUpdated!(durumlar);
        }

        if (applyFilters && onRequestTypesUpdated != null) {
          final types = items
              .map((t) => t.etkinlikAdi)
              .where((t) => t.isNotEmpty)
              .toList();
          onRequestTypesUpdated!(types);
        }

        if (items.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        final filtered = applyFilters
            ? items.where((item) {
                final surePassed = _sureFiltresindenGeciyorMu(
                  item.olusturmaTarihi,
                );
                final typePassed = _istekTuruFiltresindenGeciyorMu(
                  item.etkinlikAdi,
                );
                final statusPassed = _talepDurumuFiltresindenGeciyorMu(
                  item.onayDurumu,
                );
                return surePassed && typePassed && statusPassed;
              }).toList()
            : items;

        if (filtered.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        final sorted = [...filtered]
          ..sort((a, b) {
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
            itemBuilder: (context, index) =>
                _YiyecekIcecekTalepCard(talep: sorted[index], helper: helper),
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
  const _YiyecekIcecekTalepCard({required this.talep, required this.helper});

  final YiyecekIstekTalep talep;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tarihStr = TalepYonetimHelper.formatDate(talep.olusturmaTarihi);
    final isDeleteAvailable = talep.onayDurumu.toLowerCase().contains(
      'onay bekliyor',
    );

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
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
        onTap: () =>
            context.push('/yiyecek_icecek_istek/detay/${talep.onayKayitId}'),
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

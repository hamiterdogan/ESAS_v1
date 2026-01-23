import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';

class SarfMalzemeTalepYonetimScreen extends ConsumerStatefulWidget {
  const SarfMalzemeTalepYonetimScreen({super.key});

  @override
  ConsumerState<SarfMalzemeTalepYonetimScreen> createState() =>
      _SarfMalzemeTalepYonetimScreenState();
}

class _SarfMalzemeTalepYonetimScreenState
    extends ConsumerState<SarfMalzemeTalepYonetimScreen> {
  // Filtre değerleri
  String _selectedDuration = 'Tümü';
  final Set<String> _selectedRequestTypes = {};
  final Set<String> _selectedStatuses = {};

  // Mevcut filtre seçenekleri
  List<String> _availableRequestTypes = [];
  List<String> _availableStatuses = [];

  // Süre seçenekleri
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
        statusOptions: _availableStatuses,
        initialSelectedStatuses: _selectedStatuses,
        requestTypeTitle: 'Sarf Malzeme Türü',
        requestTypeEmptyLabel: 'Henüz sarf malzeme türü bilgisi yok',
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
    return GenericTalepYonetimScreen<SarfMalzemeTalep>(
      config: TalepYonetimConfig<SarfMalzemeTalep>(
        title: 'Sarf Malzeme İsteklerini Yönet',
        addRoute: '/sarf_malzeme_istek/tur-secim',
        enableFilter: true,
        onFilterTap: _showFilterBottomSheet,
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _SarfMalzemeTalepListesi(
                  taleplerAsync: ref.watch(
                    sarfMalzemeDevamEdenTaleplerProvider,
                  ),
                  onRefresh: () =>
                      ref.refresh(sarfMalzemeDevamEdenTaleplerProvider.future),
                  helper: helper,
                  applyFilters: false,
                  selectedDuration: _selectedDuration,
                  selectedRequestTypes: _selectedRequestTypes,
                  selectedStatuses: _selectedStatuses,
                  onDurumlarUpdated: _updateAvailableStatuses,
                  onRequestTypesUpdated: _updateAvailableRequestTypes,
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

class _SarfMalzemeTalepListesi extends ConsumerWidget {
  const _SarfMalzemeTalepListesi({
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

  final AsyncValue<List<SarfMalzemeTalep>> taleplerAsync;
  final Future<List<SarfMalzemeTalep>> Function() onRefresh;
  final TalepYonetimHelper helper;
  final bool applyFilters;
  final String selectedDuration;
  final Set<String> selectedRequestTypes;
  final Set<String> selectedStatuses;
  final void Function(List<String> durumlar)? onDurumlarUpdated;
  final void Function(List<String> requestTypes)? onRequestTypesUpdated;

  bool _sureFiltresindenGeciyorMu(DateTime olusturmaTarihi) {
    if (selectedDuration == 'Tümü') return true;

    try {
      final simdi = DateTime.now();
      final fark = simdi.difference(olusturmaTarihi);

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

  bool _istekTuruFiltresindenGeciyorMu(String requestType) {
    if (selectedRequestTypes.isEmpty) return true;
    final value = requestType.toLowerCase();
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
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: () => onRefresh()),
      data: (talepler) {
        if (applyFilters && onDurumlarUpdated != null) {
          final durumlar = talepler
              .map((t) => t.onayDurumu)
              .where((d) => d.isNotEmpty)
              .toList();
          onDurumlarUpdated!(durumlar);
        }

        if (applyFilters && onRequestTypesUpdated != null) {
          final types = talepler
              .map((t) => t.sarfMalzemeTuru)
              .where((t) => t.isNotEmpty)
              .toList();
          onRequestTypesUpdated!(types);
        }

        if (talepler.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        final filtered = applyFilters
            ? talepler.where((talep) {
                final surePassed = _sureFiltresindenGeciyorMu(
                  talep.olusturmaTarihi,
                );
                final typePassed = _istekTuruFiltresindenGeciyorMu(
                  talep.sarfMalzemeTuru,
                );
                final statusPassed = _talepDurumuFiltresindenGeciyorMu(
                  talep.onayDurumu,
                );
                return surePassed && typePassed && statusPassed;
              }).toList()
            : talepler;

        if (filtered.isEmpty) {
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
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) =>
                _SarfMalzemeTalepCard(talep: filtered[index], helper: helper),
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
                      const Spacer(),
                      Transform.translate(
                        offset: const Offset(38, 0),
                        child: TalepYonetimHelper.buildStatusBadge(
                          talep.onayDurumu,
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

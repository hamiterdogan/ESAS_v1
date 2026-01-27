import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// Araç talep yönetim ekranı.
///
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// Filtreleme desteği aktiftir.
class AracTalepYonetimScreen extends ConsumerStatefulWidget {
  const AracTalepYonetimScreen({super.key});

  @override
  ConsumerState<AracTalepYonetimScreen> createState() =>
      _AracTalepYonetimScreenState();
}

class _AracTalepYonetimScreenState
    extends ConsumerState<AracTalepYonetimScreen> {
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

  bool _showLoadingOverlay = true;

  @override
  void initState() {
    super.initState();
    // 6 saniye loading göster
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() {
          _showLoadingOverlay = false;
        });
      }
    });
  }

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
        requestTypeTitle: 'Araç Türü',
        requestTypeEmptyLabel: 'Henüz araç türü bilgisi yok',
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
    return Stack(
      children: [
        GenericTalepYonetimScreen<Talep>(
          config: TalepYonetimConfig<Talep>(
            title: 'Araç İsteklerini Yönet',
            addRoute: '/arac/turu_secim',
            enableFilter: true,
            onFilterTap: () => _showFilterBottomSheet(),
            devamEdenBuilder:
                (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
                  return _AracTalepListesi(
                    taleplerAsync: ref.watch(aracDevamEdenTaleplerProvider),
                    onRefresh: () =>
                        ref.refresh(aracDevamEdenTaleplerProvider.future),
                    helper: helper,
                    applyFilters: false,
                    selectedDuration: _selectedDuration,
                    selectedRequestTypes: _selectedRequestTypes,
                    selectedStatuses: _selectedStatuses,
                    onDurumlarUpdated: _updateAvailableStatuses,
                    onRequestTypesUpdated: _updateAvailableRequestTypes,
                  );
                },
            tamamlananBuilder:
                (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
                  return _AracTalepListesi(
                    taleplerAsync: ref.watch(aracTamamlananTaleplerProvider),
                    onRefresh: () =>
                        ref.refresh(aracTamamlananTaleplerProvider.future),
                    helper: helper,
                    applyFilters: true,
                    selectedDuration: _selectedDuration,
                    selectedRequestTypes: _selectedRequestTypes,
                    selectedStatuses: _selectedStatuses,
                    onDurumlarUpdated: _updateAvailableStatuses,
                    onRequestTypesUpdated: _updateAvailableRequestTypes,
                  );
                },
          ),
        ),
        if (_showLoadingOverlay)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: BrandedLoadingIndicator(),
            ),
          ),
      ],
    );
  }
}

class _AracTalepListesi extends ConsumerWidget {
  const _AracTalepListesi({
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

  final AsyncValue<TalepYonetimResponse> taleplerAsync;
  final Future<TalepYonetimResponse> Function() onRefresh;
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

  bool _istekTuruFiltresindenGeciyorMu(String? aracTuru) {
    if (selectedRequestTypes.isEmpty) return true;
    final value = (aracTuru ?? '').toLowerCase();
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
      data: (data) {
        // Update available durumlar for filter
        if (applyFilters && onDurumlarUpdated != null) {
          final durumlar = data.talepler
              .map((t) => t.onayDurumu)
              .where((d) => d.isNotEmpty)
              .toList();
          onDurumlarUpdated!(durumlar);
        }

        if (applyFilters && onRequestTypesUpdated != null) {
          final types = data.talepler
              .map((t) => t.aracTuru ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
          onRequestTypesUpdated!(types);
        }

        // Apply filter
        final filtered = applyFilters
            ? data.talepler.where((t) {
                final surePassed = _sureFiltresindenGeciyorMu(
                  t.olusturmaTarihi,
                );
                final turPassed = _istekTuruFiltresindenGeciyorMu(t.aracTuru);
                final durumPassed = _talepDurumuFiltresindenGeciyorMu(
                  t.onayDurumu,
                );
                return surePassed && turPassed && durumPassed;
              }).toList()
            : data.talepler;

        if (filtered.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        // Sort by date descending
        final sorted = [...filtered]
          ..sort((a, b) {
            final aDate = DateTime.tryParse(a.olusturmaTarihi) ?? DateTime(0);
            final bDate = DateTime.tryParse(b.olusturmaTarihi) ?? DateTime(0);
            return bDate.compareTo(aDate);
          });

        return RefreshIndicator(
          onRefresh: () => onRefresh().then((_) {}),
          child: ListView.separated(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 50,
            ),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => RepaintBoundary(
              child: _AracTalepCard(talep: sorted[index], helper: helper),
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

class _AracTalepCard extends ConsumerWidget {
  const _AracTalepCard({required this.talep, required this.helper});

  final Talep talep;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GenericTalepCard(
      onayKayitId: talep.onayKayitId,
      onayDurumu: talep.onayDurumu,
      tarih: talep.olusturmaTarihi,
      title:
          'Araç Türü: ${talep.aracTuru?.isNotEmpty == true ? talep.aracTuru! : "Bilinmiyor"}',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// Dokümantasyon talep yönetim ekranı.
///
/// GenericTalepYonetimScreen kullanarak ortak yapıyı uygular.
/// Filtreleme desteği aktiftir.
class DokumantasyonTalepYonetimScreen extends ConsumerStatefulWidget {
  const DokumantasyonTalepYonetimScreen({super.key});

  @override
  ConsumerState<DokumantasyonTalepYonetimScreen> createState() =>
      _DokumantasyonTalepYonetimScreenState();
}

class _DokumantasyonTalepYonetimScreenState
    extends ConsumerState<DokumantasyonTalepYonetimScreen> {
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
        requestTypeTitle: 'Doküman Türü',
        requestTypeEmptyLabel: 'Henüz doküman türü bilgisi yok',
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
    return GenericTalepYonetimScreen<Talep>(
      config: TalepYonetimConfig<Talep>(
        title: 'Dokümantasyon İsteklerini Yönet',
        addRoute: '/dokumantasyon/turu_secim',
        enableFilter: true,
        onFilterTap: _showFilterBottomSheet,
        devamEdenBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) {
              return _DokumantasyonTalepListesi(
                taleplerAsync: ref.watch(
                  dokumantasyonDevamEdenTaleplerProvider,
                ),
                onRefresh: () =>
                    ref.refresh(dokumantasyonDevamEdenTaleplerProvider.future),
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
              return _DokumantasyonTalepListesi(
                taleplerAsync: ref.watch(
                  dokumantasyonTamamlananTaleplerProvider,
                ),
                onRefresh: () =>
                    ref.refresh(dokumantasyonTamamlananTaleplerProvider.future),
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
    );
  }
}

class _DokumantasyonTalepListesi extends ConsumerWidget {
  const _DokumantasyonTalepListesi({
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

  String _resolveRequestType(Talep talep) {
    if (talep.dokumanTuru == null || talep.dokumanTuru!.isEmpty) {
      return 'A4 Kağıdı İstek';
    }
    return 'Dokümantasyon Baskı İstek';
  }

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
              .map(_resolveRequestType)
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
                final typeLabel = _resolveRequestType(t);
                final typePassed = _istekTuruFiltresindenGeciyorMu(typeLabel);
                final statusPassed = _talepDurumuFiltresindenGeciyorMu(
                  t.onayDurumu,
                );
                return surePassed && typePassed && statusPassed;
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
            itemBuilder: (context, index) =>
                _DokumantasyonTalepCard(talep: sorted[index], helper: helper),
          ),
        );
      },
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: () => onRefresh()),
    );
  }
}

class _DokumantasyonTalepCard extends ConsumerWidget {
  const _DokumantasyonTalepCard({required this.talep, required this.helper});

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

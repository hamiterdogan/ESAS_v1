import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/generic_talep_yonetim_screen.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/providers/teknik_destek_talep_providers.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';
import 'package:esas_v1/features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

/// Bilgi Teknoloji talep yönetim ekranı.
///
/// Bu ekran [GenericTalepYonetimScreen] widget'ını kullanarak
/// ortak talep yönetim yapısını uygular.
///
/// TODO: Provider'lar ve modeller oluşturulduktan sonra
/// tam implementation eklenecek.
class BilgiTeknolojiBilgiTalepYonetimScreen extends ConsumerStatefulWidget {
  const BilgiTeknolojiBilgiTalepYonetimScreen({super.key});

  @override
  ConsumerState<BilgiTeknolojiBilgiTalepYonetimScreen> createState() =>
      _BilgiTeknolojiBilgiTalepYonetimScreenState();
}

class _BilgiTeknolojiBilgiTalepYonetimScreenState
    extends ConsumerState<BilgiTeknolojiBilgiTalepYonetimScreen> {
  String _selectedDuration = 'Tümü';
  final Set<String> _selectedRequestTypes = {};
  final Set<String> _selectedStatuses = {};

  final List<String> _durationOptions = const [
    'Tümü',
    '1 Hafta',
    '1 Ay',
    '3 Ay',
    '1 Yıl',
  ];

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
        requestTypeOptions: const [],
        initialSelectedRequestTypes: _selectedRequestTypes,
        statusOptions: const [],
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
    return GenericTalepYonetimScreen<dynamic>(
      config: TalepYonetimConfig<dynamic>(
        title: 'Bilgi Teknolojileri İsteklerini Yönet',
        addRoute: '/bilgi_teknolojileri/ekle',
        enableFilter: true,
        onFilterTap: _showFilterBottomSheet,
        devamEdenBuilder:
            (
              ctx,
              ref,
              helper, {
              filterPredicate,
              onDurumlarUpdated,
            }) => _TeknikDestekTalepListesi(
              taleplerAsync: ref.watch(bilgiTeknolojiDevamEdenTaleplerProvider),
              onRefresh: () =>
                  ref.refresh(bilgiTeknolojiDevamEdenTaleplerProvider.future),
              helper: helper,
            ),
        tamamlananBuilder:
            (ctx, ref, helper, {filterPredicate, onDurumlarUpdated}) =>
                _TeknikDestekTalepListesi(
                  taleplerAsync: ref.watch(
                    bilgiTeknolojiTamamlananTaleplerProvider,
                  ),
                  onRefresh: () => ref.refresh(
                    bilgiTeknolojiTamamlananTaleplerProvider.future,
                  ),
                  helper: helper,
                ),
      ),
    );
  }
}

class _TeknikDestekTalepListesi extends ConsumerWidget {
  const _TeknikDestekTalepListesi({
    required this.taleplerAsync,
    required this.onRefresh,
    required this.helper,
  });

  final AsyncValue<TalepYonetimResponse> taleplerAsync;
  final Future<TalepYonetimResponse> Function() onRefresh;
  final TalepYonetimHelper helper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return taleplerAsync.when(
      data: (data) {
        if (data.talepler.isEmpty) {
          return helper.buildEmptyState(
            onRefresh: () => onRefresh().then((_) {}),
          );
        }

        final sorted = [...data.talepler]
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
                _TeknikDestekTalepCard(talep: sorted[index], helper: helper),
          ),
        );
      },
      loading: () => helper.buildLoadingState(),
      error: (error, stack) =>
          helper.buildErrorState(error: error, onRetry: () => onRefresh()),
    );
  }
}

class _TeknikDestekTalepCard extends ConsumerWidget {
  const _TeknikDestekTalepCard({required this.talep, required this.helper});

  final Talep talep;
  final TalepYonetimHelper helper;

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    if (normalizedStatus.contains('devam') ||
        normalizedStatus.contains('bekleme') ||
        normalizedStatus.contains('bekliyor') ||
        normalizedStatus.contains('onay bekliyor')) {
      return const Color(0xFFFFA500); // Orange for "Onay Bekliyor"
    } else if (normalizedStatus.contains('onaylandi') ||
        normalizedStatus.contains('uygun')) {
      return const Color(0xFF4CAF50); // Green for "Onaylandı"
    } else if (normalizedStatus.contains('reddedildi')) {
      return const Color(0xFFF44336); // Red for "Reddedildi"
    }
    return const Color(0xFF9E9E9E); // Grey default
  }

  String _getStatusText(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    if (normalizedStatus.contains('devam') ||
        normalizedStatus.contains('bekleme') ||
        normalizedStatus.contains('bekliyor') ||
        normalizedStatus.contains('onay bekliyor')) {
      return 'Devam Ediyor';
    } else if (normalizedStatus.contains('tamamland')) {
      return 'Tamamlandı';
    } else if (normalizedStatus.contains('reddedildi')) {
      return 'Reddedildi';
    }
    return status;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(talep.onayDurumu);
    final statusText = _getStatusText(talep.onayDurumu);
    final formattedDate = _formatDate(talep.olusturmaTarihi);

    // Extract hizmet türü from hizmetTuru field or actionAdi or use default
    final hizmetTuru =
        talep.hizmetTuru?.trim() ??
        talep.actionAdi?.trim() ??
        'Bilgi Teknolojileri';

    // Use aciklama field from API response
    final aciklama = talep.aciklama ?? '';

    final isDeleteAvailable =
        talep.onayDurumu.toLowerCase().contains('devam') ||
        talep.onayDurumu.toLowerCase().contains('bekleme');

    final cardWidget = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TeknikDestekDetayScreen(talepId: talep.onayKayitId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Süreç No
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Süreç No: ',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF212121),
                              ),
                            ),
                            TextSpan(
                              text: '${talep.onayKayitId}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusColor == const Color(0xFFFFA500)
                                  ? Icons.schedule
                                  : statusColor == const Color(0xFF4CAF50)
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Hizmet Türü (bold)
                Text(
                  hizmetTuru,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),

                // Açıklama (if available)
                if (aciklama.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      aciklama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),

                // Tarih
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isDeleteAvailable) {
      return cardWidget;
    }

    return Slidable(
      key: ValueKey(talep.onayKayitId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) => _deleteTalep(context, ref),
            backgroundColor: AppColors.error,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, size: 36, color: AppColors.textOnPrimary),
                  SizedBox(height: 6),
                  Text(
                    'Talebi Sil',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: cardWidget,
    );
  }

  Future<void> _deleteTalep(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await _showDeleteConfirmDialog(context);
    if (shouldDelete != true) return;

    try {
      final repo = ref.read(bilgiTeknolojileriIstekRepositoryProvider);
      final result = await repo.deleteTalep(id: talep.onayKayitId);

      if (!context.mounted) return;

      if (result is Success) {
        ref.invalidate(bilgiTeknolojiDevamEdenTaleplerProvider);
        ref.invalidate(bilgiTeknolojiTamamlananTaleplerProvider);
        helper.showInfoBottomSheet('Talep başarıyla silindi');
      } else if (result is Failure) {
        helper.showInfoBottomSheet('Hata: ${result.message}', isError: true);
      }
    } catch (e) {
      if (!context.mounted) return;
      helper.showInfoBottomSheet('Hata: $e', isError: true);
    }
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu bilgi teknolojileri talebini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

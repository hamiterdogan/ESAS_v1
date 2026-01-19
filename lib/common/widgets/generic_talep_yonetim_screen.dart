import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/common_appbar_action_button.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';

/// Generic talep yönetim ekranı.
///
/// Bu widget, tüm talep türleri için ortak yapıyı sağlar:
/// - AppBar (başlık, geri tuşu, tab bar)
/// - TabBarView (devam eden / tamamlanan)
/// - FloatingActionButton (yeni istek)
/// - Filtreleme desteği (tamamlanan tab için)
///
/// Özelleştirmeler [config] parametresi ile yapılır.
class GenericTalepYonetimScreen<T> extends ConsumerStatefulWidget {
  const GenericTalepYonetimScreen({super.key, required this.config});

  final TalepYonetimConfig<T> config;

  @override
  ConsumerState<GenericTalepYonetimScreen<T>> createState() =>
      _GenericTalepYonetimScreenState<T>();
}

class _GenericTalepYonetimScreenState<T>
    extends ConsumerState<GenericTalepYonetimScreen<T>>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TalepYonetimHelper _helper;

  // Filtre state
  Set<String> _selectedDurumlar = {};
  List<String> _availableDurumlar = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _helper = TalepYonetimHelper(context: context, ref: ref);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateAvailableDurumlar(List<String> durumlar) {
    final yeniDurumlar = durumlar.toSet().toList()..sort();
    if (yeniDurumlar.toString() != _availableDurumlar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _availableDurumlar = yeniDurumlar);
      });
    }
  }

  bool _filtreyeUygunMu(String durum) {
    if (_selectedDurumlar.isEmpty) return true;
    final durumStr = durum.isEmpty ? 'Belirsiz' : durum;
    return _selectedDurumlar.contains(durumStr);
  }

  Future<void> _showFilterBottomSheet() async {
    if (_availableDurumlar.isEmpty) return;

    final tempSelected = <String>{..._selectedDurumlar};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Talep Durumu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            modalSetState(tempSelected.clear);
                            setState(() => _selectedDurumlar = {});
                            Navigator.pop(context);
                          },
                          child: const Text('Temizle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _availableDurumlar.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade300),
                        itemBuilder: (context, index) {
                          final durum = _availableDurumlar[index];
                          final isSelected = tempSelected.contains(durum);
                          return InkWell(
                            onTap: () {
                              modalSetState(() {
                                if (isSelected) {
                                  tempSelected.remove(durum);
                                } else {
                                  tempSelected.add(durum);
                                }
                              });
                              setState(
                                () => _selectedDurumlar = {...tempSelected},
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      durum.isEmpty ? 'Belirsiz' : durum,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 40,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.gradientStart
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.gradientStart
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Center(
                                            child: Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppColors.textOnPrimary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget>? _buildAppBarActions() {
    if (!widget.config.enableFilter) return widget.config.appBarActions;

    if (_tabController.index == 1) {
      return [
        CommonAppBarActionButton(
          label: 'Filtrele',
          onTap: widget.config.onFilterTap ?? _showFilterBottomSheet,
        ),
        ...?widget.config.appBarActions,
      ];
    }
    return widget.config.appBarActions;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: _helper.buildAppBar(
          title: widget.config.title,
          tabController: _tabController,
          actions: _buildAppBarActions(),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Devam Eden tab
            widget.config.devamEdenBuilder?.call(
                  context,
                  ref,
                  _helper,
                  filterPredicate: null, // Devam eden için filtre yok
                  onDurumlarUpdated: null,
                ) ??
                _helper.buildEmptyState(
                  message: widget.config.emptyMessage ?? 'Talep bulunamadı.',
                  onRefresh: () async => setState(() {}),
                ),
            // Tamamlanan tab
            widget.config.tamamlananBuilder?.call(
                  context,
                  ref,
                  _helper,
                  filterPredicate: widget.config.enableFilter
                      ? _filtreyeUygunMu
                      : null,
                  onDurumlarUpdated: widget.config.enableFilter
                      ? _updateAvailableDurumlar
                      : null,
                ) ??
                _helper.buildEmptyState(
                  message: widget.config.emptyMessage ?? 'Talep bulunamadı.',
                  onRefresh: () async => setState(() {}),
                ),
          ],
        ),
        floatingActionButton: widget.config.showFab
            ? _helper.buildFloatingActionButton(
                onPressed: () => context.push(widget.config.addRoute),
                label: widget.config.fabLabel ?? 'Yeni İstek',
              )
            : null,
      ),
    );
  }
}

/// Talep yönetim ekranı konfigürasyonu.
class TalepYonetimConfig<T> {
  const TalepYonetimConfig({
    required this.title,
    required this.addRoute,
    this.devamEdenBuilder,
    this.tamamlananBuilder,
    this.appBarActions,
    this.showFab = true,
    this.fabLabel,
    this.emptyMessage,
    this.enableFilter = false,
    this.onFilterTap,
  });

  /// AppBar başlığı
  final String title;

  /// Yeni istek ekleme route'u
  final String addRoute;

  /// Devam eden tab içeriği builder
  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    TalepYonetimHelper helper, {
    bool Function(String durum)? filterPredicate,
    void Function(List<String> durumlar)? onDurumlarUpdated,
  })?
  devamEdenBuilder;

  /// Tamamlanan tab içeriği builder
  final Widget Function(
    BuildContext context,
    WidgetRef ref,
    TalepYonetimHelper helper, {
    bool Function(String durum)? filterPredicate,
    void Function(List<String> durumlar)? onDurumlarUpdated,
  })?
  tamamlananBuilder;

  /// AppBar action butonları
  final List<Widget>? appBarActions;

  /// FAB gösterilsin mi
  final bool showFab;

  /// FAB etiketi
  final String? fabLabel;

  /// Boş liste mesajı
  final String? emptyMessage;

  /// Tamamlanan tab için filtreleme aktif mi
  final bool enableFilter;

  /// Filtre butonu tıklaması (opsiyonel)
  final VoidCallback? onFilterTap;
}

// ─────────────────────────────────────────────────────────────────────────────
// ORTAK TALEP CARD BİLEŞENLERİ
// ─────────────────────────────────────────────────────────────────────────────

/// Generic talep kartı - tüm talep türleri için kullanılabilir.
class GenericTalepCard extends StatelessWidget {
  const GenericTalepCard({
    super.key,
    required this.onayKayitId,
    required this.onayDurumu,
    required this.tarih,
    required this.onTap,
    this.title,
    this.subtitle,
    this.extraInfo,
    this.onDelete,
    this.showChevron = true,
  });

  final int onayKayitId;
  final String onayDurumu;
  final String tarih;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final Widget? extraInfo;
  final Future<void> Function()? onDelete;
  final bool showChevron;

  bool get _isDeleteAvailable =>
      onDelete != null && onayDurumu.toLowerCase().contains('onay bekliyor');

  @override
  Widget build(BuildContext context) {
    final tarihStr = TalepYonetimHelper.formatDate(tarih);
    final statusColor = TalepYonetimHelper.getStatusColor(onayDurumu);

    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            AppColors.textOnPrimary,
            0.65,
          ) ??
          AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Süreç No
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
                        '$onayKayitId',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  if (extraInfo != null) ...[
                    const SizedBox(height: 4),
                    extraInfo!,
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          tarihStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TalepYonetimHelper.getStatusIcon(onayDurumu),
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                onayDurumu.isEmpty
                                    ? 'Durum Bilinmiyor'
                                    : onayDurumu,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 30, color: Colors.grey.shade500),
            ],
          ],
        ),
      ),
    );

    if (!_isDeleteAvailable) {
      return GestureDetector(onTap: onTap, child: card);
    }

    return Slidable(
      key: ValueKey(onayKayitId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          CustomSlidableAction(
            onPressed: (_) => onDelete?.call(),
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
      child: Builder(
        builder: (builderContext) => GestureDetector(
          onTap: () {
            final slidable = Slidable.of(builderContext);
            final isClosed =
                slidable?.actionPaneType.value == ActionPaneType.none;
            if (!isClosed) {
              slidable?.close();
              return;
            }
            onTap();
          },
          child: card,
        ),
      ),
    );
  }
}

/// Generic talep listesi widget'ı
class GenericTalepListView<T> extends StatelessWidget {
  const GenericTalepListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    required this.helper,
    this.emptyMessage,
    this.sortBy,
    this.filterPredicate,
    this.onItemsLoaded,
  });

  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final TalepYonetimHelper helper;
  final String? emptyMessage;
  final int Function(T a, T b)? sortBy;
  final bool Function(T item)? filterPredicate;
  final void Function(List<T> items)? onItemsLoaded;

  @override
  Widget build(BuildContext context) {
    // Apply filter if provided
    var filtered = filterPredicate != null
        ? items.where(filterPredicate!).toList()
        : items;

    // Apply sorting if provided
    if (sortBy != null) {
      filtered = [...filtered]..sort(sortBy);
    }

    // Notify about loaded items
    if (onItemsLoaded != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onItemsLoaded!(filtered);
      });
    }

    if (filtered.isEmpty) {
      return helper.buildEmptyState(
        message: emptyMessage ?? 'Sonuç bulunamadı.',
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 50),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) => itemBuilder(filtered[index]),
      ),
    );
  }
}

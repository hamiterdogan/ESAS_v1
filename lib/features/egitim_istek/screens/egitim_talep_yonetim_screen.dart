import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_talep_item.dart';
import 'package:esas_v1/features/egitim_istek/providers/egitim_istek_providers.dart';
import 'package:esas_v1/features/egitim_istek/repositories/egitim_istek_repository.dart';
import 'package:esas_v1/core/models/result.dart';

class EgitimTalepYonetimScreen extends ConsumerStatefulWidget {
  const EgitimTalepYonetimScreen({super.key});

  @override
  ConsumerState<EgitimTalepYonetimScreen> createState() =>
      _EgitimTalepYonetimScreenState();
}

class _EgitimTalepYonetimScreenState
    extends ConsumerState<EgitimTalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _showStatusBottomSheet(
    String message, {
    bool isError = false,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final icon = isError ? Icons.error_outline : Icons.check_circle_outline;
        final iconColor = isError ? Colors.red : AppColors.gradientStart;

        return Container(
          padding: const EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: 60,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Icon(icon, color: iconColor, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) +
                      3,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteEgitimTalebi(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu eğitim talebini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final repo = ref.read(egitimIstekRepositoryProvider);
      final result = await repo.egitimIstekSil(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(egitimDevamEdenTaleplerProvider);
        ref.invalidate(egitimTamamlananTaleplerProvider);
        await _showStatusBottomSheet('Talep başarıyla silindi');
      } else if (result is Failure) {
        await _showStatusBottomSheet('Hata: ${result.message}', isError: true);
      } else {
        await _showStatusBottomSheet('Hata oluştu', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      await _showStatusBottomSheet('Hata: $e', isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text(
              'Eğitim İsteklerini Yönet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: AppColors.gradientStart,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Devam Eden'),
              Tab(text: 'Tamamlanan'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTalepListesi(
              ref.watch(egitimDevamEdenTaleplerProvider),
              () => ref.refresh(egitimDevamEdenTaleplerProvider.future),
            ),
            _buildTalepListesi(
              ref.watch(egitimTamamlananTaleplerProvider),
              () => ref.refresh(egitimTamamlananTaleplerProvider.future),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/egitim_istek/ekle');
          },
          backgroundColor: AppColors.gradientStart,
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
          label: const Text(
            'Yeni İstek',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase().contains('redd')) return Colors.red;
    if (status.toLowerCase().contains('onay bekliyor')) return Colors.orange;
    if (status.toLowerCase().contains('onay')) return Colors.green;
    return Colors.blueGrey;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildTalepListesi(
    AsyncValue<List<EgitimTalepItem>> taleplerAsync,
    VoidCallback onRefresh,
  ) {
    return taleplerAsync.when(
      data: (talepler) {
        if (talepler.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(
                  child: Text(
                    'Talep bulunamadı',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: talepler.length,
            itemBuilder: (context, index) {
              final talep = talepler[index];
              final statusColor = _getStatusColor(talep.onayDurumu);
              final tarihStr = _formatDate(talep.baslangicTarihi);

              final isDeleteAvailable = talep.onayDurumu.toLowerCase().contains(
                'onay bekliyor',
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Slidable(
                  key: ValueKey(talep.onayKayitId),
                  endActionPane: isDeleteAvailable
                      ? ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            CustomSlidableAction(
                              onPressed: (_) =>
                                  _deleteEgitimTalebi(talep.onayKayitId),
                              backgroundColor: Colors.red,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 36,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Talebi Sil',
                                      style: TextStyle(
                                        color: Colors.white,
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
                        )
                      : null,
                  child: Builder(
                    builder: (builderContext) => Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          final slidable = Slidable.of(builderContext);
                          final isClosed =
                              slidable?.actionPaneType.value ==
                              ActionPaneType.none;

                          if (!isClosed) {
                            slidable?.close();
                            return;
                          }

                          context.push(
                            '/egitim_istek/detay/${talep.onayKayitId}',
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Süreç No: ',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '${talep.onayKayitId}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF014B92),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        talep.egitimAdi.isEmpty
                                            ? '(...)'
                                            : talep.egitimAdi,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tarihStr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  talep.onayDurumu
                                                          .toLowerCase()
                                                          .contains(
                                                            'onay bekliyor',
                                                          )
                                                      ? Icons.access_time
                                                      : talep.onayDurumu
                                                            .toLowerCase()
                                                            .contains('redd')
                                                      ? Icons.close
                                                      : Icons.check_circle,
                                                  size: 16,
                                                  color: statusColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    talep.onayDurumu.isEmpty
                                                        ? 'Durum Bilinmiyor'
                                                        : talep.onayDurumu,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  size: 30,
                                  color: Colors.grey.shade500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 153,
          height: 153,
          child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hata: $error'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

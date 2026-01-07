import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/repositories/sarf_malzeme_repository.dart'
    as repo;
import 'package:intl/intl.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';

class SarfMalzemeTalepYonetimScreen extends ConsumerStatefulWidget {
  const SarfMalzemeTalepYonetimScreen({super.key});

  @override
  ConsumerState<SarfMalzemeTalepYonetimScreen> createState() =>
      _SarfMalzemeTalepYonetimScreenState();
}

class _SarfMalzemeTalepYonetimScreenState
    extends ConsumerState<SarfMalzemeTalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _devamEdenYuklendi = false;
  bool _tamamlananYuklendi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BrandedLoadingDialog.show(context);
      }
    });
  }

  void _tryHideLoadingDialog() {
    if (_devamEdenYuklendi && _tamamlananYuklendi) {
      BrandedLoadingDialog.hide(context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dinle: Devam Eden talepler yüklendi mi?
    ref.listen(sarfMalzemeDevamEdenTaleplerProvider, (prev, next) {
      next.when(
        data: (_) {
          if (mounted) {
            setState(() => _devamEdenYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
        loading: () {},
        error: (error, stack) {
          if (mounted) {
            setState(() => _devamEdenYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
      );
    });

    // Dinle: Tamamlanan talepler yüklendi mi?
    ref.listen(sarfMalzemeTamamlananTaleplerProvider, (prev, next) {
      next.when(
        data: (_) {
          if (mounted) {
            setState(() => _tamamlananYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
        loading: () {},
        error: (error, stack) {
          if (mounted) {
            setState(() => _tamamlananYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
      );
    });

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
              'Sarf Malzeme İsteklerini Yönet',
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
              ref.watch(sarfMalzemeDevamEdenTaleplerProvider),
              () => ref.refresh(sarfMalzemeDevamEdenTaleplerProvider.future),
            ),
            _buildTalepListesi(
              ref.watch(sarfMalzemeTamamlananTaleplerProvider),
              () => ref.refresh(sarfMalzemeTamamlananTaleplerProvider.future),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/sarf_malzeme_istek/tur-secim');
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

  Future<void> _deleteSarfMalzemeTalebi(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu sarf malzeme talebini silmek istediğinizden emin misiniz?',
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
      final repository = ref.read(sarfMalzemeRepositoryProvider);
      final result = await repository.sarfMalzemeSil(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(sarfMalzemeDevamEdenTaleplerProvider);
        ref.invalidate(sarfMalzemeTamamlananTaleplerProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Talep başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result is Failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatDate(DateTime date) {
    if (date.year == 1) return '-';
    try {
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return '-';
    }
  }

  Widget _buildTalepListesi(
    AsyncValue<List<SarfMalzemeTalep>> asyncTalepler,
    Future<void> Function() onRefresh,
  ) {
    return asyncTalepler.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: $error'),
                ],
              ),
            ),
          ),
        ),
      ),
      data: (talepler) {
        if (talepler.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: const Center(
                  child: Text(
                    'Talep bulunamadı',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 50,
            ),
            itemCount: talepler.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final talep = talepler[index];
              final tarihStr = _formatDate(talep.olusturmaTarihi);

              return Slidable(
                key: ValueKey(talep.onayKayitId),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    CustomSlidableAction(
                      onPressed: (_) =>
                          _deleteSarfMalzemeTalebi(talep.onayKayitId),
                      backgroundColor: Colors.red,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, size: 36, color: Colors.white),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SarfMalzemeDetayScreen(
                            talepId: talep.onayKayitId,
                          ),
                        ),
                      );
                    },
                    child: InkWell(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SarfMalzemeDetayScreen(
                              talepId: talep.onayKayitId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'S\u00fcre\u00e7 No: ',
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
                                    Row(
                                      children: [
                                        const Text(
                                          'Sarf Malzemesi: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
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
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      talep.aciklama.isEmpty
                                          ? '(...)'
                                          : talep.aciklama,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
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
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: 30,
                              ),
                            ],
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
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/common/widgets/common_appbar_action_button.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_talep.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';

class SatinAlmaTalepYonetimScreen extends ConsumerStatefulWidget {
  const SatinAlmaTalepYonetimScreen({super.key});

  @override
  ConsumerState<SatinAlmaTalepYonetimScreen> createState() =>
      _SatinAlmaTalepYonetimScreenState();
}

class _SatinAlmaTalepYonetimScreenState
    extends ConsumerState<SatinAlmaTalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _tamamlananSeciliDurumlar = {};
  List<String> _tamamlananDurumlar = [];
  Map<int, String> _anaKategoriAdlari = {};
  Map<int, String> _altKategoriAdlari = {};
  bool _anaKategoriYuklendi = false;
  final Set<int> _yuklenenAltAnaIds = {};
  bool _devamEdenYuklendi = false;
  bool _tamamlananYuklendi = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadAnaKategoriAdlariOnce();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BrandedLoadingDialog.show(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dinle: Devam Eden talepler yüklendi mi?
    ref.listen(satinAlmaDevamEdenTaleplerProvider, (prev, next) {
      next.when(
        data: (_) {
          if (mounted) {
            setState(() => _devamEdenYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
        loading: () {
          // Loading durumunda henüz yüklenmedi
        },
        error: (error, stack) {
          // Hata durumunda da yüklenmiş sayılır, dialog kapanmalı
          if (mounted) {
            setState(() => _devamEdenYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
      );
    });

    // Dinle: Tamamlanan talepler yüklendi mi?
    ref.listen(satinAlmaTamamlananTaleplerProvider, (prev, next) {
      next.when(
        data: (_) {
          if (mounted) {
            setState(() => _tamamlananYuklendi = true);
            _tryHideLoadingDialog();
          }
        },
        loading: () {
          // Loading durumunda henüz yüklenmedi
        },
        error: (error, stack) {
          // Hata durumunda da yüklenmiş sayılır, dialog kapanmalı
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
              'Satın Alma İsteklerini Yönet',
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
          actions: _tabController.index == 1
              ? [
                  CommonAppBarActionButton(
                    label: 'Filtrele',
                    onTap: _showTamamlananFilterBottomSheet,
                  ),
                ]
              : [],
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
              ref.watch(satinAlmaDevamEdenTaleplerProvider),
              () => ref.refresh(satinAlmaDevamEdenTaleplerProvider.future),
              tamamlanan: false,
            ),
            _buildTalepListesi(
              ref.watch(satinAlmaTamamlananTaleplerProvider),
              () => ref.refresh(satinAlmaTamamlananTaleplerProvider.future),
              tamamlanan: true,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/satin_alma/ekle');
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

  Future<void> _deleteSatinAlmaTalebi(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu satın alma talebini silmek istediğinize emin misiniz?',
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
      final repo = ref.read(satinAlmaRepositoryProvider);
      final result = await repo.deleteTalep(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(satinAlmaDevamEdenTaleplerProvider);
        ref.invalidate(satinAlmaTamamlananTaleplerProvider);

        _showInfoBottomSheet(context, 'Talep başarıyla silindi');
      } else if (result is Failure) {
        _showInfoBottomSheet(
          context,
          'Silme başarısız: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showInfoBottomSheet(context, 'Hata: $e', isError: true);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  void _tryHideLoadingDialog() {
    if (_devamEdenYuklendi && _tamamlananYuklendi && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          BrandedLoadingDialog.hide(context);
        }
      });
    }
  }

  void _showInfoBottomSheet(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    // Modal bottom sheet bazen Slidable veya dialog kapandıktan hemen sonra
    // çağrılınca çakışabiliyor; bir frame + microtask sonrasına erteliyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.microtask(() {});
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        useRootNavigator: true,
        isDismissible: false,
        enableDrag: false,
        barrierColor: Colors.black54,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isError ? Colors.red[100] : Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError ? Icons.error_rounded : Icons.check_circle,
                    size: 48,
                    color: isError ? Colors.red[600] : Colors.green[600],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: isError ? null : AppColors.primaryGradient,
                    color: isError ? Colors.redAccent : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(sheetContext, rootNavigator: true).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _updateTamamlananDurumlar(List<SatinAlmaTalep> items) {
    final durumSet = <String>{};
    for (final talep in items) {
      if (talep.onayDurumu.isNotEmpty) {
        durumSet.add(talep.onayDurumu);
      }
    }
    final yeni = durumSet.toList()..sort();
    if (yeni.toString() != _tamamlananDurumlar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tamamlananDurumlar = yeni);
      });
    }
  }

  bool _tamamlananFiltreUygunMu(SatinAlmaTalep talep) {
    if (_tamamlananSeciliDurumlar.isEmpty) return true;
    final durum = talep.onayDurumu.isEmpty ? 'Belirsiz' : talep.onayDurumu;
    return _tamamlananSeciliDurumlar.contains(durum);
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
      // sessiz başarısızlık: mevcut isimler yoksa mevcut fallback metni gösterilmeye devam eder
    }
  }

  Future<void> _ensureAltKategoriAdlariFor(Set<int> anaIds) async {
    final toLoad = anaIds.where((id) => !_yuklenenAltAnaIds.contains(id));
    for (final anaId in toLoad) {
      try {
        final liste = await ref.read(
          satinAlmaAltKategorilerProvider(anaId).future,
        );
        if (!mounted) return;
        setState(() {
          for (final alt in liste) {
            _altKategoriAdlari[alt.id] = alt.altKategori;
          }
          _yuklenenAltAnaIds.add(anaId);
        });
      } catch (_) {
        // sessiz geç: alt kategori ismi bulunamazsa mevcut fallback metni gösterilir
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

    // Ana kategori isimleri bir kere yükleniyor; alt kategoriler ihtiyaç oldukça çekiliyor.
    if (!_anaKategoriYuklendi) {
      unawaited(_loadAnaKategoriAdlariOnce());
    }
    if (anaIds.isNotEmpty) {
      unawaited(_ensureAltKategoriAdlariFor(anaIds));
    }
  }

  Future<void> _showTamamlananFilterBottomSheet() async {
    if (_tamamlananDurumlar.isEmpty) return;

    final tempSelected = <String>{..._tamamlananSeciliDurumlar};
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
                child: _tamamlananDurumlar.isEmpty
                    ? const Text('Filtreleyebileceğiniz durum bulunamadı.')
                    : Column(
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
                                  setState(
                                    () => _tamamlananSeciliDurumlar = {},
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Temizle'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._tamamlananDurumlar.map(
                            (durum) => CheckboxListTile(
                              value: tempSelected.contains(durum),
                              activeColor: AppColors.gradientStart,
                              title: Text(durum.isEmpty ? 'Belirsiz' : durum),
                              onChanged: (value) {
                                modalSetState(() {
                                  if (value == true) {
                                    tempSelected.add(durum);
                                  } else {
                                    tempSelected.remove(durum);
                                  }
                                });

                                setState(
                                  () => _tamamlananSeciliDurumlar = {
                                    ...tempSelected,
                                  },
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

  Widget _buildTalepListesi(
    AsyncValue<List<SatinAlmaTalep>> taleplerAsync,
    Future<List<SatinAlmaTalep>> Function() onRefresh, {
    required bool tamamlanan,
  }) {
    return taleplerAsync.when(
      data: (items) {
        _primeKategoriAdlari(items);

        if (tamamlanan) {
          _updateTamamlananDurumlar(items);
        }

        final filtered = tamamlanan
            ? items.where(_tamamlananFiltreUygunMu).toList()
            : items;

        if (filtered.isEmpty) {
          return const Center(child: Text('Talep bulunamadı'));
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
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 50,
            ),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final talep = sorted[index];
              final statusColor = _getStatusColor(talep.onayDurumu);
              final tarihStr = _formatDate(talep.olusturmaTarihi);

              final kategori =
                  _anaKategoriAdlari[talep.satinAlmaAnaKategoriId]?.trim() ??
                  talep.urunKategori.trim();
              final altKategori =
                  _altKategoriAdlari[talep.satinAlmaAltKategoriId]?.trim() ??
                  talep.urunAltKategori.trim();
              final kategoriLabel = [
                kategori,
                altKategori,
              ].where((e) => e.isNotEmpty).join(' - ');

              final isDeleteAvailable =
                  !tamamlanan &&
                  talep.onayDurumu.toLowerCase().contains('onay bekliyor');

              return Slidable(
                key: ValueKey(talep.onayKayitId),
                endActionPane: isDeleteAvailable
                    ? ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          CustomSlidableAction(
                            onPressed: (_) =>
                                _deleteSatinAlmaTalebi(talep.onayKayitId),
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
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
                child: InkWell(
                  onTap: () =>
                      context.push('/satin_alma/detay/${talep.onayKayitId}'),
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
                                const SizedBox(height: 6),
                                Text(
                                  talep.saticiFirma.isEmpty
                                      ? '-'
                                      : talep.saticiFirma,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
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
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            talep.onayDurumu
                                                    .toLowerCase()
                                                    .contains('onay bekliyor')
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
              );
            },
          ),
        );
      },
      // BrandedLoadingDialog zaten global overlay olarak gösteriliyor;
      // ek bir spinner göstermeyelim ki çift yüklenme efekti olmasın.
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hata: $error'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                onRefresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

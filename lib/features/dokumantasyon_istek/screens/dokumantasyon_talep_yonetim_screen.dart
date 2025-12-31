import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_talep_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/common/widgets/common_appbar_action_button.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';

class DokumantasyonTalepYonetimScreen extends ConsumerStatefulWidget {
  const DokumantasyonTalepYonetimScreen({super.key});

  @override
  ConsumerState<DokumantasyonTalepYonetimScreen> createState() =>
      _DokumantasyonTalepYonetimScreenState();
}

class _DokumantasyonTalepYonetimScreenState
    extends ConsumerState<DokumantasyonTalepYonetimScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<_DokumantasyonTalepListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<_DokumantasyonTalepListesiState> _tamamlananKey = GlobalKey();

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
      onPopInvokedWithResult: (didPop, result) {
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
              'Dokümantasyon İsteklerini Yönet',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF014B92),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          ),
          elevation: 0,
          actions: _tabController.index == 0
              ? []
              : [
                  CommonAppBarActionButton(
                    label: 'Filtrele',
                    onTap: () {
                      _tamamlananKey.currentState
                          ?.showFilterBottomSheetPublic();
                    },
                  ),
                ],
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
            _DokumantasyonTalepListesi(key: _devamEdenKey, tip: 0),
            _DokumantasyonTalepListesi(key: _tamamlananKey, tip: 1),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/dokumantasyon/turu_secim'),
          backgroundColor: const Color(0xFF014B92),
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
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
}

class _DokumantasyonTalepListesi extends ConsumerStatefulWidget {
  final int tip; // 0: Devam Eden, 1: Tamamlanan

  const _DokumantasyonTalepListesi({super.key, required this.tip});

  @override
  ConsumerState<_DokumantasyonTalepListesi> createState() =>
      _DokumantasyonTalepListesiState();
}

class _DokumantasyonTalepListesiState
    extends ConsumerState<_DokumantasyonTalepListesi> {
  bool _yenidenEskiye = true;
  Set<String> _selectedDurumlar = {};
  List<String> _availableDurumlar = [];

  void showFilterBottomSheetPublic() {
    if (_availableDurumlar.isEmpty) return;
    _showFilterBottomSheet();
  }

  Future<void> _showFilterBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _availableDurumlar.isEmpty
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
                              setState(() => _selectedDurumlar.clear());
                              Navigator.pop(context);
                            },
                            child: const Text('Temizle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._availableDurumlar.map(
                        (durum) => CheckboxListTile(
                          value: _selectedDurumlar.contains(durum),
                          title: Text(durum.isEmpty ? 'Belirsiz' : durum),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedDurumlar.add(durum);
                              } else {
                                _selectedDurumlar.remove(durum);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _updateAvailableDurumlar(List<Talep> talepler) {
    final durumSet = <String>{};
    for (final talep in talepler) {
      if (talep.onayDurumu.isNotEmpty) {
        durumSet.add(talep.onayDurumu);
      }
    }
    final yeniDurumlar = durumSet.toList()..sort();
    if (yeniDurumlar.toString() != _availableDurumlar.toString()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _availableDurumlar = yeniDurumlar);
      });
    }
  }

  bool _talepFiltrelerineUyuyorMu(Talep talep) {
    final durum = talep.onayDurumu.isEmpty ? 'Belirsiz' : talep.onayDurumu;
    if (_selectedDurumlar.isEmpty) return true;
    return _selectedDurumlar.contains(durum);
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    if (status.contains('Onay')) return Colors.orange;
    if (status.contains('Reddedildi')) return Colors.red;
    if (status.contains('Onaylandı')) return Colors.green;
    return Colors.blue;
  }

  Future<void> _deleteDokumantasyonTalebi(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Talebi Sil'),
        content: const Text(
          'Bu dokümantasyon talebini silmek istediğinize emin misiniz?',
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
      final repo = ref.read(dokumantasyonIstekRepositoryProvider);
      final result = await repo.dokumantasyonIstekSil(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(dokumantasyonDevamEdenTaleplerProvider);
        ref.invalidate(dokumantasyonTamamlananTaleplerProvider);

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

  @override
  Widget build(BuildContext context) {
    final provider = widget.tip == 0
        ? dokumantasyonDevamEdenTaleplerProvider
        : dokumantasyonTamamlananTaleplerProvider;
    final taleplerAsync = ref.watch(provider);

    return taleplerAsync.when(
      data: (data) {
        _updateAvailableDurumlar(data.talepler);

        final filtered =
            data.talepler.where(_talepFiltrelerineUyuyorMu).toList()
              ..sort((a, b) {
                final aDate = _parseDate(a.olusturmaTarihi);
                final bDate = _parseDate(b.olusturmaTarihi);
                return _yenidenEskiye
                    ? bDate.compareTo(aDate)
                    : aDate.compareTo(bDate);
              });

        if (filtered.isEmpty) {
          return const Center(child: Text('Talep bulunamadı'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 50,
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final talep = filtered[index];
              final statusColor = _getStatusColor(talep.onayDurumu);
              final tarihStr = _formatDate(talep.olusturmaTarihi);

              final isDeleteAvailable = talep.onayDurumu.toLowerCase().contains(
                'onay bekliyor',
              );

              return Slidable(
                key: ValueKey(talep.onayKayitID),
                endActionPane: isDeleteAvailable
                    ? ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          CustomSlidableAction(
                            onPressed: (_) =>
                                _deleteDokumantasyonTalebi(talep.onayKayitID),
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
                  builder: (builderContext) => GestureDetector(
                    onTap: () {
                      final slidable = Slidable.of(builderContext);
                      final isClosed =
                          slidable?.actionPaneType.value == ActionPaneType.none;

                      if (!isClosed) {
                        slidable?.close();
                        return;
                      }
                      context.push(
                        '/dokumantasyon/detay/${talep.onayKayitID}',
                        extra: talep.onayTipi,
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      elevation: 2,
                      color:
                          Color.lerp(
                            Theme.of(context).scaffoldBackgroundColor,
                            Colors.white,
                            0.65,
                          ) ??
                          Colors.white,
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
                                        '${talep.onayKayitID}',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF014B92),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (talep.dokumanTuru == null ||
                                            talep.dokumanTuru!.isEmpty)
                                        ? 'A4 Kağıdı İstek'
                                        : 'Dokümantasyon Baskı İstek',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tarihStr,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
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
                                          color: statusColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              talep.onayDurumu.contains('Onay')
                                                  ? Icons.access_time
                                                  : talep.onayDurumu.contains(
                                                      'Reddedildi',
                                                    )
                                                  ? Icons.close
                                                  : Icons.check_circle,
                                              size: 18,
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
                                                  fontSize: 13,
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
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                          ],
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hata: $error'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(provider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

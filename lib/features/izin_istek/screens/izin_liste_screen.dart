import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/talep_yonetim_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turu_secim_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/common/widgets/common_appbar_action_button.dart';
import 'package:esas_v1/common/widgets/talep_filter_bottom_sheet.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';

class IzinListeScreen extends ConsumerStatefulWidget {
  const IzinListeScreen({super.key});

  @override
  ConsumerState<IzinListeScreen> createState() => _IzinListeScreenState();
}

class _IzinListeScreenState extends ConsumerState<IzinListeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GlobalKey'ler liste widget'larına erişim için
  final GlobalKey<_IzinTalepleriListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<_IzinTalepleriListesiState> _tamamlananKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Tab değişikliğinde AppBar'ı yeniden build et
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
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: const Text(
              'İzin İsteklerini Yönet',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => context.go('/'),
          ),
          elevation: 0,
          actions: _tabController.index == 0
              ? [] // Devam Eden tabında filtre ikonunu gizle
              : [
                  // Sıralama ikonları şimdilik gizli - ilerde tekrar etkinleştirilecek
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 4),
                  //   child: InkWell(...sort...)
                  // ),
                  CommonAppBarActionButton(
                    label: 'Filtrele',
                    onTap: () {
                      if (_tabController.index == 0) {
                        _devamEdenKey.currentState
                            ?.showFilterBottomSheetPublic();
                      } else {
                        _tamamlananKey.currentState
                            ?.showFilterBottomSheetPublic();
                      }
                    },
                  ),
                ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.textOnPrimary,
            labelColor: AppColors.textOnPrimary,
            unselectedLabelColor: AppColors.textOnPrimaryMuted,
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
            _IzinTalepleriListesi(key: _devamEdenKey, tip: 0), // Devam Eden
            _IzinTalepleriListesi(key: _tamamlananKey, tip: 1), // Tamamlanan
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(45),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IzinTuruSecimScreen(),
                    ),
                  );
                  if (mounted) {
                    ref.invalidate(onayBekleyenTaleplerProvider);
                    ref.invalidate(onaylananTaleplerProvider);
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                focusElevation: 0,
                hoverElevation: 0,
                highlightElevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                icon: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.textOnPrimary,
                    size: 24,
                  ),
                ),
                label: const Text(
                  'Yeni İstek',
                  style: TextStyle(color: AppColors.textOnPrimary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// İzin Talepleri Listesi Widget'ı - Filtreli
class _IzinTalepleriListesi extends ConsumerStatefulWidget {
  final int tip; // 0: Devam Eden, 1: Tamamlanan

  const _IzinTalepleriListesi({super.key, required this.tip});

  @override
  ConsumerState<_IzinTalepleriListesi> createState() =>
      _IzinTalepleriListesiState();
}

class _IzinTalepleriListesiState extends ConsumerState<_IzinTalepleriListesi> {
  // Filtre değerleri - Çoklu seçim için Set kullanılıyor
  String _selectedSure = 'Tümü';
  final Set<String> _selectedIzinTurleri = {};
  final Set<String> _selectedTalepDurumlari = {};

  // Sıralama: true = yeniden eskiye (varsayılan), false = eskiden yeniye
  bool _yenidenEskiye = true;

  // API'den gelen taleplerdeki izin türlerinin listesi
  List<String> _mevcutIzinTurleri = [];

  // Talep durumu seçenekleri
  final List<String> _talepDurumuSecenekleri = ['Onaylandı', 'Reddedildi'];

  // Süre seçenekleri
  final List<String> _sureSecenekleri = [
    'Tümü',
    '1 Hafta',
    '1 Ay',
    '3 Ay',
    '1 Yıl',
  ];

  // AppBar'dan çağrılacak public metodlar
  void showSiralamaBottomSheetPublic() {
    _showSiralamaBottomSheet(context);
  }

  void showFilterBottomSheetPublic() {
    // Filtrelenecek seçenek yoksa hiçbir tepki verme
    if (_mevcutIzinTurleri.isEmpty && _talepDurumuSecenekleri.isEmpty) {
      return;
    }
    _showFilterOptionsBottomSheet();
  }

  // Süre filtresine göre tarih kontrolü
  bool _sureFiltresindenGeciyorMu(String olusturmaTarihi) {
    if (_selectedSure == 'Tümü') return true;

    try {
      final tarih = DateTime.parse(olusturmaTarihi);
      final simdi = DateTime.now();
      final fark = simdi.difference(tarih);

      switch (_selectedSure) {
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

  // İzin türü filtresine göre kontrol - Çoklu seçim destekli
  bool _izinTuruFiltresindenGeciyorMu(String? izinTuru) {
    if (_selectedIzinTurleri.isEmpty) return true;
    if (izinTuru == null || izinTuru.isEmpty) return false;

    return _selectedIzinTurleri.any(
      (tur) => izinTuru.toLowerCase().contains(tur.toLowerCase()),
    );
  }

  // Talep durumu filtresine göre kontrol
  bool _talepDurumuFiltresindenGeciyorMu(String? onayDurumu) {
    if (_selectedTalepDurumlari.isEmpty) return true;
    if (onayDurumu == null || onayDurumu.isEmpty) return false;

    return _selectedTalepDurumlari.any(
      (durum) => onayDurumu.toLowerCase().contains(durum.toLowerCase()),
    );
  }

  // Sıralama BottomSheet
  void _showSiralamaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Sıralama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                'Eskiden Yeniye',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: !_yenidenEskiye
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: !_yenidenEskiye
                      ? AppColors.primary
                      : AppColors.textPrimary87,
                ),
              ),
              trailing: !_yenidenEskiye
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _yenidenEskiye = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text(
                'Yeniden Eskiye',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _yenidenEskiye
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _yenidenEskiye
                      ? AppColors.primary
                      : AppColors.textPrimary87,
                ),
              ),
              trailing: _yenidenEskiye
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _yenidenEskiye = true);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Tüm filtre seçeneklerini gösteren BottomSheet - Multi-page
  void _showFilterOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => TalepFilterBottomSheet(
        durationOptions: _sureSecenekleri,
        initialSelectedDuration: _selectedSure,
        requestTypeOptions: _mevcutIzinTurleri,
        initialSelectedRequestTypes: _selectedIzinTurleri,
        requestTypeTitle: 'İzin Türü',
        statusOptions: _talepDurumuSecenekleri,
        initialSelectedStatuses: _selectedTalepDurumlari,
        showStatusSection: widget.tip == 1,
        onApply: (selections) {
          setState(() {
            _selectedSure = selections.selectedDuration;
            _selectedIzinTurleri
              ..clear()
              ..addAll(selections.selectedRequestTypes);
            _selectedTalepDurumlari
              ..clear()
              ..addAll(selections.selectedStatuses);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = widget.tip == 0
        ? ref.watch(onayBekleyenTaleplerProvider)
        : ref.watch(onaylananTaleplerProvider);

    return asyncValue.when(
      loading: () => const Center(
        child: SizedBox(
          width: 153,
          height: 153,
          child: BrandedLoadingIndicator(size: 153, strokeWidth: 24),
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Hata: ${error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (widget.tip == 0) {
                  ref.invalidate(onayBekleyenTaleplerProvider);
                } else {
                  ref.invalidate(onaylananTaleplerProvider);
                }
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (response) {
        // Mevcut izin türlerinin listesini güncelle (unique ve sıralı)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final izinTurleri =
              response.talepler
                  .map((t) => t.izinTuru)
                  .where((tur) => tur.isNotEmpty)
                  .cast<String>()
                  .toSet()
                  .toList()
                ..sort();
          if (_mevcutIzinTurleri.length != izinTurleri.length ||
              !_mevcutIzinTurleri.every((t) => izinTurleri.contains(t))) {
            setState(() {
              _mevcutIzinTurleri = izinTurleri;
            });
          }
        });

        // Filtrelenmiş liste
        var filteredTalepler = response.talepler.where((talep) {
          final surePassed = _sureFiltresindenGeciyorMu(talep.olusturmaTarihi);
          final izinTuruPassed = _izinTuruFiltresindenGeciyorMu(talep.izinTuru);
          // Talep durumu filtresi sadece Tamamlanan tab'da (tip == 1) uygulanır
          final talepDurumuPassed = widget.tip == 1
              ? _talepDurumuFiltresindenGeciyorMu(talep.onayDurumu)
              : true;
          return surePassed && izinTuruPassed && talepDurumuPassed;
        }).toList();

        // Sıralama uygula
        filteredTalepler.sort((a, b) {
          try {
            final tarihA = DateTime.parse(a.olusturmaTarihi);
            final tarihB = DateTime.parse(b.olusturmaTarihi);
            return _yenidenEskiye
                ? tarihB.compareTo(tarihA) // Yeniden eskiye
                : tarihA.compareTo(tarihB); // Eskiden yeniye
          } catch (e) {
            return 0;
          }
        });

        if (filteredTalepler.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              if (widget.tip == 0) {
                ref.invalidate(onayBekleyenTaleplerProvider);
              } else {
                ref.invalidate(onaylananTaleplerProvider);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(child: Container()),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (widget.tip == 0) {
              ref.invalidate(onayBekleyenTaleplerProvider);
            } else {
              ref.invalidate(onaylananTaleplerProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 80,
            ),
            itemCount: filteredTalepler.length,
            itemBuilder: (context, index) {
              final talep = filteredTalepler[index];
              return _IzinTalepKarti(
                talep: talep,
                onDelete: () => _deleteIzinTalebi(talep.onayKayitId),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteIzinTalebi(int id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İzin Talebini İptal Et'),
        content: const Text(
          'Bu izin talebini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final repository = ref.read(talepYonetimRepositoryProvider);
      final result = await repository.izinIstekSil(id: id);

      if (!mounted) return;

      if (result is Success) {
        ref.invalidate(onayBekleyenTaleplerProvider);
        ref.invalidate(onaylananTaleplerProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İzin talebi başarıyla iptal edildi'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (result is Failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${result.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// İzin Talep Kartı Widget'ı
class _IzinTalepKarti extends StatelessWidget {
  final dynamic talep;
  final VoidCallback onDelete;

  const _IzinTalepKarti({required this.talep, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final rawStatus = talep.onayDurumu;
    final statusColor = TalepYonetimHelper.getStatusColor(rawStatus);
    final statusIcon = TalepYonetimHelper.getStatusIcon(rawStatus);
    final statusText = TalepYonetimHelper.getStatusText(rawStatus);


    String tarihStr = '';
    try {
      final date = DateTime.parse(talep.olusturmaTarihi);
      tarihStr = '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      tarihStr = 'Bilinmiyor';
    }

    final izinTuru =
        (talep.izinTuru != null && talep.izinTuru.toString().isNotEmpty)
        ? talep.izinTuru
        : 'İzin Türü Bilinmiyor';

    final isDeleteAvailable =
        rawStatus.toLowerCase().contains('onay bekliyor') ||
        rawStatus.toLowerCase().contains('bekliyor');

    return Slidable(
      key: ValueKey(talep.onayKayitId),
      endActionPane: isDeleteAvailable
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                CustomSlidableAction(
                  onPressed: (context) => onDelete(),
                  backgroundColor: AppColors.error,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          size: 40,
                          color: AppColors.textOnPrimary,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'İzni İptal Et',
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 16,
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
        builder: (BuildContext builderContext) {
          return GestureDetector(
            onTap: () {
              final slidable = Slidable.of(builderContext);
              final isClosed =
                  slidable?.actionPaneType.value == ActionPaneType.none;

              if (isClosed) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => Scaffold(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      body: IzinIstekDetayScreen(
                        talepId: talep.onayKayitId,
                        onayTipi: talep.onayTipi,
                      ),
                    ),
                  ),
                );
              } else {
                slidable?.close();
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              elevation: 2,
              color:
                  Color.lerp(
                    Theme.of(context).scaffoldBackgroundColor,
                    AppColors.textOnPrimary,
                    0.65,
                  ) ??
                  AppColors.textOnPrimary,
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
                                offset: const Offset(30, 0),
                                child: Container(
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
                                        statusIcon,
                                        size: 18,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
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
                          const SizedBox(height: 4),
                          Text(
                            izinTuru,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tarihStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 30,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


}

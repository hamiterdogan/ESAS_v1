import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/talep/screens/widgets/talep_karti.dart';
import 'package:esas_v1/common/widgets/shimmer_loading_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// İsteklerim tab içeriği - Devam Eden ve Tamamlanan tab'ları ile
class IsteklerimContent extends ConsumerStatefulWidget {
  final VoidCallback? onFilterStateChanged;

  const IsteklerimContent({super.key, this.onFilterStateChanged});

  @override
  ConsumerState<IsteklerimContent> createState() => IsteklerimContentState();
}

class IsteklerimContentState extends ConsumerState<IsteklerimContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GlobalKey'ler liste widget'larına erişim için
  final GlobalKey<IsteklerimListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<IsteklerimListesiState> _tamamlananKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Tab değişiminde provider invalidate etmeyerek flicker'ı azalt
        // Güncelleme pull-to-refresh ve detail sonrası refresh ile devam eder
        widget.onFilterStateChanged?.call();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// AppBar'dan çağrılacak sıralama metodu
  void showSiralamaBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showSiralamaBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showSiralamaBottomSheetPublic();
    }
  }

  /// AppBar'dan çağrılacak filtreleme metodu
  void showFilterBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showFilterBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showFilterBottomSheetPublic();
    }
  }

  bool get isFilterActive {
    if (_tabController.index == 0) {
      return _devamEdenKey.currentState?.isFilterActive ?? false;
    } else {
      return _tamamlananKey.currentState?.isFilterActive ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.textOnPrimary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.gradientStart,
            labelColor: AppColors.gradientStart,
            unselectedLabelColor: Colors.grey,
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
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Devam Eden
              // Devam Eden
              IsteklerimListesi(
                key: _devamEdenKey,
                tip: 0,
                onFilterStateChanged: widget.onFilterStateChanged,
              ),
              // Tamamlanan
              IsteklerimListesi(
                key: _tamamlananKey,
                tip: 1,
                onFilterStateChanged: widget.onFilterStateChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// İsteklerim listesi widget'ı - Filtreli
class IsteklerimListesi extends ConsumerStatefulWidget {
  final int tip;

  final VoidCallback? onFilterStateChanged;

  const IsteklerimListesi({
    super.key,
    required this.tip,
    this.onFilterStateChanged,
  });

  @override
  ConsumerState<IsteklerimListesi> createState() => IsteklerimListesiState();
}

class IsteklerimListesiState extends ConsumerState<IsteklerimListesi> {
  // Filtre değerleri - Çoklu seçim için Set kullanılıyor
  String _selectedSure = '1 Ay';
  final Set<String> _selectedTalepTurleri = {};
  final Set<String> _selectedTalepDurumlari = {};

  // Bilgi Teknolojileri onayKayitId cache
  Set<int> _bilgiTekOnayKayitIds = <int>{};

  // PERFORMANCE: Filtreleme cache - Her build'de yeniden filtreleme yerine
  // sadece veri veya filtre değiştiğinde yeniden hesaplanır
  List<Talep> _cachedFilteredTalepler = [];
  int _lastFilteredDataHash = 0;
  String _lastFilterHash = '';

  final ItemScrollController _itemScrollController = ItemScrollController();
  static const int _pageSize = 20;
  int _lastTotal = -1;
  ProviderSubscription<PaginatedTalepState>? _prefetchSub;

  int _loadingSkeletonCount() {
    if (_lastTotal > 0) {
      return _lastTotal.clamp(1, 5);
    }
    return 2;
  }

  // Sıralama: true = yeniden eskiye (varsayılan), false = eskiden yeniye
  bool _yenidenEskiye = true;

  // API'den gelen taleplerdeki talep türlerinin listesi
  List<String> _mevcutTalepTurleri = [];

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

  // Filtre sayfası durumu - null = ana liste, 'talepTuru' = talep türü sayfası, vb.
  String? _currentFilterPage;

  bool get isFilterActive =>
      (_selectedSure != 'Tümü' && _selectedSure != '1 Ay') ||
      _selectedTalepTurleri.isNotEmpty ||
      _selectedTalepDurumlari.isNotEmpty;

  String _resolveTeknikBilgiLabel(Talep talep) {
    final onayTipiLower = talep.onayTipi.toLowerCase();
    if (!onayTipiLower.contains('teknik destek')) {
      return talep.onayTipi;
    }

    final hizmetTuruLower = (talep.hizmetTuru ?? '').toLowerCase().trim();

    if (hizmetTuruLower.contains('bilgi teknoloj')) {
      return 'Bilgi Teknolojileri';
    }

    if (hizmetTuruLower.contains('teknik hizmet') ||
        hizmetTuruLower.contains('iç hizmet') ||
        hizmetTuruLower.contains('ic hizmet')) {
      return 'Teknik Destek';
    }

    if (_bilgiTekOnayKayitIds.contains(talep.onayKayitId)) {
      return 'Bilgi Teknolojileri';
    }

    return 'Teknik Destek';
  }

  @override
  void initState() {
    super.initState();

    // Provider now auto-loads in build() method, no need for manual loadInitial

    final provider = widget.tip == 0
        ? devamEdenIsteklerimProvider
        : tamamlananIsteklerimProvider;

    _prefetchSub = ref.listenManual<PaginatedTalepState>(provider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      if (!next.isLoading &&
          !next.isInitialLoading &&
          next.hasMore &&
          next.talepler.isNotEmpty &&
          next.talepler.length < _pageSize) {
        ref.read(provider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _prefetchSub?.close();
    super.dispose();
  }

  bool _handleScrollNotification(
    ScrollNotification notification,
    int listLength,
  ) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      final provider = widget.tip == 0
          ? devamEdenIsteklerimProvider
          : tamamlananIsteklerimProvider;
      ref.read(provider.notifier).loadMore();
    }
    return false;
  }

  /// Scroll to index when returning from detail screen
  /// Called via TalepKarti.onReturnIndex callback
  void _scrollToIndex(int index, int maxLength) {
    if (index < 0 || index >= maxLength) return;
    if (!_itemScrollController.isAttached) return;

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  /// Hata mesajlarını kullanıcı dostu hale getir
  String _getHataBasligi(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('timeout') || lowerError.contains('time out')) {
      return 'Bağlantı Zaman Aşımı';
    } else if (lowerError.contains('connection') ||
        lowerError.contains('network')) {
      return 'Bağlantı Hatası';
    } else if (lowerError.contains('401') ||
        lowerError.contains('unauthorized')) {
      return 'Oturum Süresi Doldu';
    } else if (lowerError.contains('500') || lowerError.contains('server')) {
      return 'Sunucu Hatası';
    }
    return 'Bir Hata Oluştu';
  }

  String _getHataMesaji(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('timeout') || lowerError.contains('time out')) {
      return 'Sunucuya bağlanırken zaman aşımı oluştu. İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
    } else if (lowerError.contains('connection') ||
        lowerError.contains('network')) {
      return 'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.';
    } else if (lowerError.contains('401') ||
        lowerError.contains('unauthorized')) {
      return 'Oturumunuzun süresi doldu. Lütfen uygulamayı yeniden başlatın.';
    } else if (lowerError.contains('500') || lowerError.contains('server')) {
      return 'Sunucu geçici olarak hizmet veremiyor. Lütfen daha sonra tekrar deneyin.';
    }
    return 'Veriler yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.';
  }

  Widget _buildTalepList(
    BuildContext context,
    PaginatedTalepState state,
    Set<int> bilgiTekOnayKayitIds,
  ) {
    final talepler = state.talepler;

    // Side effect: Update filter lists - only if talepler length changed
    // Use microtask instead of postFrameCallback for less overhead
    if (talepler.length != _lastTotal) {
      _lastTotal = talepler.length;
      Future.microtask(() {
        if (!mounted) return;
        final talepTurleri =
            talepler
                .map((t) => t.onayTipi)
                .where((tur) => tur.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        if (!_listEquals(_mevcutTalepTurleri, talepTurleri)) {
          setState(() {
            _mevcutTalepTurleri = talepTurleri;
          });
        }
      });
    }

    // PERFORMANCE: Memoized filtreleme - sadece veri veya filtre değiştiğinde çalışır
    final filteredTalepler = _getFilteredAndSortedTalepler(talepler);

    if (filteredTalepler.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bilgiTeknolojileriOnayKayitIdSetProvider);
          final provider = widget.tip == 0
              ? devamEdenIsteklerimProvider
              : tamamlananIsteklerimProvider;
          await ref.read(provider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    'Yenilemek için ekranı aşağı çekin',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(bilgiTeknolojileriOnayKayitIdSetProvider);
        final provider = widget.tip == 0
            ? devamEdenIsteklerimProvider
            : tamamlananIsteklerimProvider;
        await ref.read(provider.notifier).refresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          _handleScrollNotification(notification, filteredTalepler.length);
          return false;
        },
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120,
          ),
          // +1 for loading indicator
          itemCount: filteredTalepler.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading spinner
            if (index == filteredTalepler.length) {
              // Eğer loading spinner görünüyorsa ve henüz yükleme yapılmıyorsa,
              // yeni verileri yükle (Auto-pagination for short lists)
              if (!state.isLoading && state.hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final provider = widget.tip == 0
                      ? devamEdenIsteklerimProvider
                      : tamamlananIsteklerimProvider;
                  ref.read(provider.notifier).loadMore();
                });
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: TalepKartiShimmer()),
              );
            }

            final talep = filteredTalepler[index];

            return RepaintBoundary(
              child: TalepKarti(
                talep: talep,
                displayOnayTipi: _resolveTeknikBilgiLabel(talep),
                talepList: filteredTalepler,
                indexInList: index,
                onReturnIndex: (returnIndex) {
                  _scrollToIndex(returnIndex, filteredTalepler.length);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// AppBar'dan çağrılacak public metodlar
  void showSiralamaBottomSheetPublic() {
    _showSiralamaBottomSheet(context);
  }

  void showFilterBottomSheetPublic() {
    // Filtrelenecek seçenek yoksa hiçbir tepki verme
    if (_mevcutTalepTurleri.isEmpty && _talepDurumuSecenekleri.isEmpty) {
      return;
    }
    _showFilterOptionsBottomSheet();
  }

  // Listeleri karşılaştırma helper
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// PERFORMANCE: Memoized filtreleme ve sıralama
  /// Sadece veri veya filtre değiştiğinde yeniden hesaplanır
  List<Talep> _getFilteredAndSortedTalepler(List<Talep> taleplerListesi) {
    // Cache key oluştur
    final filterHash =
        '$_selectedSure|'
        '${_selectedTalepTurleri.join(',')}|'
        '${_selectedTalepDurumlari.join(',')}|'
        '$_yenidenEskiye';
    final dataHash = taleplerListesi.length;

    // Cache hit - veri ve filtre değişmemişse cache'den dön
    if (dataHash == _lastFilteredDataHash && filterHash == _lastFilterHash) {
      return _cachedFilteredTalepler;
    }

    // Cache miss - yeniden hesapla
    _lastFilteredDataHash = dataHash;
    _lastFilterHash = filterHash;

    List<Talep> result;

    // Filtre yoksa ve varsayılan sıralama ise direkt kullan
    if (!isFilterActive && _yenidenEskiye) {
      result = taleplerListesi;
    } else {
      // Pre-calculate filter cutoff
      final now = DateTime.now();
      final sureCutoff = _getSureCutoffDate(now);

      // Filtreleme - PERFORMANCE: cached parsedOlusturmaTarihi kullanılıyor
      result = taleplerListesi.where((talep) {
        // Date filter
        if (sureCutoff != null) {
          if (talep == null ||
              talep.parsedOlusturmaTarihi.isBefore(sureCutoff)) {
            return false;
          }
        }

        // Talep türü filtresi
        if (_selectedTalepTurleri.isNotEmpty &&
            (talep == null ||
                !_selectedTalepTurleri.contains(talep.onayTipi))) {
          return false;
        }

        // Talep durumu filtresi (sadece Tamamlanan tab)
        if (widget.tip == 1 &&
            _selectedTalepDurumlari.isNotEmpty &&
            (talep == null ||
                !_talepDurumuFiltresindenGeciyorMu(talep.onayDurumu))) {
          return false;
        }

        return true;
      }).toList();

      // Sıralama - PERFORMANCE: cached parsedOlusturmaTarihi kullanılıyor
      result.sort((a, b) {
        if (a == null || b == null) return 0;
        return _yenidenEskiye
            ? b.parsedOlusturmaTarihi.compareTo(a.parsedOlusturmaTarihi)
            : a.parsedOlusturmaTarihi.compareTo(b.parsedOlusturmaTarihi);
      });
    }

    _cachedFilteredTalepler = result;
    return result;
  }

  // Süre filtresi için cutoff tarihini hesapla - her filtreleme için tekrar hesaplama yerine bir kere
  DateTime? _getSureCutoffDate(DateTime now) {
    switch (_selectedSure) {
      case '1 Hafta':
        return now.subtract(const Duration(days: 7));
      case '1 Ay':
        return now.subtract(const Duration(days: 30));
      case '3 Ay':
        return now.subtract(const Duration(days: 90));
      case '1 Yıl':
        return now.subtract(const Duration(days: 365));
      default:
        return null; // Tümü - no cutoff
    }
  }

  // Talep durumu filtresine göre kontrol
  bool _talepDurumuFiltresindenGeciyorMu(String onayDurumu) {
    if (_selectedTalepDurumlari.isEmpty) return true;
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
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(top: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 20,
        ),
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
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              trailing: !_yenidenEskiye
                  ? const Icon(Icons.check, color: AppColors.gradientStart)
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
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              trailing: _yenidenEskiye
                  ? const Icon(Icons.check, color: AppColors.gradientStart)
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
    setState(() => _currentFilterPage = null);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          margin: const EdgeInsets.only(top: 20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height - 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (_currentFilterPage != null)
                      InkWell(
                        onTap: () {
                          setModalState(() => _currentFilterPage = null);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, size: 20),
                            SizedBox(width: 8),
                            Text('Geri', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 64),
                    const Spacer(),
                    Text(
                      _currentFilterPage == null
                          ? 'Filtrele'
                          : _getFilterTitle(_currentFilterPage!),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_currentFilterPage == null)
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _currentFilterPage = null;
                            _selectedSure = '1 Ay';
                            _selectedTalepTurleri.clear();
                            _selectedTalepDurumlari.clear();
                          });

                          // Reset Date Filter in Provider
                          final provider = widget.tip == 0
                              ? devamEdenIsteklerimProvider
                              : tamamlananIsteklerimProvider;

                          // Reset to default (null will use provider default of 30 days)
                          ref.read(provider.notifier).updateDateFilter(null);

                          // PERFORMANCE: setState kaldırıldı - modal state yeterli
                          widget.onFilterStateChanged?.call();
                        },
                        child: const Text(
                          'Tüm filtreleri temizle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gradientStart,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation =
                        Tween<Offset>(
                          begin: const Offset(1.0, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        );
                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  child: _currentFilterPage == null
                      ? _buildFilterMainPage(setModalState)
                      : _buildFilterDetailPage(
                          _currentFilterPage!,
                          setModalState,
                        ),
                ),
              ),
              if (_currentFilterPage == null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 50,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply Date Filter to Provider
                        final provider = widget.tip == 0
                            ? devamEdenIsteklerimProvider
                            : tamamlananIsteklerimProvider;

                        DateTime? startDate;
                        switch (_selectedSure) {
                          case '1 Hafta':
                            startDate = DateTime.now().subtract(
                              const Duration(days: 7),
                            );
                            break;
                          case '1 Ay':
                            startDate = DateTime.now().subtract(
                              const Duration(days: 30),
                            );
                            break;
                          case '3 Ay':
                            startDate = DateTime.now().subtract(
                              const Duration(days: 90),
                            );
                            break;
                          case '1 Yıl':
                            startDate = DateTime.now().subtract(
                              const Duration(days: 365),
                            );
                            break;
                          case 'Tümü':
                          default:
                            startDate = DateTime(2000);
                            break;
                        }

                        // Update provider (triggers API call if changed)
                        ref
                            .read(provider.notifier)
                            .updateDateFilter(
                              startDate.toUtc().toIso8601String(),
                            );

                        // PERFORMANCE: Çift setState kaldırıldı, modal kapanınca rebuild olur
                        widget.onFilterStateChanged?.call();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Uygula',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentFilterPage != null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 50,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setModalState(() {
                            _currentFilterPage = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
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
                            color: AppColors.textOnPrimary,
                          ),
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
  }

  String _getFilterTitle(String key) {
    switch (key) {
      case 'talepTuru':
        return 'Talep Türü';
      case 'sure':
        return 'Süre';
      case 'talepDurumu':
        return 'Talep Durumu';
      default:
        return 'Filtre';
    }
  }

  Widget _buildFilterMainPage(StateSetter setModalState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterMainItem(
            title: 'Talep Türü',
            selectedValue: _selectedTalepTurleri.isEmpty
                ? 'Tümü'
                : _selectedTalepTurleri.join(', '),
            onTap: () => setModalState(() => _currentFilterPage = 'talepTuru'),
          ),
          _buildFilterMainItem(
            title: 'Süre',
            selectedValue: _selectedSure,
            onTap: () => setModalState(() => _currentFilterPage = 'sure'),
          ),
          if (widget.tip == 1)
            _buildFilterMainItem(
              title: 'Talep Durumu',
              selectedValue: _selectedTalepDurumlari.isEmpty
                  ? 'Tümü'
                  : _selectedTalepDurumlari.join(', '),
              onTap: () =>
                  setModalState(() => _currentFilterPage = 'talepDurumu'),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterMainItem({
    required String title,
    required String selectedValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (selectedValue != 'Tümü') ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gradientStart,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDetailPage(String filterType, StateSetter setModalState) {
    switch (filterType) {
      case 'talepTuru':
        return _buildTalepTuruFilterDetailPage(setModalState);
      case 'sure':
        return _buildSureFilterDetailPage(setModalState);
      case 'talepDurumu':
        return _buildTalepDurumuFilterDetailPage(setModalState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTalepTuruFilterDetailPage(StateSetter setModalState) {
    if (_mevcutTalepTurleri.isEmpty) {
      return const Center(child: Text('Henüz talep türü bilgisi yok'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedTalepTurleri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedTalepTurleri.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.gradientStart),
                  ),
                ),
              ),
            ),
          ..._mevcutTalepTurleri.map(
            (tur) => CheckboxListTile(
              dense: true,
              title: Text(
                tur,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _selectedTalepTurleri.contains(tur)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedTalepTurleri.contains(tur)
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              value: _selectedTalepTurleri.contains(tur),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: AppColors.textTertiary, width: 1.5),
              onChanged: (bool? value) {
                setModalState(() {
                  if (value == true) {
                    _selectedTalepTurleri.add(tur);
                  } else {
                    _selectedTalepTurleri.remove(tur);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSureFilterDetailPage(StateSetter setModalState) {
    return SingleChildScrollView(
      child: Column(
        children: _sureSecenekleri
            .map(
              (secenek) => ListTile(
                dense: true,
                title: Text(
                  secenek,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: secenek == _selectedSure
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: secenek == _selectedSure
                        ? AppColors.gradientStart
                        : AppColors.textPrimary87,
                  ),
                ),
                trailing: secenek == _selectedSure
                    ? const Icon(
                        Icons.check,
                        color: AppColors.gradientStart,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  setModalState(() => _selectedSure = secenek);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTalepDurumuFilterDetailPage(StateSetter setModalState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedTalepDurumlari.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedTalepDurumlari.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.gradientStart),
                  ),
                ),
              ),
            ),
          ..._talepDurumuSecenekleri.map(
            (secenek) => CheckboxListTile(
              dense: true,
              title: Text(
                secenek,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _selectedTalepDurumlari.contains(secenek)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedTalepDurumlari.contains(secenek)
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              value: _selectedTalepDurumlari.contains(secenek),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: AppColors.textTertiary, width: 1.5),
              onChanged: (bool? value) {
                setModalState(() {
                  if (value == true) {
                    _selectedTalepDurumlari.add(secenek);
                  } else {
                    _selectedTalepDurumlari.remove(secenek);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bilgi Teknolojileri ID'lerini güvenli şekilde izle - non-blocking
    // Use previous value during loading to prevent shimmer flicker
    final bilgiTekAsyncValue = ref.watch(
      bilgiTeknolojileriOnayKayitIdSetProvider,
    );

    // Cache the IDs locally when available
    if (bilgiTekAsyncValue.hasValue) {
      _bilgiTekOnayKayitIds = bilgiTekAsyncValue.value!;
    }

    final provider = widget.tip == 0
        ? devamEdenIsteklerimProvider
        : tamamlananIsteklerimProvider;

    final state = ref.watch(provider);

    // DEBUG LOG
    if (kDebugMode) {
      print(
        '🖥️ [IsteklerimListesi tip:${widget.tip}] BUILD - isInitialLoading:${state.isInitialLoading}, isLoading:${state.isLoading}, talepler:${state.talepler.length}, error:${state.errorMessage}',
      );
    }

    if (state.errorMessage != null && state.talepler.isEmpty) {
      if (kDebugMode)
        print('🖥️ [IsteklerimListesi tip:${widget.tip}] SHOWING ERROR STATE');
      return RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bilgiTeknolojileriOnayKayitIdSetProvider);
          await ref.read(provider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getHataBasligi(state.errorMessage!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getHataMesaji(state.errorMessage!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(
                          bilgiTeknolojileriOnayKayitIdSetProvider,
                        );
                        ref.read(provider.notifier).refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (state.isInitialLoading) {
      if (kDebugMode) {
        print('🖥️ [IsteklerimListesi tip:${widget.tip}] SHOWING SHIMMER');
      }
      return ListShimmer(itemCount: _loadingSkeletonCount());
    }

    if (kDebugMode) {
      print(
        '🖥️ [IsteklerimListesi tip:${widget.tip}] SHOWING LIST with ${state.talepler.length} items',
      );
    }
    // Use cached IDs immediately - don't wait for provider to load
    return _buildTalepList(context, state, _bilgiTekOnayKayitIds);
  }
}

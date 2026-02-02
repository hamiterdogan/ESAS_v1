import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/talep/screens/widgets/gelen_kutusu_karti.dart';
import 'package:esas_v1/common/widgets/shimmer_loading_widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Gelen Kutusu tab içeriği - Devam Eden ve Tamamlanan tab'ları ile
class GelenKutusuContent extends ConsumerStatefulWidget {
  final VoidCallback? onFilterStateChanged;

  const GelenKutusuContent({super.key, this.onFilterStateChanged});

  @override
  ConsumerState<GelenKutusuContent> createState() => GelenKutusuContentState();
}

class GelenKutusuContentState extends ConsumerState<GelenKutusuContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GlobalKey'ler liste widget'larına erişim için
  final GlobalKey<GelenKutusuListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<GelenKutusuListesiState> _tamamlananKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
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
              // Devam Eden (tip: 2)
              // Devam Eden (tip: 2)
              GelenKutusuListesi(
                key: _devamEdenKey,
                tip: 2,
                onFilterStateChanged: widget.onFilterStateChanged,
              ),
              // Tamamlanan (tip: 3)
              GelenKutusuListesi(
                key: _tamamlananKey,
                tip: 3,
                onFilterStateChanged: widget.onFilterStateChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gelen Kutusu listesi widget'ı - Filtreli
class GelenKutusuListesi extends ConsumerStatefulWidget {
  final int tip;
  final VoidCallback? onFilterStateChanged;

  const GelenKutusuListesi({
    super.key,
    required this.tip,
    this.onFilterStateChanged,
  });

  @override
  ConsumerState<GelenKutusuListesi> createState() => GelenKutusuListesiState();
}

class GelenKutusuListesiState extends ConsumerState<GelenKutusuListesi> {
  // Sıralama: true = yeniden eskiye (varsayılan), false = eskiden yeniye
  bool _yenidenEskiye = true;

  // Filtre sayfası durumu - null = ana liste, 'talepTuru' = talep türü sayfası, vb.
  String? _currentFilterPage;

  // Filtre değerleri - Çoklu seçim için Set kullanılıyor
  final Set<String> _selectedTalepTurleri = {};
  final Set<String> _selectedTalepEdenler = {};
  String _selectedTalepTarihi = 'Tümü';

  // API'den gelen taleplerdeki "Talep Eden" kişilerin listesi
  List<String> _talepEdenKisiler = [];

  // API'den gelen taleplerdeki görevlerin listesi
  List<String> _mevcutGorevler = [];

  // API'den gelen taleplerdeki talep türlerinin listesi
  List<String> _mevcutTalepTurleri = [];

  // API'den gelen taleplerdeki görev yerlerinin listesi
  List<String> _mevcutGorevYerleri = [];

  // Talep tarihi (süre) seçenekleri
  final List<String> _talepTarihiSecenekleri = [
    'Tümü',
    '1 Hafta',
    '1 Ay',
    '3 Ay',
    '1 Yıl',
  ];

  // Talep durumu seçenekleri
  final List<String> _talepDurumuSecenekleri = ['Onaylandı', 'Reddedildi'];

  // Seçilen talep durumları - Çoklu seçim
  final Set<String> _selectedTalepDurumlari = {};

  // Seçilen görevler - Çoklu seçim (String olarak görev adı)
  final Set<String> _selectedGorevler = {};

  // Scroll controller for indexed scrolling
  final ItemScrollController _itemScrollController = ItemScrollController();
  ProviderSubscription<PaginatedTalepState>? _prefetchSub;

  // Cache for preventing repeated filter calculations
  int _lastTotal = -1;

  // Seçilen görev yerleri - Çoklu seçim (String olarak görev yeri adı)

  final Set<String> _selectedGorevYerleri = {};

  // Bilgi Teknolojileri ID'lerini cache'le
  Set<int> _bilgiTekOnayKayitIds = {};

  // PERFORMANCE: Filtreleme cache - Her build'de yeniden filtreleme yerine
  // sadece veri veya filtre değiştiğinde yeniden hesaplanır
  List<Talep> _cachedFilteredTalepler = [];
  int _lastFilteredDataHash = 0;
  String _lastFilterHash = '';

  // Isolate State
  List<Talep>? _displayedTalepler;
  bool _isFiltering = false;

  bool get isFilterActive =>
      _selectedTalepTurleri.isNotEmpty ||
      _selectedTalepEdenler.isNotEmpty ||
      _selectedTalepTarihi != 'Tümü' ||
      _selectedTalepDurumlari.isNotEmpty ||
      _selectedGorevler.isNotEmpty ||
      _selectedGorevYerleri.isNotEmpty;

  @override
  void initState() {
    super.initState();

    // Provider now auto-loads in build() method, no need for manual loadInitial

    final provider = widget.tip == 2
        ? devamEdenGelenKutusuProvider
        : tamamlananGelenKutusuProvider;

    _prefetchSub = ref.listenManual<PaginatedTalepState>(provider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      if (!next.isLoading &&
          !next.isInitialLoading &&
          next.hasMore &&
          next.talepler.isNotEmpty &&
          next.talepler.length < 20) {
        ref.read(provider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _prefetchSub?.close();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      final provider = widget.tip == 2
          ? devamEdenGelenKutusuProvider
          : tamamlananGelenKutusuProvider;
      ref.read(provider.notifier).loadMore();
    }
    return false;
  }

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

  /// AppBar'dan çağrılacak public metodlar
  void showSiralamaBottomSheetPublic() {
    _showSiralamaBottomSheet();
  }

  void showFilterBottomSheetPublic() {
    _showFilterOptionsBottomSheet();
  }

  // Sıralama BottomSheet
  void _showSiralamaBottomSheet() {
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

  // Talep türü filtresine göre kontrol
  bool _talepTuruFiltresindenGeciyorMu(String onayTipi) {
    if (_selectedTalepTurleri.isEmpty) return true;
    return _selectedTalepTurleri.any(
      (tur) => onayTipi.toLowerCase().contains(tur.toLowerCase()),
    );
  }

  // Talep eden filtresine göre kontrol
  bool _talepEdenFiltresindenGeciyorMu(String olusturanKisi) {
    if (_selectedTalepEdenler.isEmpty) return true;
    return _selectedTalepEdenler.any(
      (kisi) => olusturanKisi.toLowerCase().contains(kisi.toLowerCase()),
    );
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
  /// Isolate ile filtreleme işlemini başlat
  Future<void> _runFilterIsolate(List<Talep> taleplerListesi) async {
    // Mevcut filtre parametrelerini hash'le
    final currentFilterHash =
        '$_selectedTalepTarihi|'
        '${_selectedTalepTurleri.join(',')}|'
        '${_selectedTalepEdenler.join(',')}|'
        '${_selectedTalepDurumlari.join(',')}|'
        '${_selectedGorevler.join(',')}|'
        '${_selectedGorevYerleri.join(',')}|'
        '$_yenidenEskiye';
    final currentDataHash = taleplerListesi.length;

    // Cache hit - eğer işlemde değilsek ve veri güncelse çık
    if (!_isFiltering && 
        currentDataHash == _lastFilteredDataHash && 
        currentFilterHash == _lastFilterHash && 
        _displayedTalepler != null) {
      return;
    }

    // Eğer zaten işlemdeysek, işlem bitince tekrar kontrol edilmek üzere çık
    // (Aşağıdaki loop mantığı veya recursive çağrı bunu halledecek)
    if (_isFiltering) {
      // İşlem sürüyor, parametreler değişmiş olabilir. 
      // Ancak _runFilterIsolate zaten recursive/loop mantığıyla tekrar çağrılmalı.
      // Burada sadece return diyerek mevcut isolate'in bitmesini bekleyemeyiz 
      // çünkü mevcut isolate bitince kimse yeni filtreyi tetiklemez.
      // Bu yüzden basit bir "pending update" flag'i veya recursive yapı kurmalıyız.
      // Basit çözüm: mevcut isolate bitince tekrar kontrol et.
      return; 
    }

    _lastFilteredDataHash = currentDataHash;
    _lastFilterHash = currentFilterHash;

    // Filtreleme yoksa direkt kullan (Isolate başlatma)
    if (!isFilterActive && _yenidenEskiye) {
      if (mounted) {
         setState(() {
          _displayedTalepler = List.of(taleplerListesi);
          _cachedFilteredTalepler = _displayedTalepler!;
        });
      }
      return;
    }

    setState(() {
      _isFiltering = true;
    });

    try {
      final params = FilterParams(
        talepler: taleplerListesi,
        talepTarihi: _selectedTalepTarihi,
        talepTurleri: Set.of(_selectedTalepTurleri),
        talepEdenler: Set.of(_selectedTalepEdenler),
        talepDurumlari: Set.of(_selectedTalepDurumlari),
        gorevler: Set.of(_selectedGorevler),
        gorevYerleri: Set.of(_selectedGorevYerleri),
        yenidenEskiye: _yenidenEskiye,
      );

      final result = await compute(filterAndSortTaleplerIsolate, params);

      if (mounted) {
        setState(() {
          _displayedTalepler = result;
          _cachedFilteredTalepler = result;
          _isFiltering = false;
        });

        // CRITICAL: İşlem bittikten sonra parametreler değişmiş mi kontrol et
        final newFilterHash =
            '$_selectedTalepTarihi|'
            '${_selectedTalepTurleri.join(',')}|'
            '${_selectedTalepEdenler.join(',')}|'
            '${_selectedTalepDurumlari.join(',')}|'
            '${_selectedGorevler.join(',')}|'
            '${_selectedGorevYerleri.join(',')}|'
            '$_yenidenEskiye';
        
        // Eğer işlem süresince parametreler değiştiyse, tekrar çalıştır
        if (newFilterHash != currentFilterHash) {
          _runFilterIsolate(taleplerListesi);
        }
      }
    } catch (e) {
      debugPrint('Filtreleme hatası: $e');
      if (mounted) {
        setState(() {
          _displayedTalepler = taleplerListesi; 
          _isFiltering = false;
        });
      }
    }
  }

  // Süre filtresi için cutoff tarihini hesapla - her filtreleme için tekrar hesaplama yerine bir kere
  DateTime? _getSureCutoffDate(DateTime now) {
    switch (_selectedTalepTarihi) {
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

  // Talep tarihi (süre) filtresine göre kontrol
  bool _talepTarihiFiltresindenGeciyorMu(String olusturmaTarihi) {
    if (_selectedTalepTarihi == 'Tümü') return true;

    try {
      final tarih = DateTime.parse(olusturmaTarihi);
      final simdi = DateTime.now();
      final fark = simdi.difference(tarih);

      switch (_selectedTalepTarihi) {
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

  // Talep durumu filtresine göre kontrol
  bool _talepDurumuFiltresindenGeciyorMu(String onayDurumu) {
    if (_selectedTalepDurumlari.isEmpty) return true;
    return _selectedTalepDurumlari.any(
      (durum) => onayDurumu.toLowerCase().contains(durum.toLowerCase()),
    );
  }

  // Görev filtresine göre kontrol
  bool _gorevFiltresindenGeciyorMu(String? gorevi) {
    if (_selectedGorevler.isEmpty) return true;
    if (gorevi == null || gorevi.isEmpty) return false;

    // Seçili görev adlarını kontrol et (String karşılaştırması)
    return _selectedGorevler.any(
      (selectedGorev) => gorevi.toLowerCase() == selectedGorev.toLowerCase(),
    );
  }

  // Görev Yeri filtresine göre kontrol
  bool _gorevYeriFiltresindenGeciyorMu(String? gorevYeri) {
    if (_selectedGorevYerleri.isEmpty) return true;
    if (gorevYeri == null || gorevYeri.isEmpty) return false;

    // Seçili görev yeri adlarını kontrol et (String karşılaştırması)
    return _selectedGorevYerleri.any(
      (selectedGorevYeri) =>
          gorevYeri.toLowerCase() == selectedGorevYeri.toLowerCase(),
    );
  }

  // Tüm filtre seçeneklerini gösteren BottomSheet - Multi-page
  void _showFilterOptionsBottomSheet() {
    setState(() => _currentFilterPage = null);

    final personelSearchController = TextEditingController();
    String personelSearchQuery = '';

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
            maxHeight: MediaQuery.of(context).size.height - 60,
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
                            _selectedTalepTurleri.clear();
                            _selectedTalepEdenler.clear();
                            _selectedTalepTarihi = 'Tümü';
                            _selectedTalepDurumlari.clear();
                            _selectedGorevler.clear();
                            _selectedGorevYerleri.clear();
                          });
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
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
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
                            personelSearchController,
                            personelSearchQuery,
                            (value) {
                              setModalState(() {
                                personelSearchQuery = value;
                              });
                            },
                          ),
                  ),
                ),
              ),
              if (_currentFilterPage == null)
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 60,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // PERFORMANCE: setState kaldırıldı, modal kapanınca rebuild olur
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
                    bottom: 60,
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
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textOnPrimary,
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
      case 'talepEden':
        return 'Talep Eden';
      case 'talepTarihi':
        return 'Talep Tarihi';
      case 'talepDurumu':
        return 'Talep Durumu';
      case 'gorev':
        return 'Görev';
      case 'gorevYeri':
        return 'Görev Yeri';
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
            selectedValue: _selectedTalepTurleri.isNotEmpty
                ? _selectedTalepTurleri.join(', ')
                : 'Tümü',
            onTap: () => setModalState(() => _currentFilterPage = 'talepTuru'),
          ),
          _buildFilterMainItem(
            title: 'Talep Eden',
            selectedValue: _selectedTalepEdenler.isNotEmpty
                ? _selectedTalepEdenler.join(', ')
                : 'Tümü',
            onTap: () => setModalState(() => _currentFilterPage = 'talepEden'),
          ),
          _buildFilterMainItem(
            title: 'Talep Tarihi',
            selectedValue: _selectedTalepTarihi,
            onTap: () =>
                setModalState(() => _currentFilterPage = 'talepTarihi'),
          ),
          if (widget.tip != 2)
            _buildFilterMainItem(
              title: 'Talep Durumu',
              selectedValue: _selectedTalepDurumlari.isEmpty
                  ? 'Tümü'
                  : _selectedTalepDurumlari.join(', '),
              onTap: () =>
                  setModalState(() => _currentFilterPage = 'talepDurumu'),
            ),
          _buildFilterMainItem(
            title: 'Görev',
            selectedValue: _selectedGorevler.isNotEmpty
                ? _selectedGorevler.join(', ')
                : 'Tümü',
            onTap: () => setModalState(() => _currentFilterPage = 'gorev'),
          ),
          _buildFilterMainItem(
            title: 'Görev Yeri',
            selectedValue: _selectedGorevYerleri.isNotEmpty
                ? _selectedGorevYerleri.join(', ')
                : 'Tümü',
            onTap: () => setModalState(() => _currentFilterPage = 'gorevYeri'),
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

  Widget _buildFilterDetailPage(
    String filterType,
    StateSetter setModalState,
    TextEditingController personelSearchController,
    String personelSearchQuery,
    Function(String) onPersonelSearchChanged,
  ) {
    switch (filterType) {
      case 'talepTuru':
        return _buildTalepTuruFilterDetailPage(setModalState);
      case 'talepEden':
        return _buildPersonelFilterDetailPage(
          setModalState,
          personelSearchController,
          personelSearchQuery,
          onPersonelSearchChanged,
        );
      case 'talepTarihi':
        return _buildTalepTarihiFilterDetailPage(setModalState);
      case 'talepDurumu':
        return _buildTalepDurumuFilterDetailPage(setModalState);
      case 'gorev':
        return _buildGorevFilterDetailPage(setModalState);
      case 'gorevYeri':
        return _buildGorevYeriFilterDetailPage(setModalState);
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

  Widget _buildPersonelFilterDetailPage(
    StateSetter setModalState,
    TextEditingController searchController,
    String searchQuery,
    Function(String) onSearchChanged,
  ) {
    final filteredKisiler = searchQuery.isEmpty
        ? _talepEdenKisiler
        : _talepEdenKisiler
              .where(
                (kisi) =>
                    kisi.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Personel ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: AppColors.gradientStart),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          if (_selectedTalepEdenler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedTalepEdenler.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.gradientStart),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _talepEdenKisiler.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz talep eden kişi yok',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : filteredKisiler.isEmpty
                ? const Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filteredKisiler.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) {
                      final kisi = filteredKisiler[index];
                      final selected = _selectedTalepEdenler.contains(kisi);

                      return CheckboxListTile(
                        dense: true,
                        title: Text(
                          kisi,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? AppColors.gradientStart
                                : AppColors.textPrimary87,
                          ),
                        ),
                        value: selected,
                        activeColor: AppColors.gradientStart,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: AppColors.textTertiary,
                          width: 1.5,
                        ),
                        onChanged: (bool? value) {
                          setModalState(() {
                            if (value == true) {
                              _selectedTalepEdenler.add(kisi);
                            } else {
                              _selectedTalepEdenler.remove(kisi);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTalepTarihiFilterDetailPage(StateSetter setModalState) {
    return SingleChildScrollView(
      child: Column(
        children: _talepTarihiSecenekleri
            .map(
              (secenek) => ListTile(
                dense: true,
                title: Text(
                  secenek,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: secenek == _selectedTalepTarihi
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: secenek == _selectedTalepTarihi
                        ? AppColors.gradientStart
                        : AppColors.textPrimary87,
                  ),
                ),
                trailing: secenek == _selectedTalepTarihi
                    ? const Icon(
                        Icons.check,
                        color: AppColors.gradientStart,
                        size: 22,
                      )
                    : null,
                onTap: () {
                  setModalState(() => _selectedTalepTarihi = secenek);
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

  Widget _buildGorevFilterDetailPage(StateSetter setModalState) {
    if (_mevcutGorevler.isEmpty) {
      return const Center(child: Text('Henüz görev bilgisi yok'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedGorevler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedGorevler.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.gradientStart),
                  ),
                ),
              ),
            ),
          ..._mevcutGorevler.map(
            (gorev) => CheckboxListTile(
              dense: true,
              title: Text(
                gorev,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _selectedGorevler.contains(gorev)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedGorevler.contains(gorev)
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              value: _selectedGorevler.contains(gorev),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: AppColors.textTertiary, width: 1.5),
              onChanged: (bool? value) {
                setModalState(() {
                  if (value == true) {
                    _selectedGorevler.add(gorev);
                  } else {
                    _selectedGorevler.remove(gorev);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGorevYeriFilterDetailPage(StateSetter setModalState) {
    if (_mevcutGorevYerleri.isEmpty) {
      return const Center(child: Text('Henüz görev yeri bilgisi yok'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedGorevYerleri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedGorevYerleri.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: AppColors.gradientStart),
                  ),
                ),
              ),
            ),
          ..._mevcutGorevYerleri.map(
            (yeri) => CheckboxListTile(
              dense: true,
              title: Text(
                yeri,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _selectedGorevYerleri.contains(yeri)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedGorevYerleri.contains(yeri)
                      ? AppColors.gradientStart
                      : AppColors.textPrimary87,
                ),
              ),
              value: _selectedGorevYerleri.contains(yeri),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: AppColors.textTertiary, width: 1.5),
              onChanged: (bool? value) {
                setModalState(() {
                  if (value == true) {
                    _selectedGorevYerleri.add(yeri);
                  } else {
                    _selectedGorevYerleri.remove(yeri);
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
      bilgiTeknolojileriGelenKutusuOnayKayitIdSetProvider,
    );

    // Cache the IDs locally when available
    if (bilgiTekAsyncValue.hasValue) {
      _bilgiTekOnayKayitIds = bilgiTekAsyncValue.value!;
    }

    // 1. Provider'ı seç
    final provider = widget.tip == 2
        ? devamEdenGelenKutusuProvider
        : tamamlananGelenKutusuProvider;

    // 2. State'i izle
    final state = ref.watch(provider);

    // Veri çekildi bildirimi - Sadece tamamlanan tabında göster (tip: 3)
    ref.listen(provider, (previous, next) {
      if (widget.tip == 3 &&
          previous?.isInitialLoading == true &&
          !next.isInitialLoading &&
          next.talepler.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veri geldi'),
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // 3. İlk yükleme hatası varsa göster
    if (state.errorMessage != null && state.talepler.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
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

    // 4. İlk yükleme (Loading) durumu
    // 4. İlk yükleme (Loading) durumu veya Filtreleme durumu
    // Eğer filtreleme yapılıyorsa ve henüz data yoksa shimmer göster
    if (state.isInitialLoading || (_isFiltering && _displayedTalepler == null)) {
      return const ListShimmer(itemCount: 5);
    }

    // 5. Verileri işle (Filtreleme & Sıralama - Client Side)
    // NOT: Pagination ile client side filtreleme sadece YÜKLENMİŞ veriler üzerinde çalışır.
    // İdealde filtreler sunucu tarafında olmalı, ancak mevcut yapıyı koruyoruz.

    // Filtreleri doldur (Sadece build esnasında bir kez tetiklemek için post frame callback kullanılabilir veya doğrudan burada hesaplanabilir)
    // Sürekli setState çağırmamak için, burada sadece hesaplayıp local değişkenlerde tutuyoruz.
    // _mevcutGorevler vb. listeleri güncellemek UI rebuilding gerektirebilir, ancak state zaten değiştiğinde build çalışıyor.

    final taleplerListesi = state.talepler;

    // Side effect: Filtre listelerini güncelle - only when data changes
    // Use microtask for less overhead and guard with length check
    if (taleplerListesi.length != _lastTotal) {
      _lastTotal = taleplerListesi.length;
      Future.microtask(() {
        if (!mounted) return;
        final kisiler =
            taleplerListesi
                .map((t) => t.olusturanKisi)
                .where((kisi) => kisi.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        final talepTurleri =
            taleplerListesi
                .map((t) => t.onayTipi)
                .where((tur) => tur.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        final gorevler =
            taleplerListesi
                .map((t) => t.gorevi ?? '')
                .where((gorev) => gorev.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        final gorevYerleri =
            taleplerListesi
                .map((t) => t.gorevYeri ?? '')
                .where((gorevYeri) => gorevYeri.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        bool kisilerChanged = !_listEquals(_talepEdenKisiler, kisiler);
        bool talepTurleriChanged = !_listEquals(
          _mevcutTalepTurleri,
          talepTurleri,
        );
        bool gorevlerChanged = !_listEquals(_mevcutGorevler, gorevler);
        bool gorevYerleriChanged = !_listEquals(
          _mevcutGorevYerleri,
          gorevYerleri,
        );

        if (kisilerChanged ||
            talepTurleriChanged ||
            gorevlerChanged ||
            gorevYerleriChanged) {
          setState(() {
            if (kisilerChanged) {
              _talepEdenKisiler = kisiler;
            }
            if (talepTurleriChanged) {
              _mevcutTalepTurleri = talepTurleri;
            }
            if (gorevlerChanged) {
              _mevcutGorevler = gorevler;
            }
            if (gorevYerleriChanged) {
              _mevcutGorevYerleri = gorevYerleri;
            }
          });
        }
      });
    }

    // 5. Verileri işle (Filtreleme & Sıralama - Client Side)
    // NOT: Pagination ile client side filtreleme sadece YÜKLENMİŞ veriler üzerinde çalışır.

    // PERFORMANCE: Memoized filtreleme - sadece veri veya filtre değiştiğinde çalışır
    // 5. Verileri işle (Filtreleme & Sıralama - Isolate)
    // Filtreleme işlemini başlat (gerekirse)
    final filterHash =
        '$_selectedTalepTarihi|'
        '${_selectedTalepTurleri.join(',')}|'
        '${_selectedTalepEdenler.join(',')}|'
        '${_selectedTalepDurumlari.join(',')}|'
        '${_selectedGorevler.join(',')}|'
        '${_selectedGorevYerleri.join(',')}|'
        '$_yenidenEskiye';
    final dataHash = taleplerListesi.length;

    // Eğer filtre/data değiştiyse isolate'i başlat
    if (dataHash != _lastFilteredDataHash || filterHash != _lastFilterHash || _displayedTalepler == null) {
      // Microtask içinde başlatarak build'i bloklama
      Future.microtask(() => _runFilterIsolate(taleplerListesi));
    }
    
    // Gösterilecek liste: Isolate sonucu varsa onu kullan, yoksa ham listeyi (ilk açılış) veya boş listeyi
    // Filtreleme sürüyorsa ve _displayedTalepler null ise loading gösterebiliriz
    final filteredTalepler = _displayedTalepler ?? (_isFiltering ? [] : taleplerListesi);

    // 6. Boş liste durumu
    if (filteredTalepler.isEmpty) {
      // Eğer hiç data yoksa
      if (taleplerListesi.isEmpty) {
        // Veri yok ekranı
        // ...
      }

      return const SizedBox.shrink();
    }

    // 7. Listeyi Oluştur
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(provider.notifier).refresh();
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120, // Bottom padding
          ),
          // +1 for loading indicator at the bottom
          itemCount: filteredTalepler.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading Indicator Item
            if (index == filteredTalepler.length) {
              // Eğer loading spinner görünüyorsa ve henüz yükleme yapılmıyorsa,
              // yeni verileri yükle (Auto-pagination for short lists)
              if (!state.isLoading && state.hasMore) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final provider = widget.tip == 2
                      ? devamEdenGelenKutusuProvider
                      : tamamlananGelenKutusuProvider;
                  ref.read(provider.notifier).loadMore();
                });
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: TalepKartiShimmer()),
              );
            }

            final talep = filteredTalepler[index];
            final isTeknikDestek = talep.onayTipi.toLowerCase().contains(
              'teknik destek',
            );
            final shouldShowBilgiTeknolojileri =
                isTeknikDestek &&
                _bilgiTekOnayKayitIds.contains(talep.onayKayitId);

            return RepaintBoundary(
              child: GelenKutusuKarti(
                talep: talep,
                displayOnayTipi: shouldShowBilgiTeknolojileri
                    ? 'Bilgi Teknolojileri'
                    : talep.onayTipi,
                talepList: filteredTalepler,
                indexInList: index,
                onReturnIndex: (returnIndex) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToIndex(returnIndex, filteredTalepler.length);
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Isolate için filtreleme parametreleri
class FilterParams {
  final List<Talep> talepler;
  final String talepTarihi;
  final Set<String> talepTurleri;
  final Set<String> talepEdenler;
  final Set<String> talepDurumlari;
  final Set<String> gorevler;
  final Set<String> gorevYerleri;
  final bool yenidenEskiye;

  FilterParams({
    required this.talepler,
    required this.talepTarihi,
    required this.talepTurleri,
    required this.talepEdenler,
    required this.talepDurumlari,
    required this.gorevler,
    required this.gorevYerleri,
    required this.yenidenEskiye,
  });
}

/// Isolate üzerinde çalışacak filtreleme ve sıralama fonksiyonu
List<Talep> filterAndSortTaleplerIsolate(FilterParams params) {
  List<Talep> result;

  // Helper date calculator
  DateTime? getSureCutoffDate(String selectedTalepTarihi, DateTime now) {
    switch (selectedTalepTarihi) {
      case '1 Hafta':
        return now.subtract(const Duration(days: 7));
      case '1 Ay':
        return now.subtract(const Duration(days: 30));
      case '3 Ay':
        return now.subtract(const Duration(days: 90));
      case '1 Yıl':
        return now.subtract(const Duration(days: 365));
      default:
        return null;
    }
  }

  // Pre-calculate filter cutoff
  final now = DateTime.now();
  final sureCutoff = getSureCutoffDate(params.talepTarihi, now);

  // Filtreleme
  result = params.talepler.where((talep) {
    // Date filter
    if (sureCutoff != null) {
      if (talep.parsedOlusturmaTarihi.isBefore(sureCutoff)) {
        return false;
      }
    }

    // Talep türü
    if (params.talepTurleri.isNotEmpty && !params.talepTurleri.contains(talep.onayTipi)) {
      return false;
    }

    // Talep eden
    if (params.talepEdenler.isNotEmpty && !params.talepEdenler.contains(talep.olusturanKisi)) {
      return false;
    }

    // Talep durumu
    if (params.talepDurumlari.isNotEmpty) {
      // Basit kontrol: contains
       if (!params.talepDurumlari.any((durum) => talep.onayDurumu.toLowerCase().contains(durum.toLowerCase()))) {
         return false;
       }
    }

    // Görev
    if (params.gorevler.isNotEmpty && !params.gorevler.contains(talep.gorevi ?? '')) {
      return false;
    }

    // Görev yeri
    if (params.gorevYerleri.isNotEmpty && !params.gorevYerleri.contains(talep.gorevYeri ?? '')) {
      return false;
    }

    return true;
  }).toList();

  // Sıralama
  result.sort((a, b) {
    return params.yenidenEskiye
        ? b.parsedOlusturmaTarihi.compareTo(a.parsedOlusturmaTarihi)
        : a.parsedOlusturmaTarihi.compareTo(b.parsedOlusturmaTarihi);
  });

  return result;
}

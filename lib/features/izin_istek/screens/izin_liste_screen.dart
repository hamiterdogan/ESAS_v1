import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turu_secim_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';

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
        appBar: AppBar(
          title: const Text(
            'İzin Taleplerini Yönet',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF014B92),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            _IzinTalepleriListesi(key: _devamEdenKey, tip: 0), // Devam Eden
            _IzinTalepleriListesi(key: _tamamlananKey, tip: 1), // Tamamlanan
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
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
            'Yeni İzin Talebi',
            style: TextStyle(color: Colors.white),
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
  Set<String> _selectedIzinTurleri = {};
  Set<String> _selectedTalepDurumlari = {};

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

  // Filtre sayfası durumu - null = ana liste, 'sure' = süre sayfası, vb.
  String? _currentFilterPage;

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
                color: Colors.grey[300],
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
                      ? const Color(0xFF014B92)
                      : Colors.black87,
                ),
              ),
              trailing: !_yenidenEskiye
                  ? const Icon(Icons.check, color: Color(0xFF014B92))
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
                      ? const Color(0xFF014B92)
                      : Colors.black87,
                ),
              ),
              trailing: _yenidenEskiye
                  ? const Icon(Icons.check, color: Color(0xFF014B92))
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
                  color: Colors.grey[300],
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
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
                        setState(() {});
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014B92),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Uygula',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {
                          _currentFilterPage = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF014B92),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Tamam',
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
      case 'sure':
        return 'Süre';
      case 'izinTuru':
        return 'İzin Türü';
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
            title: 'Süre',
            selectedValue: _selectedSure,
            onTap: () => setModalState(() => _currentFilterPage = 'sure'),
          ),
          _buildFilterMainItem(
            title: 'İzin Türü',
            selectedValue: _selectedIzinTurleri.isEmpty
                ? 'Tümü'
                : _selectedIzinTurleri.join(', '),
            onTap: () => setModalState(() => _currentFilterPage = 'izinTuru'),
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
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
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
                      color: Colors.black87,
                    ),
                  ),
                  if (selectedValue != 'Tümü') ...[
                    const SizedBox(height: 4),
                    Text(
                      selectedValue,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF014B92),
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
      case 'sure':
        return _buildSureFilterDetailPage(setModalState);
      case 'izinTuru':
        return _buildIzinTuruFilterDetailPage(setModalState);
      case 'talepDurumu':
        return _buildTalepDurumuFilterDetailPage(setModalState);
      default:
        return const SizedBox.shrink();
    }
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
                        ? const Color(0xFF014B92)
                        : Colors.black87,
                  ),
                ),
                trailing: secenek == _selectedSure
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF014B92),
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

  Widget _buildIzinTuruFilterDetailPage(StateSetter setModalState) {
    if (_mevcutIzinTurleri.isEmpty) {
      return const Center(child: Text('Henüz izin türü bilgisi yok'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedIzinTurleri.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      setModalState(() => _selectedIzinTurleri.clear()),
                  child: const Text(
                    'Temizle',
                    style: TextStyle(color: Color(0xFF014B92)),
                  ),
                ),
              ),
            ),
          ..._mevcutIzinTurleri.map(
            (tur) => CheckboxListTile(
              dense: true,
              title: Text(
                tur,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: _selectedIzinTurleri.contains(tur)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: _selectedIzinTurleri.contains(tur)
                      ? const Color(0xFF014B92)
                      : Colors.black87,
                ),
              ),
              value: _selectedIzinTurleri.contains(tur),
              activeColor: const Color(0xFF014B92),
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
              onChanged: (bool? value) {
                setModalState(() {
                  if (value == true) {
                    _selectedIzinTurleri.add(tur);
                  } else {
                    _selectedIzinTurleri.remove(tur);
                  }
                });
              },
            ),
          ),
        ],
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
                    style: TextStyle(color: Color(0xFF014B92)),
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
                      ? const Color(0xFF014B92)
                      : Colors.black87,
                ),
              ),
              value: _selectedTalepDurumlari.contains(secenek),
              activeColor: const Color(0xFF014B92),
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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
    final asyncValue = widget.tip == 0
        ? ref.watch(onayBekleyenTaleplerProvider)
        : ref.watch(onaylananTaleplerProvider);

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Hata: ${error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Filtre kriterlerine uygun talep yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                onDelete: () => _deleteIzinTalebi(talep.onayKayitID),
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
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
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
        SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: Colors.red),
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
    final statusText = talep.onayDurumu;

    Color statusColor;
    IconData statusIcon;

    switch (statusText.toLowerCase()) {
      case 'onaylandı':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'reddedildi':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

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

    final isDeleteAvailable = statusText.toLowerCase() == 'onay bekliyor';

    return Slidable(
      key: ValueKey(talep.onayKayitID),
      endActionPane: isDeleteAvailable
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                CustomSlidableAction(
                  onPressed: (context) => onDelete(),
                  backgroundColor: Colors.red,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, size: 40, color: Colors.white),
                        SizedBox(height: 6),
                        Text(
                          'İzni İptal Et',
                          style: TextStyle(
                            color: Colors.white,
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
                    builder: (ctx) => IzinIstekDetayScreen(
                      talepId: talep.onayKayitID,
                      onayTipi: talep.onayTipi,
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
                            izinTuru,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF014B92),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tarihStr,
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
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
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
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                      size: 24,
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


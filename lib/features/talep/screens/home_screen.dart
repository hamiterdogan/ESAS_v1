import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/talep/models/talep_turu.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/personel/providers/personel_providers.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // GlobalKey'ler filtre işlemlerine erişim için
  final GlobalKey<_IsteklerimContentState> _isteklerimKey = GlobalKey();
  final GlobalKey<_GelenKutusuContentState> _gelenKutusuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Tab'a göre başlık belirleme
    String appBarTitle;
    switch (_currentIndex) {
      case 1:
        appBarTitle = 'İsteklerim';
        break;
      case 2:
        appBarTitle = 'Gelen Kutusu';
        break;
      default:
        appBarTitle = 'ESAS';
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _currentIndex != 0
            ? [
                // Sıralama ikonları şimdilik gizli - ilerde tekrar etkinleştirilecek
                // Padding(
                //   padding: const EdgeInsets.only(right: 4),
                //   child: InkWell(...sort...)
                // ),
                // Filtreleme ikonu + label
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (_currentIndex == 1) {
                        _isteklerimKey.currentState?.showFilterBottomSheet();
                      } else if (_currentIndex == 2) {
                        _gelenKutusuKey.currentState?.showFilterBottomSheet();
                      }
                    },
                    child: SizedBox(
                      height: kToolbarHeight,
                      width: 50,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.filter_alt_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Filtrele',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _AnaSayfaContent(),
          _IsteklerimContent(key: _isteklerimKey),
          _GelenKutusuContent(key: _gelenKutusuKey),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 50),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Ana Sayfa
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Ana Sayfa',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              // İsteklerim
              _buildNavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment,
                label: 'İsteklerim',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              // Gelen Kutusu
              _buildNavItem(
                icon: Icons.inbox_outlined,
                activeIcon: Icons.inbox,
                label: 'Gelen Kutusu',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 110,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 33,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ana Sayfa içeriği (mevcut grid)
class _AnaSayfaContent extends ConsumerWidget {
  const _AnaSayfaContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final talepTurleri = TalepTuru.getAll();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 4,
          childAspectRatio: 1.25,
        ),
        itemCount: talepTurleri.length,
        itemBuilder: (context, index) {
          final talep = talepTurleri[index];
          return TalepTuruCard(talep: talep);
        },
      ),
    );
  }
}

// İsteklerim tab içeriği - Devam Eden ve Tamamlanan tab'ları ile
class _IsteklerimContent extends ConsumerStatefulWidget {
  const _IsteklerimContent({super.key});

  @override
  ConsumerState<_IsteklerimContent> createState() => _IsteklerimContentState();
}

class _IsteklerimContentState extends ConsumerState<_IsteklerimContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GlobalKey'ler liste widget'larına erişim için
  final GlobalKey<_IsteklerimListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<_IsteklerimListesiState> _tamamlananKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // AppBar'dan çağrılacak sıralama metodu
  void showSiralamaBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showSiralamaBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showSiralamaBottomSheetPublic();
    }
  }

  // AppBar'dan çağrılacak filtreleme metodu
  void showFilterBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showFilterBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showFilterBottomSheetPublic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
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
              _IsteklerimListesi(key: _devamEdenKey, tip: 0),
              // Tamamlanan
              _IsteklerimListesi(key: _tamamlananKey, tip: 1),
            ],
          ),
        ),
      ],
    );
  }
}

// İsteklerim listesi widget'ı - Filtreli
class _IsteklerimListesi extends ConsumerStatefulWidget {
  final int tip;

  const _IsteklerimListesi({super.key, required this.tip});

  @override
  ConsumerState<_IsteklerimListesi> createState() => _IsteklerimListesiState();
}

class _IsteklerimListesiState extends ConsumerState<_IsteklerimListesi> {
  // Filtre değerleri - Çoklu seçim için Set kullanılıyor
  String _selectedSure = 'Tümü';
  Set<String> _selectedTalepTurleri = {};
  Set<String> _selectedTalepDurumlari = {};

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

  // AppBar'dan çağrılacak public metodlar
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

  // Talep türü filtresine göre kontrol - Çoklu seçim destekli
  bool _talepTuruFiltresindenGeciyorMu(String onayTipi) {
    if (_selectedTalepTurleri.isEmpty) return true;
    return _selectedTalepTurleri.any(
      (tur) => onayTipi.toLowerCase().contains(tur.toLowerCase()),
    );
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
                      ? AppColors.gradientStart
                      : Colors.black87,
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
                      : Colors.black87,
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
            const Icon(Icons.arrow_forward, color: Colors.grey),
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
                      : Colors.black87,
                ),
              ),
              value: _selectedTalepTurleri.contains(tur),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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
                        : Colors.black87,
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
                      : Colors.black87,
                ),
              ),
              value: _selectedTalepDurumlari.contains(secenek),
              activeColor: AppColors.gradientStart,
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
        ? ref.watch(devamEdenIsteklerimProvider)
        : ref.watch(tamamlananIsteklerimProvider);

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
                  ref.invalidate(devamEdenIsteklerimProvider);
                } else {
                  ref.invalidate(tamamlananIsteklerimProvider);
                }
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (response) {
        // Mevcut talep türlerinin listesini güncelle (unique ve sıralı)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final talepTurleri =
              response.talepler
                  .map((t) => t.onayTipi)
                  .where((tur) => tur.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_mevcutTalepTurleri.length != talepTurleri.length ||
              !_mevcutTalepTurleri.every((t) => talepTurleri.contains(t))) {
            setState(() {
              _mevcutTalepTurleri = talepTurleri;
            });
          }
        });

        // Filtrelenmiş liste
        final filteredTalepler = response.talepler.where((talep) {
          final surePassed = _sureFiltresindenGeciyorMu(talep.olusturmaTarihi);
          final talepTuruPassed = _talepTuruFiltresindenGeciyorMu(
            talep.onayTipi,
          );
          // Talep durumu filtresi sadece Tamamlanan tab'da (tip == 1) uygulanır
          final talepDurumuPassed = widget.tip == 1
              ? _talepDurumuFiltresindenGeciyorMu(talep.onayDurumu)
              : true;
          return surePassed && talepTuruPassed && talepDurumuPassed;
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
                ref.invalidate(devamEdenIsteklerimProvider);
              } else {
                ref.invalidate(tamamlananIsteklerimProvider);
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
              ref.invalidate(devamEdenIsteklerimProvider);
            } else {
              ref.invalidate(tamamlananIsteklerimProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120,
            ),
            itemCount: filteredTalepler.length,
            itemBuilder: (context, index) {
              final talep = filteredTalepler[index];
              return _TalepKarti(talep: talep);
            },
          ),
        );
      },
    );
  }
}

// Talep kartı widget'ı
class _TalepKarti extends StatelessWidget {
  final Talep talep;

  const _TalepKarti({required this.talep});

  String _formatTarih(String tarihStr) {
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Color _getOnayDurumuRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Colors.orange;
      case 'onaylandı':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOnayDurumuIkonu(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Icons.schedule;
      case 'onaylandı':
        return Icons.check_circle;
      case 'reddedildi':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Sadece "İzin İstek" süreçleri için detay sayfasına git
          if (talep.onayTipi.toLowerCase().contains('izin')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => IzinIstekDetayScreen(
                  talepId: talep.onayKayitID,
                  onayTipi: talep.onayTipi,
                ),
              ),
            );
          }
          // Diğer süreç türleri için şimdilik tepki verme
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sol taraf - Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Süreç No
                    Row(
                      children: [
                        Text(
                          'Süreç No: ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${talep.onayKayitID}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gradientStart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Talep Türü
                    Text(
                      talep.onayTipi,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gradientStart,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tarih ve Onay Durumu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTarih(talep.olusturmaTarihi),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getOnayDurumuRengi(
                              talep.onayDurumu,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getOnayDurumuIkonu(talep.onayDurumu),
                                size: 16,
                                color: _getOnayDurumuRengi(talep.onayDurumu),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                talep.onayDurumu,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getOnayDurumuRengi(talep.onayDurumu),
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
              // Sağ taraf - Büyüktür ikonu
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// Gelen Kutusu tab içeriği - Devam Eden ve Tamamlanan tab'ları ile
class _GelenKutusuContent extends ConsumerStatefulWidget {
  const _GelenKutusuContent({super.key});

  @override
  ConsumerState<_GelenKutusuContent> createState() =>
      _GelenKutusuContentState();
}

class _GelenKutusuContentState extends ConsumerState<_GelenKutusuContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // GlobalKey'ler liste widget'larına erişim için
  final GlobalKey<_GelenKutusuListesiState> _devamEdenKey = GlobalKey();
  final GlobalKey<_GelenKutusuListesiState> _tamamlananKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // AppBar'dan çağrılacak sıralama metodu
  void showSiralamaBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showSiralamaBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showSiralamaBottomSheetPublic();
    }
  }

  // AppBar'dan çağrılacak filtreleme metodu
  void showFilterBottomSheet() {
    if (_tabController.index == 0) {
      _devamEdenKey.currentState?.showFilterBottomSheetPublic();
    } else {
      _tamamlananKey.currentState?.showFilterBottomSheetPublic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
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
              _GelenKutusuListesi(key: _devamEdenKey, tip: 2),
              // Tamamlanan (tip: 3)
              _GelenKutusuListesi(key: _tamamlananKey, tip: 3),
            ],
          ),
        ),
      ],
    );
  }
}

// Gelen Kutusu listesi widget'ı - Filtreli
class _GelenKutusuListesi extends ConsumerStatefulWidget {
  final int tip;

  const _GelenKutusuListesi({super.key, required this.tip});

  @override
  ConsumerState<_GelenKutusuListesi> createState() =>
      _GelenKutusuListesiState();
}

class _GelenKutusuListesiState extends ConsumerState<_GelenKutusuListesi> {
  // Sıralama: true = yeniden eskiye (varsayılan), false = eskiden yeniye
  bool _yenidenEskiye = true;

  // Filtre sayfası durumu - null = ana liste, 'talepTuru' = talep türü sayfası, vb.
  String? _currentFilterPage;

  // Filtre değerleri - Çoklu seçim için Set kullanılıyor
  Set<String> _selectedTalepTurleri = {};
  Set<String> _selectedTalepEdenler = {};
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
  Set<String> _selectedTalepDurumlari = {};

  // Seçilen görevler - Çoklu seçim (String olarak görev adı)
  Set<String> _selectedGorevler = {};

  // Seçilen görev yerleri - Çoklu seçim (String olarak görev yeri adı)
  Set<String> _selectedGorevYerleri = {};

  // AppBar'dan çağrılacak public metodlar
  void showSiralamaBottomSheetPublic() {
    _showSiralamaBottomSheet();
  }

  void showFilterBottomSheetPublic() {
    // Filtrelenecek seçenek yoksa hiçbir tepki verme
    if (_mevcutGorevler.isEmpty && _mevcutGorevYerleri.isEmpty) {
      return;
    }
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
                      ? AppColors.gradientStart
                      : Colors.black87,
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
                      : Colors.black87,
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
            selectedValue: _selectedTalepTurleri.isEmpty
                ? 'Tümü'
                : _selectedTalepTurleri.join(', '),
            onTap: () => setModalState(() => _currentFilterPage = 'talepTuru'),
          ),
          _buildFilterMainItem(
            title: 'Talep Eden',
            selectedValue: _selectedTalepEdenler.isEmpty
                ? 'Tümü'
                : _selectedTalepEdenler.join(', '),
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
            selectedValue: _selectedGorevler.isEmpty
                ? 'Tümü'
                : _selectedGorevler.join(', '),
            onTap: () => setModalState(() => _currentFilterPage = 'gorev'),
          ),
          _buildFilterMainItem(
            title: 'Görev Yeri',
            selectedValue: _selectedGorevYerleri.isEmpty
                ? 'Tümü'
                : _selectedGorevYerleri.join(', '),
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
            const Icon(Icons.arrow_forward, color: Colors.grey),
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
                      : Colors.black87,
                ),
              ),
              value: _selectedTalepTurleri.contains(tur),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
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
                                : Colors.black87,
                          ),
                        ),
                        value: selected,
                        activeColor: AppColors.gradientStart,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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
                        : Colors.black87,
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
                      : Colors.black87,
                ),
              ),
              value: _selectedTalepDurumlari.contains(secenek),
              activeColor: AppColors.gradientStart,
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
                      : Colors.black87,
                ),
              ),
              value: _selectedGorevler.contains(gorev),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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
                      : Colors.black87,
                ),
              ),
              value: _selectedGorevYerleri.contains(yeri),
              activeColor: AppColors.gradientStart,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: Colors.grey[800]!, width: 1.5),
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

  // Accordion başlık widget'ı
  Widget _buildAccordionItem({
    required String title,
    required String selectedValue,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(
                top: BorderSide(color: Colors.grey[400]!, width: 1),
                bottom: BorderSide(color: Colors.grey[400]!, width: 1),
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
                          fontSize: 19,
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
                            color: AppColors.gradientStart,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: isExpanded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: content,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // Filtre seçeneği tile widget'ı
  Widget _buildFilterOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 17,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.gradientStart : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.gradientStart, size: 22)
          : null,
      onTap: onTap,
    );
  }

  // Personel filtresi içeriği - Çoklu Seçim (Gelen kutusundaki talep edenler)
  Widget _buildPersonelFilterContentMulti({
    required TextEditingController searchController,
    required String searchQuery,
    required Function(String) onSearchChanged,
    required StateSetter setModalState,
  }) {
    // Arama sorgusuna göre filtreleme
    final filteredKisiler = searchQuery.isEmpty
        ? _talepEdenKisiler
        : _talepEdenKisiler
              .where(
                (kisi) =>
                    kisi.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

    return Column(
      children: [
        // Arama kutusu
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
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.gradientStart),
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
        // Temizle butonu
        if (_selectedTalepEdenler.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTalepEdenler.clear();
                  });
                  setModalState(() {});
                },
                child: const Text(
                  'Temizle',
                  style: TextStyle(color: AppColors.gradientStart),
                ),
              ),
            ),
          ),
        // Talep eden kişiler listesi
        if (_talepEdenKisiler.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Henüz talep eden kişi yok',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else if (filteredKisiler.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sonuç bulunamadı',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              shrinkWrap: true,
              itemCount: filteredKisiler.length,
              itemBuilder: (context, index) {
                final kisiAdi = filteredKisiler[index];
                return CheckboxListTile(
                  dense: true,
                  title: Text(
                    kisiAdi,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: _selectedTalepEdenler.contains(kisiAdi)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selectedTalepEdenler.contains(kisiAdi)
                          ? AppColors.gradientStart
                          : Colors.black87,
                    ),
                  ),
                  value: _selectedTalepEdenler.contains(kisiAdi),
                  activeColor: AppColors.gradientStart,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey[800]!, width: 1.5),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedTalepEdenler.add(kisiAdi);
                      } else {
                        _selectedTalepEdenler.remove(kisiAdi);
                      }
                    });
                    setModalState(() {});
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // Talep Türü filtresi içeriği - API'den çoklu seçim
  Widget _buildTalepTuruFilterContent({required StateSetter setModalState}) {
    if (_mevcutTalepTurleri.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Henüz talep türü bilgisi yok',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Temizle butonu
        if (_selectedTalepTurleri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTalepTurleri.clear();
                  });
                  setModalState(() {});
                },
                child: const Text(
                  'Temizle',
                  style: TextStyle(color: AppColors.gradientStart),
                ),
              ),
            ),
          ),
        // Talep türü listesi
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            shrinkWrap: true,
            itemCount: _mevcutTalepTurleri.length,
            itemBuilder: (context, index) {
              final talepTuru = _mevcutTalepTurleri[index];
              return CheckboxListTile(
                dense: true,
                title: Text(
                  talepTuru,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: _selectedTalepTurleri.contains(talepTuru)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedTalepTurleri.contains(talepTuru)
                        ? AppColors.gradientStart
                        : Colors.black87,
                  ),
                ),
                value: _selectedTalepTurleri.contains(talepTuru),
                activeColor: AppColors.gradientStart,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: Colors.grey[800]!, width: 1.5),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedTalepTurleri.add(talepTuru);
                    } else {
                      _selectedTalepTurleri.remove(talepTuru);
                    }
                  });
                  setModalState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Görev filtresi içeriği - API'den çoklu seçim
  Widget _buildGorevFilterContent({required StateSetter setModalState}) {
    // Mevcut taleplerdeki görevleri göster (API'den değil)
    if (_mevcutGorevler.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Henüz görev bilgisi yok',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Temizle butonu
        if (_selectedGorevler.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGorevler.clear();
                  });
                  setModalState(() {});
                },
                child: const Text(
                  'Temizle',
                  style: TextStyle(color: AppColors.gradientStart),
                ),
              ),
            ),
          ),
        // Görev listesi
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            shrinkWrap: true,
            itemCount: _mevcutGorevler.length,
            itemBuilder: (context, index) {
              final gorevAdi = _mevcutGorevler[index];
              return CheckboxListTile(
                dense: true,
                title: Text(
                  gorevAdi,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: _selectedGorevler.contains(gorevAdi)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedGorevler.contains(gorevAdi)
                        ? AppColors.gradientStart
                        : Colors.black87,
                  ),
                ),
                value: _selectedGorevler.contains(gorevAdi),
                activeColor: AppColors.gradientStart,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: Colors.grey[800]!, width: 1.5),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedGorevler.add(gorevAdi);
                    } else {
                      _selectedGorevler.remove(gorevAdi);
                    }
                  });
                  setModalState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Görev Yeri filtresi içeriği - ListView'deki verilerden çoklu seçim
  Widget _buildGorevYeriFilterContent({required StateSetter setModalState}) {
    if (_mevcutGorevYerleri.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Henüz görev yeri bilgisi yok',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Temizle butonu
        if (_selectedGorevYerleri.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGorevYerleri.clear();
                  });
                  setModalState(() {});
                },
                child: const Text(
                  'Temizle',
                  style: TextStyle(color: AppColors.gradientStart),
                ),
              ),
            ),
          ),
        // Görev Yeri listesi
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            shrinkWrap: true,
            itemCount: _mevcutGorevYerleri.length,
            itemBuilder: (context, index) {
              final gorevYeriAdi = _mevcutGorevYerleri[index];
              return CheckboxListTile(
                dense: true,
                title: Text(
                  gorevYeriAdi,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: _selectedGorevYerleri.contains(gorevYeriAdi)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedGorevYerleri.contains(gorevYeriAdi)
                        ? AppColors.gradientStart
                        : Colors.black87,
                  ),
                ),
                value: _selectedGorevYerleri.contains(gorevYeriAdi),
                activeColor: AppColors.gradientStart,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: Colors.grey[800]!, width: 1.5),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedGorevYerleri.add(gorevYeriAdi);
                    } else {
                      _selectedGorevYerleri.remove(gorevYeriAdi);
                    }
                  });
                  setModalState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = widget.tip == 2
        ? ref.watch(devamEdenGelenKutusuProvider)
        : ref.watch(tamamlananGelenKutusuProvider);

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
                if (widget.tip == 2) {
                  ref.invalidate(devamEdenGelenKutusuProvider);
                } else {
                  ref.invalidate(tamamlananGelenKutusuProvider);
                }
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (response) {
        // Talep eden kişilerin listesini güncelle (unique ve sıralı)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final kisiler =
              response.talepler
                  .map((t) => t.olusturanKisi)
                  .where((kisi) => kisi.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_talepEdenKisiler.length != kisiler.length ||
              !_talepEdenKisiler.every((k) => kisiler.contains(k))) {
            setState(() {
              _talepEdenKisiler = kisiler;
            });
          }

          // Mevcut görevlerin listesini güncelle (unique ve sıralı)
          final gorevler =
              response.talepler
                  .map((t) => t.gorevi ?? '')
                  .where((gorev) => gorev.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_mevcutGorevler.length != gorevler.length ||
              !_mevcutGorevler.every((g) => gorevler.contains(g))) {
            setState(() {
              _mevcutGorevler = gorevler;
            });
          }

          // Mevcut talep türlerinin listesini güncelle (unique ve sıralı)
          final talepTurleri =
              response.talepler
                  .map((t) => t.onayTipi)
                  .where((tur) => tur.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_mevcutTalepTurleri.length != talepTurleri.length ||
              !_mevcutTalepTurleri.every((t) => talepTurleri.contains(t))) {
            setState(() {
              _mevcutTalepTurleri = talepTurleri;
            });
          }

          // Mevcut görev yerlerinin listesini güncelle (unique ve sıralı)
          final gorevYerleri =
              response.talepler
                  .map((t) => t.gorevYeri ?? '')
                  .where((yer) => yer.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          if (_mevcutGorevYerleri.length != gorevYerleri.length ||
              !_mevcutGorevYerleri.every((y) => gorevYerleri.contains(y))) {
            setState(() {
              _mevcutGorevYerleri = gorevYerleri;
            });
          }
        });

        // Filtrelenmiş liste
        final filteredTalepler = response.talepler.where((talep) {
          return _talepTuruFiltresindenGeciyorMu(talep.onayTipi) &&
              _talepTarihiFiltresindenGeciyorMu(talep.olusturmaTarihi) &&
              _talepEdenFiltresindenGeciyorMu(talep.olusturanKisi) &&
              _talepDurumuFiltresindenGeciyorMu(talep.onayDurumu) &&
              _gorevFiltresindenGeciyorMu(talep.gorevi) &&
              _gorevYeriFiltresindenGeciyorMu(talep.gorevYeri);
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
              if (widget.tip == 2) {
                ref.invalidate(devamEdenGelenKutusuProvider);
              } else {
                ref.invalidate(tamamlananGelenKutusuProvider);
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
            if (widget.tip == 2) {
              ref.invalidate(devamEdenGelenKutusuProvider);
            } else {
              ref.invalidate(tamamlananGelenKutusuProvider);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 120,
            ),
            itemCount: filteredTalepler.length,
            itemBuilder: (context, index) {
              final talep = filteredTalepler[index];
              return _GelenKutusuKarti(talep: talep);
            },
          ),
        );
      },
    );
  }
}

// Gelen Kutusu kartı widget'ı
class _GelenKutusuKarti extends StatelessWidget {
  final Talep talep;

  const _GelenKutusuKarti({required this.talep});

  String _formatTarih(String tarihStr) {
    try {
      final tarih = DateTime.parse(tarihStr);
      return DateFormat('dd.MM.yyyy').format(tarih);
    } catch (e) {
      return tarihStr;
    }
  }

  Color _getOnayDurumuRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Colors.orange;
      case 'onaylandı':
        return Colors.green;
      case 'reddedildi':
        return Colors.red;
      case 'tamamlandı':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getOnayDurumuIkonu(String durum) {
    switch (durum.toLowerCase()) {
      case 'onay bekliyor':
        return Icons.schedule;
      case 'onaylandı':
        return Icons.check_circle;
      case 'reddedildi':
        return Icons.cancel;
      case 'tamamlandı':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Sadece "İzin İstek" süreçleri için detay sayfasına git
          if (talep.onayTipi.toLowerCase().contains('izin')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (ctx) => IzinIstekDetayScreen(
                  talepId: talep.onayKayitID,
                  onayTipi: talep.onayTipi,
                ),
              ),
            );
          }
          // Diğer süreç türleri için şimdilik tepki verme
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sol taraf - Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Süreç No
                    Row(
                      children: [
                        Text(
                          'Süreç No: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${talep.onayKayitID}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gradientStart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Talep Türü
                    Row(
                      children: [
                        Text(
                          'Talep Türü: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            talep.onayTipi,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gradientStart,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Talep Eden
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Talep Eden: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            talep.olusturanKisi,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Görev Yeri ve Görevi
                    Text(
                      '${talep.gorevYeri ?? '-'} - ${talep.gorevi ?? '-'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Tarih ve Onay Durumu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTarih(talep.olusturmaTarihi),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getOnayDurumuRengi(
                              talep.onayDurumu,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getOnayDurumuIkonu(talep.onayDurumu),
                                size: 14,
                                color: _getOnayDurumuRengi(talep.onayDurumu),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                talep.onayDurumu,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getOnayDurumuRengi(talep.onayDurumu),
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
              // Sağ taraf - Büyüktür ikonu
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class TalepTuruCard extends ConsumerWidget {
  final TalepTuru talep;

  const TalepTuruCard({Key? key, required this.talep}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        context.go(talep.routePath);
      },
      child: Card(
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, top: 8, bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // İkon kutusu - daha büyük
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(talep.icon, size: 52, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Etiket - kelimeleri satır bazında ayır
              Expanded(flex: 2, child: Center(child: _buildLabel(talep.label))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      textAlign: TextAlign.center,
      softWrap: true,
      style: const TextStyle(
        color: Color(0xFF2D3748),
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Talep Eden Seçim Widget'ı - BottomSheet içinde kullanılır
class _TalepEdenSecimWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String selectedTalepEden;
  final Function(String) onSelected;

  const _TalepEdenSecimWidget({
    required this.scrollController,
    required this.selectedTalepEden,
    required this.onSelected,
  });

  @override
  ConsumerState<_TalepEdenSecimWidget> createState() =>
      _TalepEdenSecimWidgetState();
}

class _TalepEdenSecimWidgetState extends ConsumerState<_TalepEdenSecimWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Personel> _filterPersoneller(List<Personel> personeller) {
    if (_searchQuery.isEmpty) {
      return personeller;
    }

    final query = _searchQuery.toLowerCase().trim();
    return personeller.where((personel) {
      final fullName = personel.fullName.toLowerCase();
      final unvan = personel.unvan?.toLowerCase() ?? '';
      return fullName.contains(query) || unvan.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final personellerAsync = ref.watch(personellerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Başlık
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Talep Eden Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          // Arama kutusu
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Personel ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF014B92)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF014B92),
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Personel listesi
          Expanded(
            child: personellerAsync.when(
              data: (personeller) {
                final filteredPersoneller = _filterPersoneller(personeller);

                if (filteredPersoneller.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: widget.scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: filteredPersoneller.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final personel = filteredPersoneller[index];
                    final isSelected =
                        widget.selectedTalepEden == personel.fullName;

                    return ListTile(
                      onTap: () => widget.onSelected(personel.fullName),
                      tileColor: isSelected
                          ? const Color(0xFF014B92).withOpacity(0.1)
                          : null,
                      title: Text(
                        personel.fullName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 15,
                          color: isSelected
                              ? const Color(0xFF014B92)
                              : Colors.black87,
                        ),
                      ),
                      subtitle: personel.unvan != null
                          ? Text(
                              personel.unvan!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF014B92))
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hata: $error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

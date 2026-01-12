import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';
import 'package:esas_v1/features/talep/screens/widgets/gelen_kutusu_karti.dart';

/// Gelen Kutusu tab içeriği - Devam Eden ve Tamamlanan tab'ları ile
class GelenKutusuContent extends ConsumerStatefulWidget {
  const GelenKutusuContent({super.key});

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
              GelenKutusuListesi(key: _devamEdenKey, tip: 2),
              // Tamamlanan (tip: 3)
              GelenKutusuListesi(key: _tamamlananKey, tip: 3),
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

  const GelenKutusuListesi({super.key, required this.tip});

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

  // Seçilen görev yerleri - Çoklu seçim (String olarak görev yeri adı)
  final Set<String> _selectedGorevYerleri = {};

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
            mainAxisSize: MainAxisSize.max,
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
                    const SizedBox(width: 64),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
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

  @override
  Widget build(BuildContext context) {
    final asyncValue = widget.tip == 2
        ? ref.watch(devamEdenGelenKutusuProvider)
        : ref.watch(tamamlananGelenKutusuProvider);

    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => RefreshIndicator(
        onRefresh: () async {
          if (widget.tip == 2) {
            ref.invalidate(devamEdenGelenKutusuProvider);
          } else {
            ref.invalidate(tamamlananGelenKutusuProvider);
          }
          // Provider'ın yeniden yüklenmesini bekle
          await Future.delayed(const Duration(milliseconds: 100));
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
                    Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    Text(
                      _getHataBasligi(error.toString()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getHataMesaji(error.toString()),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.tip == 2) {
                          ref.invalidate(devamEdenGelenKutusuProvider);
                        } else {
                          ref.invalidate(tamamlananGelenKutusuProvider);
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientStart,
                        foregroundColor: Colors.white,
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
              return GelenKutusuKarti(talep: talep);
            },
          ),
        );
      },
    );
  }
}

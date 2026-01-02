import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/egitim_istek/widgets/price_input_widget.dart';
import 'package:esas_v1/features/satin_alma/models/para_birimi.dart';
import 'package:esas_v1/features/satin_alma/models/odeme_turu.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/common/widgets/odeme_sekli_widget.dart';
import 'package:esas_v1/common/widgets/ders_saati_spinner_widget.dart';

class EgitimUcretleriScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const EgitimUcretleriScreen({Key? key, this.initialData}) : super(key: key);

  @override
  ConsumerState<EgitimUcretleriScreen> createState() =>
      _EgitimUcretleriScreenState();
}

class _EgitimUcretleriScreenState extends ConsumerState<EgitimUcretleriScreen> {
  final TextEditingController _egitimUcretiAnaController =
      TextEditingController();
  final TextEditingController _egitimUcretiKusuratController =
      TextEditingController();
  final TextEditingController _ulasimUcretiAnaController =
      TextEditingController();
  final TextEditingController _ulasimUcretiKusuratController =
      TextEditingController();
  final TextEditingController _konaklamaUcretiAnaController =
      TextEditingController();
  final TextEditingController _konaklamaUcretiKusuratController =
      TextEditingController();
  final TextEditingController _yemekUcretiAnaController =
      TextEditingController();
  final TextEditingController _yemekUcretiKusuratController =
      TextEditingController();
  final TextEditingController _kisiBasiToplamAnaController =
      TextEditingController();
  final TextEditingController _kisiBasiToplamKusuratController =
      TextEditingController();
  final TextEditingController _genelToplamAnaController =
      TextEditingController();
  final TextEditingController _genelToplamKusuratController =
      TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _hesapAdiController = TextEditingController();
  final TextEditingController _digerEkBilgilerController =
      TextEditingController();

  ParaBirimi? _selectedParaBirimi;
  ParaBirimi? _selectedUlasimParaBirimi;
  ParaBirimi? _selectedKonaklamaParaBirimi;
  ParaBirimi? _selectedYemekParaBirimi;
  OdemeTuru? _selectedOdemeTuru;
  bool _vadeli = false;
  int _odemeVadesi = 1;
  bool _dontShowWarningAgain = false;

  // Döviz kurları
  double _egitimKuru = 1.0;
  double _ulasimKuru = 1.0;
  double _konaklamaKuru = 1.0;
  double _yemekKuru = 1.0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Fiyat değişikliklerini dinle ve otomatik hesapla
    _egitimUcretiAnaController.addListener(_calculateTotals);
    _egitimUcretiKusuratController.addListener(_calculateTotals);
    _ulasimUcretiAnaController.addListener(_calculateTotals);
    _ulasimUcretiKusuratController.addListener(_calculateTotals);
    _konaklamaUcretiAnaController.addListener(_calculateTotals);
    _konaklamaUcretiKusuratController.addListener(_calculateTotals);
    _yemekUcretiAnaController.addListener(_calculateTotals);
    _yemekUcretiKusuratController.addListener(_calculateTotals);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateExchangeRates();
      _loadDefaultOdemeTuru();
      _loadDefaultParaBirimleri();
      _showAcademicYearWarningBottomSheet();
    });
  }

  Future<void> _updateExchangeRates() async {
    try {
      final repo = ref.read(satinAlmaRepositoryProvider);
      await repo.guncelleMerkezBankasiDovizKurlari();
      debugPrint('Döviz kurları güncellendi');
    } catch (e) {
      debugPrint('Döviz kurları güncellenirken hata: $e');
    }
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _egitimUcretiAnaController.text = data['egitimUcretiAna'] ?? '';
      _egitimUcretiKusuratController.text = data['egitimUcretiKusurat'] ?? '';
      _ulasimUcretiAnaController.text = data['ulasimUcretiAna'] ?? '';
      _ulasimUcretiKusuratController.text = data['ulasimUcretiKusurat'] ?? '';
      _konaklamaUcretiAnaController.text = data['konaklamaUcretiAna'] ?? '';
      _konaklamaUcretiKusuratController.text =
          data['konaklamaUcretiKusurat'] ?? '';
      _yemekUcretiAnaController.text = data['yemekUcretiAna'] ?? '';
      _yemekUcretiKusuratController.text = data['yemekUcretiKusurat'] ?? '';
      _kisiBasiToplamAnaController.text = data['kisiBasiToplamAna'] ?? '';
      _kisiBasiToplamKusuratController.text =
          data['kisiBasiToplamKusurat'] ?? '';
      _genelToplamAnaController.text = data['genelToplamAna'] ?? '';
      _genelToplamKusuratController.text = data['genelToplamKusurat'] ?? '';
      _ibanController.text = data['iban'] ?? '';
      _hesapAdiController.text = data['hesapAdi'] ?? '';
      _digerEkBilgilerController.text = data['digerEkBilgiler'] ?? '';
      _selectedParaBirimi = data['selectedParaBirimi'];
      _selectedUlasimParaBirimi = data['selectedUlasimParaBirimi'];
      _selectedKonaklamaParaBirimi = data['selectedKonaklamaParaBirimi'];
      _selectedYemekParaBirimi = data['selectedYemekParaBirimi'];
      _selectedOdemeTuru = data['selectedOdemeTuru'];
      _vadeli = data['vadeli'] ?? false;
      _odemeVadesi = data['odemeVadesi'] ?? 1;
    }
  }

  Future<void> _loadDefaultOdemeTuru() async {
    try {
      // API'den ödeme türlerini yükle
      final odemeTurleri = await ref.read(odemeTurleriProvider.future);

      // İlk seçeneği (Nakit) varsayılan olarak ayarla
      if (odemeTurleri.isNotEmpty && _selectedOdemeTuru == null && mounted) {
        setState(() {
          _selectedOdemeTuru = odemeTurleri.first; // İlk seçenek (Nakit)
        });
      }
    } catch (e) {
      // Hata durumunda sessizce geç
      debugPrint('Ödeme türleri yüklenemedi: $e');
    }
  }

  Future<void> _loadDefaultParaBirimleri() async {
    try {
      // API'den para birimlerini yükle
      final paraBirimleri = await ref.read(paraBirimlerProvider.future);

      // "Türk Lirası" veya "TRY" olanı bul, bulamazsan ilkini al
      ParaBirimi? turkLirasi;
      if (paraBirimleri.isNotEmpty) {
        turkLirasi = paraBirimleri.firstWhere(
          (pb) =>
              pb.birimAdi.toLowerCase().contains('türk') ||
              pb.birimAdi.toLowerCase().contains('turk') ||
              pb.kod.toUpperCase() == 'TRY' ||
              pb.kod.toUpperCase() == 'TL',
          orElse: () => paraBirimleri.first,
        );
      }

      // Varsayılan para birimini sadece initialData yoksa ayarla
      if (turkLirasi != null && mounted && widget.initialData == null) {
        setState(() {
          // Tüm para birimi alanlarını "Türk Lirası" olarak ayarla
          _selectedParaBirimi = turkLirasi;
          _selectedUlasimParaBirimi = turkLirasi;
          _selectedKonaklamaParaBirimi = turkLirasi;
          _selectedYemekParaBirimi = turkLirasi;
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
      debugPrint('Ödeme türleri yüklenemedi: $e');
    }
  }

  Future<void> _fetchDovizKuru(
    ParaBirimi? paraBirimi,
    Function(double) onKurFetched,
  ) async {
    if (paraBirimi == null) return;

    final kod = paraBirimi.kod.toUpperCase();
    // TRY veya TL ise kur 1.0
    if (kod == 'TRY' || kod == 'TL') {
      onKurFetched(1.0);
      return;
    }

    try {
      final repo = ref.read(satinAlmaRepositoryProvider);
      final dovizKuru = await repo.getDovizKuru(kod);
      if (mounted) {
        onKurFetched(dovizKuru.kur);
        _calculateTotals();
      }
    } catch (e) {
      debugPrint('Döviz kuru yüklenemedi: $e');
      onKurFetched(1.0);
    }
  }

  void _calculateTotals() {
    double egitimTL = _calculateTLAmount(
      _egitimUcretiAnaController.text,
      _egitimUcretiKusuratController.text,
      _egitimKuru,
    );

    double ulasimTL = _calculateTLAmount(
      _ulasimUcretiAnaController.text,
      _ulasimUcretiKusuratController.text,
      _ulasimKuru,
    );

    double konaklamaTL = _calculateTLAmount(
      _konaklamaUcretiAnaController.text,
      _konaklamaUcretiKusuratController.text,
      _konaklamaKuru,
    );

    double yemekTL = _calculateTLAmount(
      _yemekUcretiAnaController.text,
      _yemekUcretiKusuratController.text,
      _yemekKuru,
    );

    // Kişi başı toplam
    double kisiBasiToplam = egitimTL + ulasimTL + konaklamaTL + yemekTL;

    // Kişi başı toplam alanlarını doldur
    final kisiBasiAna = kisiBasiToplam.floor();
    final kisiBasiKusurat = ((kisiBasiToplam - kisiBasiAna) * 100).round();

    _kisiBasiToplamAnaController.text = kisiBasiAna.toString();
    _kisiBasiToplamKusuratController.text = kisiBasiKusurat.toString().padLeft(
      2,
      '0',
    );

    // Genel toplam - burada personel sayısını ekleyeceğiz (şimdilik 1)
    // Bu değer dışarıdan gelecek
    _genelToplamAnaController.text = kisiBasiAna.toString();
    _genelToplamKusuratController.text = kisiBasiKusurat.toString().padLeft(
      2,
      '0',
    );
  }

  double _calculateTLAmount(String ana, String kusurat, double kur) {
    final anaInt = int.tryParse(ana) ?? 0;
    final kusuratInt = int.tryParse(kusurat) ?? 0;
    final amount = anaInt + (kusuratInt / 100);
    return amount * kur;
  }

  void _showAcademicYearWarningBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          width: double.infinity,
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
              const Icon(
                Icons.info_outlined,
                color: AppColors.gradientStart,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Bulunduğunuz akademik yıl içerisinde toplamda on bin (10.000) TL\'yi geçen eğitim talepleri için, talebiniz onaylandıktan sonra insan kaynakları biriminde eğitim protokolü imzalamanız gerekmektedir.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) +
                      3,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _dontShowWarningAgain = !_dontShowWarningAgain;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.65,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 56,
                          height: 28,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 56,
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: _dontShowWarningAgain
                                      ? AppColors.gradientStart
                                      : Colors.grey.shade300,
                                ),
                              ),
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                alignment: _dontShowWarningAgain
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Uyarıyı bir daha gösterme',
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _egitimUcretiAnaController.dispose();
    _egitimUcretiKusuratController.dispose();
    _ulasimUcretiAnaController.dispose();
    _ulasimUcretiKusuratController.dispose();
    _konaklamaUcretiAnaController.dispose();
    _konaklamaUcretiKusuratController.dispose();
    _yemekUcretiAnaController.dispose();
    _yemekUcretiKusuratController.dispose();
    _kisiBasiToplamAnaController.dispose();
    _kisiBasiToplamKusuratController.dispose();
    _genelToplamAnaController.dispose();
    _genelToplamKusuratController.dispose();
    _ibanController.dispose();
    _hesapAdiController.dispose();
    _digerEkBilgilerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Eğitim Ücretleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KDV Uyarısı
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 3, 16, 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outlined,
                      color: AppColors.gradientStart,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'KDV dahil fiyatları giriniz',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.fontSize ??
                                  14) +
                              2,
                          color: AppColors.gradientStart,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kişi Başı Ücretler',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Row for Fiyat (57%) and Para Birimi (43%)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Fiyat Input
                        Expanded(
                          flex: 4,
                          child: PriceInputWidget(
                            title: 'Eğitimin Ücreti',
                            mainController: _egitimUcretiAnaController,
                            decimalController: _egitimUcretiKusuratController,
                            inputsOffset: 4,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Para Birimi (same design as Product Add)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Para Birimi',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showParaBirimiBottomSheet,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedParaBirimi != null
                                              ? '${_selectedParaBirimi!.birimAdi} (${_selectedParaBirimi!.kod})'
                                              : 'Seçiniz',
                                          style: TextStyle(
                                            color: _selectedParaBirimi != null
                                                ? Colors.black87
                                                : Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Row for Ulaşım Ücreti (57%) and Para Birimi (43%)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Ulaşım Ücreti Input
                        Expanded(
                          flex: 4,
                          child: PriceInputWidget(
                            title: 'Ulaşım Ücreti',
                            mainController: _ulasimUcretiAnaController,
                            decimalController: _ulasimUcretiKusuratController,
                            inputsOffset: 4,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Para Birimi for Ulaşım
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Para Birimi',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showUlasimParaBirimiBottomSheet,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedUlasimParaBirimi != null
                                              ? '${_selectedUlasimParaBirimi!.birimAdi} (${_selectedUlasimParaBirimi!.kod})'
                                              : 'Seçiniz',
                                          style: TextStyle(
                                            color:
                                                _selectedUlasimParaBirimi !=
                                                    null
                                                ? Colors.black87
                                                : Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Row for Konaklama Ücreti (57%) and Para Birimi (43%)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Konaklama Ücreti Input
                        Expanded(
                          flex: 4,
                          child: PriceInputWidget(
                            title: 'Konaklama Ücreti',
                            mainController: _konaklamaUcretiAnaController,
                            decimalController:
                                _konaklamaUcretiKusuratController,
                            inputsOffset: 4,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Para Birimi for Konaklama
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Para Birimi',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showKonaklamaParaBirimiBottomSheet,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedKonaklamaParaBirimi != null
                                              ? '${_selectedKonaklamaParaBirimi!.birimAdi} (${_selectedKonaklamaParaBirimi!.kod})'
                                              : 'Seçiniz',
                                          style: TextStyle(
                                            color:
                                                _selectedKonaklamaParaBirimi !=
                                                    null
                                                ? Colors.black87
                                                : Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Row for Yemek Ücreti (57%) and Para Birimi (43%)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Yemek Ücreti Input
                        Expanded(
                          flex: 4,
                          child: PriceInputWidget(
                            title: 'Yemek Ücreti',
                            mainController: _yemekUcretiAnaController,
                            decimalController: _yemekUcretiKusuratController,
                            inputsOffset: 4,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Para Birimi for Yemek
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Para Birimi',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.fontSize ??
                                              14) +
                                          1,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showYemekParaBirimiBottomSheet,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedYemekParaBirimi != null
                                              ? '${_selectedYemekParaBirimi!.birimAdi} (${_selectedYemekParaBirimi!.kod})'
                                              : 'Seçiniz',
                                          style: TextStyle(
                                            color:
                                                _selectedYemekParaBirimi != null
                                                ? Colors.black87
                                                : Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Row for Total Fields (50% each)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Kişi Başı Toplam TL Ücret
                        Expanded(
                          flex: 1,
                          child: PriceInputWidget(
                            title: 'Kişi Başı Toplam TL Ücret',
                            mainController: _kisiBasiToplamAnaController,
                            decimalController: _kisiBasiToplamKusuratController,
                            inputsOffset: 4,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Genel Toplam TL Ücret
                        Expanded(
                          flex: 1,
                          child: PriceInputWidget(
                            title: 'Genel Toplam TL Ücret',
                            mainController: _genelToplamAnaController,
                            decimalController: _genelToplamKusuratController,
                            inputsOffset: 4,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: OdemeSekliWidget(
                            title: 'Ödeme Şekli',
                            selectedOdemeTuru: _selectedOdemeTuru,
                            onOdemeTuruSelected: (val) {
                              setState(() {
                                _selectedOdemeTuru = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Switch(
                              value: _vadeli,
                              activeColor: AppColors.gradientStart,
                              inactiveTrackColor: Colors.white,
                              onChanged: (v) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _vadeli = v;
                                  if (!v) {
                                    _odemeVadesi = 1;
                                  }
                                });
                              },
                            ),
                            const Text(
                              'Vadeli',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_vadeli) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DersSaatiSpinnerWidget(
                            label: 'Ödeme Vadesi',
                            minValue: 1,
                            maxValue: 999,
                            initialValue: _odemeVadesi,
                            onValueChanged: (value) {
                              setState(() {
                                _odemeVadesi = value;
                              });
                            },
                          ),
                          const SizedBox(width: 20),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Gün',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IBAN',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _ibanController,
                          decoration: InputDecoration(
                            hintText: 'TR',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesap Adı',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hesapAdiController,
                          decoration: InputDecoration(
                            hintText: 'Hesap adını giriniz',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diğer Ek Bilgiler',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.fontSize ??
                                        14) +
                                    1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _digerEkBilgilerController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Diğer ek bilgileri giriniz',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.gradientStart,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final data = {
                              'egitimUcretiAna':
                                  _egitimUcretiAnaController.text,
                              'egitimUcretiKusurat':
                                  _egitimUcretiKusuratController.text,
                              'ulasimUcretiAna':
                                  _ulasimUcretiAnaController.text,
                              'ulasimUcretiKusurat':
                                  _ulasimUcretiKusuratController.text,
                              'konaklamaUcretiAna':
                                  _konaklamaUcretiAnaController.text,
                              'konaklamaUcretiKusurat':
                                  _konaklamaUcretiKusuratController.text,
                              'yemekUcretiAna': _yemekUcretiAnaController.text,
                              'yemekUcretiKusurat':
                                  _yemekUcretiKusuratController.text,
                              'kisiBasiToplamAna':
                                  _kisiBasiToplamAnaController.text,
                              'kisiBasiToplamKusurat':
                                  _kisiBasiToplamKusuratController.text,
                              'genelToplamAna': _genelToplamAnaController.text,
                              'genelToplamKusurat':
                                  _genelToplamKusuratController.text,
                              'iban': _ibanController.text,
                              'hesapAdi': _hesapAdiController.text,
                              'digerEkBilgiler':
                                  _digerEkBilgilerController.text,
                              'selectedParaBirimi': _selectedParaBirimi,
                              'selectedUlasimParaBirimi':
                                  _selectedUlasimParaBirimi,
                              'selectedKonaklamaParaBirimi':
                                  _selectedKonaklamaParaBirimi,
                              'selectedYemekParaBirimi':
                                  _selectedYemekParaBirimi,
                              'selectedOdemeTuru': _selectedOdemeTuru,
                              'vadeli': _vadeli,
                              'odemeVadesi': _odemeVadesi,
                            };
                            Navigator.pop(context, data);
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showParaBirimiBottomSheet() async {
    FocusScope.of(context).unfocus();
    final paraBirimlerAsync = ref.read(paraBirimlerProvider);

    if (paraBirimlerAsync.hasValue) {
      _openParaBirimiBottomSheet();
      return;
    }

    BrandedLoadingDialog.show(context);
    try {
      await ref.read(paraBirimlerProvider.future);
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        _openParaBirimiBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Para birimleri yüklenemedi: $e')),
        );
      }
    }
  }

  void _openParaBirimiBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncParaBirimleri = ref.watch(paraBirimlerProvider);

              return asyncParaBirimleri.when(
                loading: () => SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Para birimleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (paraBirimleri) {
                  final sheetHeight = (120 + paraBirimleri.length * 56.0).clamp(
                    220.0,
                    MediaQuery.of(ctx).size.height * 0.65,
                  );

                  return SizedBox(
                    height: sheetHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Para Birimi Seçiniz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.fontSize ??
                                          16) +
                                      2,
                                ),
                          ),
                        ),
                        Expanded(
                          child: paraBirimleri.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: paraBirimleri.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = paraBirimleri[index];
                                    final isSelected =
                                        _selectedParaBirimi?.id == item.id;
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        '${item.birimAdi} (${item.kod})',
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColors.gradientStart
                                              : Colors.black87,
                                          fontSize:
                                              (Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.fontSize ??
                                                  16) +
                                              2,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedParaBirimi = item;
                                        });
                                        // Döviz kurunu çek ve hesapla
                                        _fetchDovizKuru(item, (kur) {
                                          setState(() {
                                            _egitimKuru = kur;
                                          });
                                        });
                                        // Unfocus after selection as per global rule
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showUlasimParaBirimiBottomSheet() async {
    FocusScope.of(context).unfocus();
    final paraBirimlerAsync = ref.read(paraBirimlerProvider);

    if (paraBirimlerAsync.hasValue) {
      _openUlasimParaBirimiBottomSheet();
      return;
    }

    BrandedLoadingDialog.show(context);
    try {
      await ref.read(paraBirimlerProvider.future);
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        _openUlasimParaBirimiBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Para birimleri yüklenemedi: $e')),
        );
      }
    }
  }

  void _openUlasimParaBirimiBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncParaBirimleri = ref.watch(paraBirimlerProvider);

              return asyncParaBirimleri.when(
                loading: () => SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Para birimleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (paraBirimleri) {
                  final sheetHeight = (120 + paraBirimleri.length * 56.0).clamp(
                    220.0,
                    MediaQuery.of(ctx).size.height * 0.65,
                  );

                  return SizedBox(
                    height: sheetHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Para Birimi Seçiniz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.fontSize ??
                                          16) +
                                      2,
                                ),
                          ),
                        ),
                        Expanded(
                          child: paraBirimleri.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: paraBirimleri.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (_, index) {
                                    final item = paraBirimleri[index];
                                    final isSelected =
                                        _selectedUlasimParaBirimi?.id ==
                                        item.id;

                                    return ListTile(
                                      title: Text(
                                        item.birimAdi,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  (Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.fontSize ??
                                                      16) +
                                                  2,
                                            ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedUlasimParaBirimi = item;
                                        });
                                        // Döviz kurunu çek ve hesapla
                                        _fetchDovizKuru(item, (kur) {
                                          setState(() {
                                            _ulasimKuru = kur;
                                          });
                                        });
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showKonaklamaParaBirimiBottomSheet() async {
    FocusScope.of(context).unfocus();
    final paraBirimlerAsync = ref.read(paraBirimlerProvider);

    if (paraBirimlerAsync.hasValue) {
      _openKonaklamaParaBirimiBottomSheet();
      return;
    }

    BrandedLoadingDialog.show(context);
    try {
      await ref.read(paraBirimlerProvider.future);
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        _openKonaklamaParaBirimiBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Para birimleri yüklenemedi: $e')),
        );
      }
    }
  }

  void _openKonaklamaParaBirimiBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncParaBirimleri = ref.watch(paraBirimlerProvider);

              return asyncParaBirimleri.when(
                loading: () => SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Para birimleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (paraBirimleri) {
                  final sheetHeight = (120 + paraBirimleri.length * 56.0).clamp(
                    220.0,
                    MediaQuery.of(ctx).size.height * 0.65,
                  );

                  return SizedBox(
                    height: sheetHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Para Birimi Seçiniz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.fontSize ??
                                          16) +
                                      2,
                                ),
                          ),
                        ),
                        Expanded(
                          child: paraBirimleri.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: paraBirimleri.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (_, index) {
                                    final item = paraBirimleri[index];
                                    final isSelected =
                                        _selectedKonaklamaParaBirimi?.id ==
                                        item.id;

                                    return ListTile(
                                      title: Text(
                                        item.birimAdi,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  (Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.fontSize ??
                                                      16) +
                                                  2,
                                            ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedKonaklamaParaBirimi = item;
                                        });
                                        // Döviz kurunu çek ve hesapla
                                        _fetchDovizKuru(item, (kur) {
                                          setState(() {
                                            _konaklamaKuru = kur;
                                          });
                                        });
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showYemekParaBirimiBottomSheet() async {
    FocusScope.of(context).unfocus();
    final paraBirimlerAsync = ref.read(paraBirimlerProvider);

    if (paraBirimlerAsync.hasValue) {
      _openYemekParaBirimiBottomSheet();
      return;
    }

    BrandedLoadingDialog.show(context);
    try {
      await ref.read(paraBirimlerProvider.future);
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        _openYemekParaBirimiBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Para birimleri yüklenemedi: $e')),
        );
      }
    }
  }

  void _openYemekParaBirimiBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncParaBirimleri = ref.watch(paraBirimlerProvider);

              return asyncParaBirimleri.when(
                loading: () => SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Para birimleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (paraBirimleri) {
                  final sheetHeight = (120 + paraBirimleri.length * 56.0).clamp(
                    220.0,
                    MediaQuery.of(ctx).size.height * 0.65,
                  );

                  return SizedBox(
                    height: sheetHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Para Birimi Seçiniz',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      (Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.fontSize ??
                                          16) +
                                      2,
                                ),
                          ),
                        ),
                        Expanded(
                          child: paraBirimleri.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: paraBirimleri.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (_, index) {
                                    final item = paraBirimleri[index];
                                    final isSelected =
                                        _selectedYemekParaBirimi?.id == item.id;

                                    return ListTile(
                                      title: Text(
                                        item.birimAdi,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  (Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.fontSize ??
                                                      16) +
                                                  2,
                                            ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: AppColors.gradientStart,
                                            )
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          _selectedYemekParaBirimi = item;
                                        });
                                        // Döviz kurunu çek ve hesapla
                                        _fetchDovizKuru(item, (kur) {
                                          setState(() {
                                            _yemekKuru = kur;
                                          });
                                        });
                                        FocusScope.of(context).unfocus();
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

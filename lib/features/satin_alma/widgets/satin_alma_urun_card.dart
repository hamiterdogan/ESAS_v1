import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/core/utils/thousands_input_formatter.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';
import 'package:esas_v1/features/satin_alma/models/para_birimi.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';

class SatinAlmaUrunCard extends ConsumerStatefulWidget {
  final SatinAlmaUrunBilgisi? initialBilgi;

  const SatinAlmaUrunCard({super.key, this.initialBilgi});

  @override
  ConsumerState<SatinAlmaUrunCard> createState() => SatinAlmaUrunCardState();
}

class SatinAlmaUrunCardState extends ConsumerState<SatinAlmaUrunCard> {
  SatinAlmaAnaKategori? _selectedAnaKategori;
  SatinAlmaAltKategori? _selectedAltKategori;
  SatinAlmaOlcuBirim? _selectedOlcuBirim;
  ParaBirimi? _selectedParaBirimi;
  double _dovizKuru = 1.0;
  int _miktar = 1;
  bool _kdvDahilDegil = false;
  int _kdvOrani = 0; // 0 means not selected or 0%

  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _fiyatAnaController = TextEditingController();
  final TextEditingController _fiyatKusuratController = TextEditingController();
  final TextEditingController _toplamFiyatController = TextEditingController();
  final TextEditingController _tlKurFiyatiController = TextEditingController();
  final TextEditingController _toplamTlFiyatiController =
      TextEditingController();

  bool _showingKategoriLoading = false;
  bool _showingAltKategoriLoading = false;
  bool _showingOlcuBirimLoading = false;
  bool _showingParaBirimiLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialBilgi != null) {
      final bilgi = widget.initialBilgi!;
      if (bilgi.anaKategoriId != null) {
        _selectedAnaKategori = SatinAlmaAnaKategori(
          id: bilgi.anaKategoriId!,
          kategori: bilgi.anaKategori ?? '',
          aktif: true,
        );
      }
      if (bilgi.altKategoriId != null) {
        _selectedAltKategori = SatinAlmaAltKategori(
          id: bilgi.altKategoriId!,
          altKategori: bilgi.altKategori ?? '',
          satinAlmaAnaKategoriId: bilgi.anaKategoriId ?? 0,
          aktif: true,
        );
      }
      if (bilgi.olcuBirimiId != null) {
        _selectedOlcuBirim = SatinAlmaOlcuBirim(
          id: bilgi.olcuBirimiId!,
          birimAdi: bilgi.olcuBirimi ?? '',
          kisaltma: bilgi.olcuBirimiKisaltma ?? '',
        );
      }
      if (bilgi.paraBirimiId != null) {
        _selectedParaBirimi = ParaBirimi(
          id: bilgi.paraBirimiId!,
          kod: bilgi.paraBirimiKod ?? '',
          birimAdi: bilgi.paraBirimi ?? '',
          sembol: '',
        );
      }

      _urunAdiController.text = bilgi.urunDetay ?? '';
      _miktar = bilgi.miktar ?? 0;
      _fiyatAnaController.text = bilgi.fiyatAna ?? '';
      _fiyatKusuratController.text = bilgi.fiyatKusurat ?? '';
      _dovizKuru = bilgi.dovizKuru ?? 1.0;
      _kdvDahilDegil = bilgi.kdvDahilDegil;
      _kdvOrani = bilgi.kdvOrani;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateToplamFiyat();
        _updateTlKurFiyati();
      });
    }
  }

  SatinAlmaUrunBilgisi? getData() {
    if (!validateForm()) return null;

    return SatinAlmaUrunBilgisi(
      anaKategori: _selectedAnaKategori?.kategori,
      anaKategoriId: _selectedAnaKategori?.id,
      altKategori: _selectedAltKategori?.altKategori,
      altKategoriId: _selectedAltKategori?.id,
      urunDetay: _urunAdiController.text,
      aciklama: _aciklamaController.text,
      miktar: _miktar,
      olcuBirimi: _selectedOlcuBirim?.birimAdi,
      olcuBirimiId: _selectedOlcuBirim?.id,
      olcuBirimiKisaltma: _selectedOlcuBirim?.kisaltma,
      paraBirimi: _selectedParaBirimi?.birimAdi,
      paraBirimiId: _selectedParaBirimi?.id,
      paraBirimiKod: _selectedParaBirimi?.kod,
      dovizKuru: _dovizKuru,
      fiyatAna: _fiyatAnaController.text,
      fiyatKusurat: _fiyatKusuratController.text,
      toplamFiyat: _toplamFiyatController.text,
      tlKurFiyati: _tlKurFiyatiController.text,
      toplamTlFiyati: _toplamTlFiyatiController.text,
      kdvDahilDegil: _kdvDahilDegil,
      kdvOrani: _kdvOrani,
    );
  }

  bool validateForm() {
    if (_selectedAnaKategori == null) {
      _showErrorBottomSheet('Ürün kategorisi seçiniz');
      return false;
    }
    if (_selectedAltKategori == null) {
      _showErrorBottomSheet('Alt kategorisi seçiniz');
      return false;
    }
    if (_selectedOlcuBirim == null) {
      _showErrorBottomSheet('Birim seçiniz');
      return false;
    }
    if (_fiyatAnaController.text.isEmpty) {
      _showErrorBottomSheet('Birim fiyatı giriniz');
      return false;
    }
    if (_urunAdiController.text.isEmpty) {
      _showErrorBottomSheet('Ürün detay bilgisi giriniz');
      return false;
    }
    if (_kdvDahilDegil && _kdvOrani == 0) {
      _showErrorBottomSheet('KDV Oranı Seçiniz');
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _urunAdiController.dispose();
    _miktarController.dispose();
    _fiyatController.dispose();
    _aciklamaController.dispose();
    _fiyatAnaController.dispose();
    _fiyatKusuratController.dispose();
    _toplamFiyatController.dispose();
    _tlKurFiyatiController.dispose();
    _toplamTlFiyatiController.dispose();
    super.dispose();
  }

  void _showErrorBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Uyarı',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodyMedium?.fontSize ??
                            14) +
                        3,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
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
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAnaKategoriBottomSheet() {
    final kategorilerAsync = ref.read(satinAlmaAnaKategorilerProvider);

    // Eğer data cache'de varsa direkt bottom sheet aç
    if (kategorilerAsync.hasValue) {
      _openAnaKategoriBottomSheet();
      return;
    }

    // Loading'de ise loading dialog göster
    _showingKategoriLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Center(child: BrandedLoadingIndicator(size: 120)),
    );
  }

  void _openAnaKategoriBottomSheet() {
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
              final asyncKategoriler = ref.watch(
                satinAlmaAnaKategorilerProvider,
              );
              return asyncKategoriler.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Kategoriler alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (kategoriler) {
                  final allKategoriler = kategoriler;
                  final TextEditingController searchController =
                      TextEditingController();

                  return _AnaKategoriBottomSheetContent(
                    kategoriler: allKategoriler,
                    selectedKategori: _selectedAnaKategori,
                    onKategoriSelected: (selected) {
                      setState(() {
                        _selectedAnaKategori = selected;
                        _selectedAltKategori = null;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showAltKategoriBottomSheet() {
    if (_selectedAnaKategori == null) return;
    if (_selectedAnaKategori!.id == 0) {
      return;
    }

    final altKategorilerAsync = ref.read(
      satinAlmaAltKategorilerProvider(_selectedAnaKategori!.id),
    );

    // Eğer data cache'de varsa direkt bottom sheet aç
    if (altKategorilerAsync.hasValue) {
      _openAltKategoriBottomSheet();
      return;
    }

    // Loading'de ise loading dialog göster
    _showingAltKategoriLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Center(child: BrandedLoadingIndicator(size: 120)),
    );
  }

  void _openAltKategoriBottomSheet() {
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
              final asyncSubKategoriler = ref.watch(
                satinAlmaAltKategorilerProvider(_selectedAnaKategori!.id),
              );
              return asyncSubKategoriler.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Alt kategoriler alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (altKategoriler) {
                  return _AltKategoriBottomSheetContent(
                    altKategoriler: altKategoriler,
                    selectedAltKategori: _selectedAltKategori,
                    onAltKategoriSelected: (selected) {
                      setState(() {
                        _selectedAltKategori = selected;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showOlcuBirimBottomSheet() {
    final olcuAsync = ref.read(satinAlmaOlcuBirimleriProvider);

    if (olcuAsync.hasValue) {
      _openOlcuBirimBottomSheet();
      return;
    }

    _showingOlcuBirimLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Center(child: BrandedLoadingIndicator(size: 120)),
    );
  }

  void _openOlcuBirimBottomSheet() {
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
              final asyncOlcuBirimleri = ref.watch(
                satinAlmaOlcuBirimleriProvider,
              );

              return asyncOlcuBirimleri.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: BrandedLoadingIndicator(size: 56)),
                ),
                error: (error, stack) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Ölçü birimleri alınamadı',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ),
                ),
                data: (birimler) {
                  final sheetHeight = (120 + birimler.length * 56.0).clamp(
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
                            'Birim Seçiniz',
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
                          child: birimler.isEmpty
                              ? Center(
                                  child: Text(
                                    'Kayıt bulunamadı',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: birimler.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = birimler[index];
                                    final isSelected =
                                        _selectedOlcuBirim?.id == item.id;
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        item.birimAdi,
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
                                          _selectedOlcuBirim = item;
                                        });
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

  void _showParaBirimiBottomSheet() {
    final paraBirimlerAsync = ref.read(paraBirimlerProvider);

    if (paraBirimlerAsync.hasValue) {
      _openParaBirimiBottomSheet();
      return;
    }

    _showingParaBirimiLoading = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => Center(child: BrandedLoadingIndicator(size: 120)),
    );
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
                loading: () => const SizedBox(
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

                                        // Seçim değiştiğinde mevcut değerlerle hemen hesapla
                                        _updateToplamFiyat();

                                        // Güncel kuru alıp tekrar hesapla
                                        _fetchDovizKuru(item.kod);
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

  void _showKdvOraniBottomSheet() {
    final kdvRates = [20, 10, 1];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'KDV Oranı Seçiniz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize:
                        (Theme.of(context).textTheme.titleMedium?.fontSize ??
                            16) +
                        1,
                  ),
                ),
              ),
              ...kdvRates.map(
                (rate) => Column(
                  children: [
                    ListTile(
                      dense: true,
                      title: Text(
                        '%$rate',
                        style: TextStyle(
                          fontWeight: _kdvOrani == rate
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _kdvOrani == rate
                              ? AppColors.gradientStart
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      trailing: _kdvOrani == rate
                          ? const Icon(
                              Icons.check,
                              color: AppColors.gradientStart,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _kdvOrani = rate;
                        });
                        _calculateToplamFiyat();
                        Navigator.pop(context);
                      },
                    ),
                    if (rate != kdvRates.last)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchDovizKuru(String dovizKodu) async {
    // TRY için kur sabit 1.0
    if (dovizKodu == 'TRY') {
      if (!mounted) return;
      setState(() {
        _dovizKuru = 1.0;
      });
      _updateTlKurFiyati();
      return;
    }

    try {
      final repo = ref.read(satinAlmaRepositoryProvider);
      final kur = await repo.getDovizKuru(dovizKodu);
      // API yanlış alan döndürürse kur=0 geliyor; bu durumda eski kuru koru.
      if (kur.kur <= 0) {
        // Hata durumunda 0 gösterme, önceki kuru koru
        if (mounted) {
          _updateTlKurFiyati();
        }
        return;
      }
      if (mounted) {
        setState(() {
          _dovizKuru = kur.kur;
        });
        _updateTlKurFiyati();
      }
    } catch (e) {
      if (mounted) {
        // Hata durumunda mevcut kuru bozma, sadece UI güncelle
        _updateTlKurFiyati();
      }
    }
  }

  void _updateTlKurFiyati() {
    try {
      final numberFormat = NumberFormat('#,##0.000', 'tr_TR');
      final kurFormatted = numberFormat.format(_dovizKuru);
      if (mounted) {
        _tlKurFiyatiController.text = '$kurFormatted TRY';
      }
    } catch (e) {
      if (mounted) {
        _tlKurFiyatiController.text = '0,00 TRY';
      }
    }
    // TL toplam fiyatını da güncelle
    _updateTlToplamFiyat();
  }

  void _updateTlToplamFiyat() {
    try {
      final fiyatAnaText = _fiyatAnaController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final fiyatAna = double.tryParse(fiyatAnaText) ?? 0;
      final fiyatKusurat = double.tryParse(_fiyatKusuratController.text) ?? 0;
      double birimFiyat = fiyatAna + (fiyatKusurat / 100);

      // KDV Ekleme mantığı
      if (_kdvDahilDegil && _kdvOrani > 0) {
        birimFiyat += birimFiyat * (_kdvOrani / 100);
      }

      // Toplam TL = miktar * efektif birim fiyatı * TL kur
      final toplam = _miktar * birimFiyat;
      final toplamTl = toplam * _dovizKuru;

      final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
      final toplamTlFormatted = numberFormat.format(toplamTl);

      if (mounted) {
        _toplamTlFiyatiController.text = '$toplamTlFormatted TL';
      }
    } catch (e) {
      if (mounted) {
        _toplamTlFiyatiController.text = '0,00 TL';
      }
    }
  }

  void _updateToplamFiyat() {
    try {
      final fiyatAnaText = _fiyatAnaController.text
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final fiyatAna = double.tryParse(fiyatAnaText) ?? 0;
      final fiyatKusurat = double.tryParse(_fiyatKusuratController.text) ?? 0;
      double birimFiyat = fiyatAna + (fiyatKusurat / 100);

      // KDV Ekleme mantığı
      if (_kdvDahilDegil && _kdvOrani > 0) {
        birimFiyat += birimFiyat * (_kdvOrani / 100);
      }

      final paraBirimiKodu = _selectedParaBirimi?.kod ?? 'TRY';

      // Kullanıcı birim fiyatı hangi para biriminde girdiyse, ekranda toplamı aynı para biriminde göster.
      final toplam = _miktar * birimFiyat;
      final numberFormat = NumberFormat('#,##0.00', 'tr_TR');
      final toplamFormatted = numberFormat.format(toplam);

      if (mounted) {
        if (_miktar > 0 && birimFiyat > 0) {
          _toplamFiyatController.text = '$toplamFormatted $paraBirimiKodu';
        } else {
          _toplamFiyatController.text = '0,00 $paraBirimiKodu';
        }
      }

      // TL cinsinden toplam fiyat hesapla
      _updateTlToplamFiyat();
    } catch (e) {
      if (mounted) {
        _toplamFiyatController.text = '0.00 TRY';
      }
    }
  }

  void _calculateToplamFiyat() {
    _updateToplamFiyat();
  }

  @override
  Widget build(BuildContext context) {
    // Listen ana kategoriler yükleme
    ref.listen(satinAlmaAnaKategorilerProvider, (previous, next) {
      if (_showingKategoriLoading && next.hasValue) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // dialog kapat
        }
        _showingKategoriLoading = false;
        _openAnaKategoriBottomSheet();
      }
    });

    // Listen alt kategoriler yükleme
    if (_selectedAnaKategori != null && _selectedAnaKategori!.id != 0) {
      ref.listen(satinAlmaAltKategorilerProvider(_selectedAnaKategori!.id), (
        previous,
        next,
      ) {
        if (_showingAltKategoriLoading && next.hasValue) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // dialog kapat
          }
          _showingAltKategoriLoading = false;
          _openAltKategoriBottomSheet();
        }
      });
    }

    // Listen ölçü birimleri yükleme
    ref.listen(satinAlmaOlcuBirimleriProvider, (previous, next) {
      if (_showingOlcuBirimLoading && next.hasValue) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showingOlcuBirimLoading = false;
        _openOlcuBirimBottomSheet();
      }
    });

    // Listen para birimleri yükleme
    ref.listen(paraBirimlerProvider, (previous, next) {
      final paraBirimleri = next.value;
      if (next.hasValue && paraBirimleri != null && paraBirimleri.isNotEmpty) {
        // İlk para birimini otomatik seç (TRY)
        if (_selectedParaBirimi == null) {
          final tryBirimi = paraBirimleri.firstWhere(
            (p) => p.kod == 'TRY',
            orElse: () => paraBirimleri.first,
          );
          setState(() {
            _selectedParaBirimi = tryBirimi;
            _dovizKuru = 1.0; // TRY'nin kuru her zaman 1.0
          });
          _calculateToplamFiyat();
          _updateTlKurFiyati();
        }
      }
      if (_showingParaBirimiLoading && next.hasValue) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _showingParaBirimiLoading = false;
        _openParaBirimiBottomSheet();
      }
    });

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            Colors.white,
            0.65,
          ) ??
          Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün Kategorisi
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Ürün Kategorisi',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showAnaKategoriBottomSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _selectedAnaKategori == null
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedAnaKategori?.kategori ?? 'Ürün kategorisi',
                        style: TextStyle(
                          color: _selectedAnaKategori == null
                              ? Colors.grey.shade600
                              : Colors.black,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ürün Alt Kategorisi
            if (_selectedAnaKategori != null &&
                _selectedAnaKategori!.id != 0) ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Ürün Alt Kategorisi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            1,
                      ),
                    ),
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize:
                            (Theme.of(context).textTheme.titleSmall?.fontSize ??
                                14) +
                            1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showAltKategoriBottomSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: _selectedAltKategori == null
                          ? Colors.red.shade300
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedAltKategori?.altKategori ??
                              'Ürün alt kategorisi',
                          style: TextStyle(
                            color: _selectedAltKategori == null
                                ? Colors.grey.shade600
                                : Colors.black,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ürün Detay
            Text(
              'Ürün Detay',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urunAdiController,
              decoration: InputDecoration(
                hintText: 'Ürün detayını giriniz',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gradientStart),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Miktar Spinner
            DersSaatiSpinnerWidget(
              label: 'Miktar',
              minValue: 1,
              maxValue: 99999,
              initialValue: _miktar,
              onValueChanged: (value) {
                setState(() {
                  _miktar = value;
                });
                _calculateToplamFiyat();
              },
            ),

            const SizedBox(height: 16),

            // Birim (Full Width)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Birim',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showOlcuBirimBottomSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: _selectedOlcuBirim == null
                        ? Colors.red.shade300
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedOlcuBirim?.birimAdi ?? 'Birim seçiniz',
                        style: TextStyle(
                          color: _selectedOlcuBirim == null
                              ? Colors.grey.shade600
                              : Colors.black,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Birim Fiyatı (Label)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Birim Fiyatı',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Birim Fiyatı ve KDV Toggle Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fiyatAnaController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [ThousandsInputFormatter()],
                          onChanged: (_) => _calculateToplamFiyat(),
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _fiyatAnaController.text.isEmpty
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _fiyatAnaController.text.isEmpty
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.gradientStart,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                        child: Text(
                          ',',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _fiyatKusuratController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => _calculateToplamFiyat(),
                          decoration: InputDecoration(
                            hintText: '00',
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
                              borderSide: const BorderSide(
                                color: AppColors.gradientStart,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // KDV Toggle (White background, Button left, label right)
                Row(
                  children: [
                    Switch(
                      value: _kdvDahilDegil,
                      activeColor: AppColors.gradientStart,
                      inactiveTrackColor: Colors.white,
                      onChanged: (v) {
                        setState(() {
                          _kdvDahilDegil = v;
                          if (!v) {
                            _kdvOrani = 0; // Reset rate if unchecked
                          }
                        });
                        _calculateToplamFiyat();
                      },
                    ),
                    const Text(
                      'KDV Ekle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // KDV Oranı Input (Conditional)
            if (_kdvDahilDegil) ...[
              const SizedBox(height: 16),
              Text(
                'Eklenecek KDV Oranı',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showKdvOraniBottomSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _kdvOrani > 0 ? '%$_kdvOrani' : 'KDV Oranı Seçiniz',
                        style: TextStyle(
                          color: _kdvOrani > 0
                              ? Colors.black
                              : Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Para Birimi ve TL Kur Fiyatı - Aynı satırda
            Row(
              children: [
                // Para Birimi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Para Birimi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize:
                              (Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.fontSize ??
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
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedParaBirimi != null
                                      ? '${_selectedParaBirimi!.birimAdi} (${_selectedParaBirimi!.kod})'
                                      : 'Para birimi seçiniz',
                                  style: TextStyle(
                                    color: _selectedParaBirimi == null
                                        ? Colors.grey.shade600
                                        : Colors.black,
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
                const SizedBox(width: 16),
                // TL Kur Fiyatı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TL Kur Fiyatı',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                        controller: _tlKurFiyatiController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '0.00 TRY',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gradientStart,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Ürün Toplam Fiyatı ve Ürün Toplam TL Fiyatı - Aynı satırda
            Row(
              children: [
                // Ürün Toplam Fiyatı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ürün Toplam Fiyatı',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                        controller: _toplamFiyatController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gradientStart,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Ürün Toplam TL Fiyatı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ürün Toplam TL Fiyatı',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                        controller: _toplamTlFiyatiController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.gradientStart,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AnaKategoriBottomSheetContent extends StatefulWidget {
  final List<SatinAlmaAnaKategori> kategoriler;
  final SatinAlmaAnaKategori? selectedKategori;
  final Function(SatinAlmaAnaKategori) onKategoriSelected;

  const _AnaKategoriBottomSheetContent({
    required this.kategoriler,
    required this.selectedKategori,
    required this.onKategoriSelected,
  });

  @override
  State<_AnaKategoriBottomSheetContent> createState() =>
      _AnaKategoriBottomSheetContentState();
}

class _AnaKategoriBottomSheetContentState
    extends State<_AnaKategoriBottomSheetContent> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.kategoriler.where((k) {
      return k.kategori.toLowerCase().contains(
        searchController.text.toLowerCase(),
      );
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Ürün Kategorisi Seçiniz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize:
                    (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) +
                    1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredList.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final isSelected = widget.selectedKategori?.id == item.id;
                return ListTile(
                  dense: true,
                  title: Text(
                    item.kategori,
                    style: TextStyle(
                      fontSize:
                          (Theme.of(context).textTheme.titleMedium?.fontSize ??
                          16),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.gradientStart
                          : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: AppColors.gradientStart)
                      : null,
                  onTap: () {
                    widget.onKategoriSelected(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AltKategoriBottomSheetContent extends StatefulWidget {
  final List<SatinAlmaAltKategori> altKategoriler;
  final SatinAlmaAltKategori? selectedAltKategori;
  final Function(SatinAlmaAltKategori) onAltKategoriSelected;

  const _AltKategoriBottomSheetContent({
    required this.altKategoriler,
    required this.selectedAltKategori,
    required this.onAltKategoriSelected,
  });

  @override
  State<_AltKategoriBottomSheetContent> createState() =>
      _AltKategoriBottomSheetContentState();
}

class _AltKategoriBottomSheetContentState
    extends State<_AltKategoriBottomSheetContent> {
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.altKategoriler.where((k) {
      return k.altKategori.toLowerCase().contains(
        searchController.text.toLowerCase(),
      );
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Ürün Alt Kategorisi Seçiniz',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize:
                    (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) +
                    1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(8),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'Sonuç bulunamadı',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isSelected =
                          widget.selectedAltKategori?.id == item.id;
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.altKategori,
                          style: TextStyle(
                            fontSize:
                                (Theme.of(
                                  context,
                                ).textTheme.titleMedium?.fontSize ??
                                16),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.gradientStart
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppColors.gradientStart,
                              )
                            : null,
                        onTap: () {
                          widget.onAltKategoriSelected(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

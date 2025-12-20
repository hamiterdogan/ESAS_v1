import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/core/utils/thousands_input_formatter.dart';
import 'package:esas_v1/core/utils/thousands_input_formatter.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';

class SatinAlmaUrunCard extends ConsumerStatefulWidget {
  const SatinAlmaUrunCard({super.key});

  @override
  ConsumerState<SatinAlmaUrunCard> createState() => _SatinAlmaUrunCardState();
}

class _SatinAlmaUrunCardState extends ConsumerState<SatinAlmaUrunCard> {
  SatinAlmaAnaKategori? _selectedAnaKategori;
  SatinAlmaAltKategori? _selectedAltKategori;
  SatinAlmaOlcuBirim? _selectedOlcuBirim;

  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();
  final TextEditingController _fiyatAnaController = TextEditingController();
  final TextEditingController _fiyatKusuratController = TextEditingController();

  int _miktar = 0;

  bool _showingKategoriLoading = false;
  bool _showingAltKategoriLoading = false;
  bool _showingOlcuBirimLoading = false;

  bool validateForm() {
    if (_urunAdiController.text.isEmpty) {
      _showErrorBottomSheet('Ürün detay bilgisi giriniz');
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
                  style: Theme.of(context).textTheme.bodyMedium,
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
      builder: (ctx) => Center(child: BrandedLoadingIndicator()),
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

                  return StatefulBuilder(
                    builder: (context, setModalState) {
                      String searchQuery = '';
                      // We need a local controller inside the modal or manage state differently.
                      // Using a local variable for simplicity inside StatefulBuilder is common,
                      // but for text field we need a controller or onChanged.
                      // Let's use a local controller for the modal.
                      final TextEditingController searchController =
                          TextEditingController();

                      return StatefulBuilder(
                        builder: (context, setStateModal) {
                          final filteredList = allKategoriler.where((k) {
                            return k.kategori.toLowerCase().contains(
                              searchController.text.toLowerCase(),
                            );
                          }).toList();

                          return SizedBox(
                            height: MediaQuery.of(ctx).size.height * 0.75,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    16,
                                    16,
                                    8,
                                  ),
                                  child: Text(
                                    'Ürün Kategorisi Seçiniz',
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
                                              1,
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: TextField(
                                    controller: searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Ara...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon:
                                          searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                searchController.clear();
                                                setStateModal(() {});
                                              },
                                            )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(8),
                                    ),
                                    onChanged: (val) {
                                      setStateModal(() {});
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: filteredList.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color:
                                          Colors.grey.shade200, // Lighter grey
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = filteredList[index];
                                      final isSelected =
                                          _selectedAnaKategori?.id == item.id;
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          item.kategori,
                                          style: TextStyle(
                                            fontSize:
                                                (Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.fontSize ??
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
                                          setState(() {
                                            _selectedAnaKategori = item;
                                            _selectedAltKategori = null;
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
      builder: (ctx) => Center(child: BrandedLoadingIndicator()),
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
                  final TextEditingController searchController =
                      TextEditingController();

                  return StatefulBuilder(
                    builder: (context, setStateModal) {
                      final filteredList = altKategoriler.where((k) {
                        return k.altKategori.toLowerCase().contains(
                          searchController.text.toLowerCase(),
                        );
                      }).toList();

                      return SizedBox(
                        height: MediaQuery.of(ctx).size.height * 0.75,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Ürün Alt Kategorisi Seçiniz',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          (Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.fontSize ??
                                              16) +
                                          1,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
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
                                            setStateModal(() {});
                                          },
                                        )
                                      : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(8),
                                ),
                                onChanged: (val) {
                                  setStateModal(() {});
                                },
                              ),
                            ),
                            Expanded(
                              child: filteredList.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Sonuç bulunamadı',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: filteredList.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade200,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = filteredList[index];
                                        final isSelected =
                                            _selectedAltKategori?.id == item.id;
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            item.altKategori,
                                            style: TextStyle(
                                              fontSize:
                                                  (Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.fontSize ??
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
                                                  color:
                                                      AppColors.gradientStart,
                                                )
                                              : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedAltKategori = item;
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
      builder: (ctx) => Center(child: BrandedLoadingIndicator()),
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
            Text(
              'Ürün Kategorisi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
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
                  border: Border.all(color: Colors.grey.shade300),
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
              Text(
                'Ürün Alt Kategorisi',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                      1,
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
                    border: Border.all(color: Colors.grey.shade300),
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
              maxValue: 99999,
              initialValue: _miktar,
              onValueChanged: (value) {
                setState(() {
                  _miktar = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Başlıklar Row'u
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Birim',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Birim Fiyatı',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize:
                          (Theme.of(context).textTheme.titleSmall?.fontSize ??
                              14) +
                          1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Input'lar Row'u
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showOlcuBirimBottomSheet,
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _fiyatAnaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsInputFormatter()],
                          decoration: InputDecoration(
                            hintText: '0',
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
                              horizontal: 12,
                              vertical: 13,
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
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(2),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                              horizontal: 12,
                              vertical: 13,
                            ),
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

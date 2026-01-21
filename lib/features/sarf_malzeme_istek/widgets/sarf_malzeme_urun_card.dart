import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_kategori_models.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/common/index.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';

class SarfMalzemeUrunCard extends ConsumerStatefulWidget {
  final SatinAlmaUrunBilgisi? initialBilgi;
  final String talepTuru; // 'Temizlik', 'Kirtasiye', 'Promosyon'

  const SarfMalzemeUrunCard({
    super.key,
    this.initialBilgi,
    required this.talepTuru,
  });

  @override
  ConsumerState<SarfMalzemeUrunCard> createState() =>
      SarfMalzemeUrunCardState();
}

class SarfMalzemeUrunCardState extends ConsumerState<SarfMalzemeUrunCard> {
  // Using SatinAlmaAnaKategori for UI compatibility
  SatinAlmaAnaKategori? _selectedAnaKategori;
  SatinAlmaAltKategori? _selectedAltKategori;
  SatinAlmaOlcuBirim? _selectedOlcuBirim;
  int _miktar = 1;

  late final FocusNode _urunDetayFocusNode;
  late final TextEditingController _urunDetayController;
  final TextEditingController _miktarController = TextEditingController();
  final TextEditingController _aciklamaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urunDetayFocusNode = FocusNode(canRequestFocus: true, skipTraversal: true);
    _urunDetayController = TextEditingController(
      text: widget.initialBilgi?.urunDetay ?? '',
    );
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

      _miktar = bilgi.miktar ?? 1;
    }
  }

  Future<SatinAlmaUrunBilgisi?> getData() async {
    if (!await validateForm()) return null;

    return SatinAlmaUrunBilgisi(
      anaKategori: _selectedAnaKategori?.kategori,
      anaKategoriId: _selectedAnaKategori?.id,
      altKategori: _selectedAltKategori?.altKategori,
      altKategoriId: _selectedAltKategori?.id,
      urunDetay: _urunDetayController.text,
      aciklama: _aciklamaController.text,
      miktar: _miktar,
      olcuBirimi: _selectedOlcuBirim?.birimAdi,
      olcuBirimiId: _selectedOlcuBirim?.id,
      olcuBirimiKisaltma: _selectedOlcuBirim?.kisaltma,
      // Default/Empty values for removed fields
      paraBirimi: null,
      paraBirimiId: null,
      paraBirimiKod: null,
      dovizKuru: 1.0,
      fiyatAna: '0',
      fiyatKusurat: '00',
      toplamFiyat: '0',
      tlKurFiyati: '0',
      toplamTlFiyati: '0',
      kdvDahilDegil: false,
      kdvOrani: 0,
    );
  }

  Future<bool> validateForm() async {
    if (_selectedAnaKategori == null) {
      await ValidationUyariWidget.goster(
        context: context,
        message: 'Ürün kategorisi seçiniz',
      );
      return false;
    }
    if (_selectedAltKategori == null) {
      await ValidationUyariWidget.goster(
        context: context,
        message: 'Alt kategorisi seçiniz',
      );
      return false;
    }
    if (_urunDetayController.text.isEmpty) {
      await ValidationUyariWidget.goster(
        context: context,
        message: 'Ürün detay bilgisi giriniz',
      );
      return false;
    }
    if (_selectedOlcuBirim == null) {
      await ValidationUyariWidget.goster(
        context: context,
        message: 'Birim seçiniz',
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _urunDetayFocusNode.dispose();
    _urunDetayController.dispose();
    _miktarController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  Future<void> _showAnaKategoriBottomSheet() async {
    _urunDetayFocusNode.canRequestFocus = false;
    _urunDetayFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    await Future.delayed(Duration.zero);

    AsyncValue<List<SarfMalzemeAnaKategori>> kategorilerAsync;

    // Select dynamic provider
    if (widget.talepTuru.toLowerCase().contains('temizlik')) {
      kategorilerAsync = ref.read(sarfMalzemeTemizlikKategorilerProvider);
    } else if (widget.talepTuru.toLowerCase().contains('kırtasiye') ||
        widget.talepTuru.toLowerCase().contains('kirtasiye')) {
      kategorilerAsync = ref.read(sarfMalzemeKirtasiyeKategorilerProvider);
    } else if (widget.talepTuru.toLowerCase().contains('promosyon')) {
      kategorilerAsync = ref.read(sarfMalzemePromosyonKategorilerProvider);
    } else {
      // Default to Yiyecek if others don't match, or check explicitly
      kategorilerAsync = ref.read(sarfMalzemeYiyecekKategorilerProvider);
    }

    if (kategorilerAsync.hasValue) {
      await _openAnaKategoriBottomSheet();
      return;
    }

    if (!mounted) return;
    BrandedLoadingDialog.show(context);
    try {
      if (widget.talepTuru.toLowerCase().contains('temizlik')) {
        await ref.read(sarfMalzemeTemizlikKategorilerProvider.future);
      } else if (widget.talepTuru.toLowerCase().contains('kırtasiye') ||
          widget.talepTuru.toLowerCase().contains('kirtasiye')) {
        await ref.read(sarfMalzemeKirtasiyeKategorilerProvider.future);
      } else if (widget.talepTuru.toLowerCase().contains('promosyon')) {
        await ref.read(sarfMalzemePromosyonKategorilerProvider.future);
      } else {
        await ref.read(sarfMalzemeYiyecekKategorilerProvider.future);
      }

      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openAnaKategoriBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openAnaKategoriBottomSheet();
      }
    }
    _urunDetayFocusNode.canRequestFocus = true;
  }

  Future<void> _openAnaKategoriBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              AsyncValue<List<SarfMalzemeAnaKategori>> asyncKategoriler;
              if (widget.talepTuru.toLowerCase().contains('temizlik')) {
                asyncKategoriler = ref.watch(
                  sarfMalzemeTemizlikKategorilerProvider,
                );
              } else if (widget.talepTuru.toLowerCase().contains('kırtasiye') ||
                  widget.talepTuru.toLowerCase().contains('kirtasiye')) {
                asyncKategoriler = ref.watch(
                  sarfMalzemeKirtasiyeKategorilerProvider,
                );
              } else if (widget.talepTuru.toLowerCase().contains('promosyon')) {
                asyncKategoriler = ref.watch(
                  sarfMalzemePromosyonKategorilerProvider,
                );
              } else {
                asyncKategoriler = ref.watch(
                  sarfMalzemeYiyecekKategorilerProvider,
                );
              }

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
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (sarfKategoriler) {
                  final allKategoriler = sarfKategoriler
                      .map(
                        (k) => SatinAlmaAnaKategori(
                          id: k.id,
                          kategori: k.kategori,
                          aktif: k.aktif,
                        ),
                      )
                      .toList();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _urunDetayFocusNode.canRequestFocus = true;
    });
  }

  Future<void> _showAltKategoriBottomSheet() async {
    _urunDetayFocusNode.canRequestFocus = false;
    _urunDetayFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    await Future.delayed(Duration.zero);

    if (_selectedAnaKategori == null) return;

    final altKategorilerAsync = ref.read(
      sarfMalzemeAltKategorilerProvider(_selectedAnaKategori!.id),
    );

    if (altKategorilerAsync.hasValue) {
      await _openAltKategoriBottomSheet();
      return;
    }

    if (!mounted) return;
    BrandedLoadingDialog.show(context);
    try {
      await ref.read(
        sarfMalzemeAltKategorilerProvider(_selectedAnaKategori!.id).future,
      );
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openAltKategoriBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openAltKategoriBottomSheet();
      }
    }
    _urunDetayFocusNode.canRequestFocus = true;
  }

  Future<void> _openAltKategoriBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final asyncSubKategoriler = ref.watch(
                // Use the Sarf Malzeme specific provider with the selected category ID
                sarfMalzemeAltKategorilerProvider(_selectedAnaKategori!.id),
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
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (sarfKategoriler) {
                  // Map specific SarfMalzemeAltKategori model to SatinAlmaAltKategori for UI compatibility
                  final altKategoriler = sarfKategoriler
                      .map(
                        (k) => SatinAlmaAltKategori(
                          id: k.id,
                          altKategori: k.altKategori,
                          satinAlmaAnaKategoriId: k.anaKategoriId,
                          aktif: k.aktif,
                        ),
                      )
                      .toList();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _urunDetayFocusNode.canRequestFocus = true;
    });
  }

  Future<void> _showOlcuBirimBottomSheet() async {
    _urunDetayFocusNode.canRequestFocus = false;
    _urunDetayFocusNode.unfocus();
    FocusScope.of(context).unfocus();

    await Future.delayed(Duration.zero);

    final olcuAsync = ref.read(satinAlmaOlcuBirimleriProvider);

    if (olcuAsync.hasValue) {
      await _openOlcuBirimBottomSheet();
      return;
    }

    if (!mounted) return;
    BrandedLoadingDialog.show(context);
    try {
      await ref.read(satinAlmaOlcuBirimleriProvider.future);
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openOlcuBirimBottomSheet();
      }
    } catch (e) {
      if (mounted) {
        BrandedLoadingDialog.hide(context);
        await _openOlcuBirimBottomSheet();
      }
    }
    _urunDetayFocusNode.canRequestFocus = true;
  }

  Future<void> _openOlcuBirimBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textOnPrimary,
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
                      style: TextStyle(color: AppColors.error),
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
                                      color: AppColors.textSecondary,
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
                                              : AppColors.textPrimary87,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
      _urunDetayFocusNode.canRequestFocus = true;
    });
  }

  void _handleAutoSelect(AsyncValue<List<SarfMalzemeAnaKategori>> next) {
    if (next.hasValue && next.value != null && next.value!.isNotEmpty) {
      if (_selectedAnaKategori == null) {
        final firstCat = next.value!.first;
        setState(() {
          _selectedAnaKategori = SatinAlmaAnaKategori(
            id: firstCat.id,
            kategori: firstCat.kategori,
            aktif: firstCat.aktif,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-select logic based on talepTuru
    if (widget.talepTuru.toLowerCase().contains('temizlik')) {
      ref.listen(sarfMalzemeTemizlikKategorilerProvider, (previous, next) {
        _handleAutoSelect(next);
      });
    } else if (widget.talepTuru.toLowerCase().contains('kırtasiye') ||
        widget.talepTuru.toLowerCase().contains('kirtasiye')) {
      ref.listen(sarfMalzemeKirtasiyeKategorilerProvider, (previous, next) {
        _handleAutoSelect(next);
      });
    } else if (widget.talepTuru.toLowerCase().contains('promosyon')) {
      ref.listen(sarfMalzemePromosyonKategorilerProvider, (previous, next) {
        _handleAutoSelect(next);
      });
    } else {
      ref.listen(sarfMalzemeYiyecekKategorilerProvider, (previous, next) {
        _handleAutoSelect(next);
      });
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color:
          Color.lerp(
            Theme.of(context).scaffoldBackgroundColor,
            AppColors.textOnPrimary,
            0.65,
          ) ??
          AppColors.textOnPrimary,
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
                color: AppColors.primaryDark,
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
                  color: AppColors.textOnPrimary,
                  border: Border.all(color: AppColors.border),
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
                              : AppColors.textPrimary,
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

            // Ürün Alt Kategorisi - Always visible
            Text(
              'Ürün Alt Kategorisi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap:
                  _showAltKategoriBottomSheet, // Will handle empty/null parent check internally if needed
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary,
                  border: Border.all(
                    color: _selectedAltKategori == null
                        ? Colors
                              .grey
                              .shade300 // Start plain, highlight error via validation if needed
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
                              : AppColors.textPrimary,
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

            // Ürün Detay
            Text(
              'Ürün Detay',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              focusNode: _urunDetayFocusNode,
              controller: _urunDetayController,
              autofocus: false,
              readOnly: false,
              decoration: InputDecoration(
                hintText: 'Ürün detayını giriniz',
                filled: true,
                fillColor: AppColors.textOnPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
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
            NumericSpinnerWidget(
              label: 'Miktar',
              minValue: 1,
              maxValue: 99999,
              initialValue: _miktar,
              onValueChanged: (value) {
                setState(() {
                  _miktar = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Birim (Full Width)
            Text(
              'Birim',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize:
                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) +
                    1,
                color: AppColors.primaryDark,
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
                  color: AppColors.textOnPrimary,
                  border: Border.all(color: AppColors.border),
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
                              : AppColors.textPrimary,
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
                  borderSide: BorderSide(color: AppColors.border),
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
                          : AppColors.textPrimary87,
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
                  borderSide: BorderSide(color: AppColors.border),
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
                      style: TextStyle(color: AppColors.textSecondary),
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
                                : AppColors.textPrimary87,
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

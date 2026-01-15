import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_dialog.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_turu.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_turleri/temizlik_malzemesi_istek_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_turleri/kirtasiye_malzemesi_istek_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_turleri/promosyon_malzemesi_istek_screen.dart';

class SarfMalzemeTuruSecimScreen extends ConsumerStatefulWidget {
  const SarfMalzemeTuruSecimScreen({super.key});

  @override
  ConsumerState<SarfMalzemeTuruSecimScreen> createState() =>
      _SarfMalzemeTuruSecimScreenState();
}

class _SarfMalzemeTuruSecimScreenState
    extends ConsumerState<SarfMalzemeTuruSecimScreen> {
  bool _isActionInProgress = false;
  bool _turlerYuklendi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BrandedLoadingDialog.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final turlerAsync = ref.watch(allSarfMalzemeTurleriProvider);

    // Türler yüklendiğinde loading dialog'u kapat
    ref.listen(allSarfMalzemeTurleriProvider, (prev, next) {
      next.when(
        data: (_) {
          if (mounted && !_turlerYuklendi) {
            setState(() => _turlerYuklendi = true);
            BrandedLoadingDialog.hide(context);
          }
        },
        loading: () {},
        error: (error, stack) {
          if (mounted && !_turlerYuklendi) {
            setState(() => _turlerYuklendi = true);
            BrandedLoadingDialog.hide(context);
          }
        },
      );
    });

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: const Text(
            'Yeni Sarf Malzeme İsteği',
            style: TextStyle(color: AppColors.textOnPrimary),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        ),
        body: turlerAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('Hata: $error'),
              ],
            ),
          ),
          data: (turler) {
            if (turler.isEmpty) {
              return const Center(child: Text('Sarf malzeme türü bulunamadı'));
            }

            return ListView.builder(
              itemCount: turler.length,
              itemBuilder: (context, index) {
                final tur = turler[index];
                return _buildSarfTuruTile(tur, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSarfTuruTile(SarfMalzemeTuru tur, BuildContext context) {
    // Türe göre ikon belirle
    IconData icon;
    final turAdi = tur.ad.toLowerCase();
    if (turAdi.contains('temizlik')) {
      icon = Icons.cleaning_services;
    } else if (turAdi.contains('kırtasiye') || turAdi.contains('kirtasiye')) {
      icon = Icons.description;
    } else if (turAdi.contains('promosyon')) {
      icon = Icons.card_giftcard;
    } else {
      icon = Icons.shopping_bag;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _navigateToSarfScreen(context, tur);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppColors.primaryLight, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        tur.ad,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.primaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 55, right: 8),
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  Future<void> _navigateToSarfScreen(
    BuildContext context,
    SarfMalzemeTuru tur,
  ) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      Widget screen;

      // Türe göre ilgili ekranı seç
      final turAdi = tur.ad.toLowerCase();
      if (turAdi.contains('temizlik')) {
        screen = const TemizlikMalzemesiIstekScreen();
      } else if (turAdi.contains('kırtasiye') || turAdi.contains('kirtasiye')) {
        screen = const KirtasiyeMalzemesiIstekScreen();
      } else if (turAdi.contains('promosyon')) {
        screen = const PromosyonMalzemesiIstekScreen();
      } else {
        // Varsayılan olarak temizlik ekranını aç
        screen = const TemizlikMalzemesiIstekScreen();
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }
}

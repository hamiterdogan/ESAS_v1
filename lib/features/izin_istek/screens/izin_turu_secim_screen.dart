import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/common/widgets/branded_loading_indicator.dart';
import 'package:esas_v1/features/izin_istek/models/izin_nedeni.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_providers.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/dini_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/yillik_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/hastalik_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/evlilik_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/dogum_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/kurum_gorevlendirmesi_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/mazeret_izin_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_turleri/vefat_izin_screen.dart';

class IzinTuruSecimScreen extends ConsumerStatefulWidget {
  const IzinTuruSecimScreen({super.key});

  @override
  ConsumerState<IzinTuruSecimScreen> createState() =>
      _IzinTuruSecimScreenState();
}

class _IzinTuruSecimScreenState extends ConsumerState<IzinTuruSecimScreen> {
  bool _isActionInProgress = false;

  IconData _iconForIzinSebebiId(int? izinSebebiId) {
    switch (izinSebebiId) {
      case 1: // Yıllık İzin
        return Icons.beach_access;
      case 2: // Evlilik İzni
        return Icons.card_giftcard;
      case 3: // Vefat İzni
        return Icons.spa;
      case 4: // Hastalık İzni
        return Icons.medical_services;
      case 5: // Mazeret İzni
        return Icons.event_note;
      case 6: // Dini İzin
        return Icons.public;
      case 7: // Doğum İzni
        return Icons.child_friendly;
      case 8: // Kurum Görevlendirmesi
        return Icons.work;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    final izinNedenlerAsync = ref.watch(allIzinNedenlerProvider);
    final isLoading = izinNedenlerAsync.isLoading;
    final body = izinNedenlerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
      data: (nedenler) {
        if (nedenler.isEmpty) {
          return const Center(child: Text('İzin türü bulunamadı'));
        }

        return ListView.builder(
          itemCount: nedenler.length,
          itemBuilder: (context, index) {
            final neden = nedenler[index];

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    _iconForIzinSebebiId(neden.izinSebebiId),
                    color: AppColors.primaryLight,
                    size: 30,
                  ),
                  title: Text(
                    neden.izinAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryLight,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  onTap: () => _navigateToIzinScreen(context, neden),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 55,
                  endIndent: 8,
                  color: AppColors.border,
                ),
              ],
            );
          },
        );
      },
    );

    return PopScope(
      canPop: true,
      child: SizedBox.expand(
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.scaffoldBackground,
              appBar: AppBar(
                title: const Text(
                  'Yeni İzin İsteği',
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
              body: body,
            ),
            if (isLoading)
              const BrandedLoadingOverlay(indicatorSize: 153, strokeWidth: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToIzinScreen(
    BuildContext context,
    IzinNedeni neden,
  ) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    try {
      Widget screen;

      // İzin türü ID'sine göre doğru sayfaya yönlendir
      switch (neden.izinSebebiId) {
        case 1: // Yıllık İzin
          screen = const YillikIzinScreen();
          break;
        case 2: // Evlilik İzni
          screen = const EvlilikIzinScreen();
          break;
        case 3: // Vefat İzni
          screen = const VefatIzinScreen();
          break;
        case 4: // Hastalık İzni
          screen = const HastalikIzinScreen();
          break;
        case 5: // Mazeret İzni
          screen = const MazeretIzinScreen();
          break;
        case 6: // Dini İzin
          screen = const DiniIzinScreen();
          break;
        case 7: // Doğum İzni
          screen = const DogumIzinScreen();
          break;
        case 8: // Kurum Görevlendirmesi
          screen = const KurumGorevlendirmesiIzinScreen();
          break;
        default:
          screen = const DiniIzinScreen();
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

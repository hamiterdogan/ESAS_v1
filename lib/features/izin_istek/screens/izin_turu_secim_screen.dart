import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final izinNedenlerAsync = ref.watch(allIzinNedenlerProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF1F5),
        appBar: AppBar(
          title: const Text(
            'İzin Türü Seçin',
            style: TextStyle(color: Colors.white),
          ),
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: izinNedenlerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
                print(
                  '📌 Liste item $index: ID=${neden.izinSebebiId}, İzinAdı=${neden.izinAdi}',
                );
                return _buildIzinTuruTile(neden, context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildIzinTuruTile(IzinNedeni neden, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigateToIzinScreen(context, neden);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    neden.izinAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
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
      print(
        '🔀 Navigating to izin screen: ID=${neden.izinSebebiId}, İzinAdı=${neden.izinAdi}',
      );
      Widget screen;

      // İzin türü ID'sine göre doğru sayfaya yönlendir
      switch (neden.izinSebebiId) {
        case 1: // Yıllık İzin
          print('  → Yıllık İzin seçildi');
          screen = const YillikIzinScreen();
          break;
        case 2: // Evlilik İzni
          print('  → Evlilik İzni seçildi');
          screen = const EvlilikIzinScreen();
          break;
        case 3: // Vefat İzni
          print('  → Vefat İzni seçildi');
          screen = const VefatIzinScreen();
          break;
        case 4: // Hastalık İzni
          print('  → Hastalık İzni seçildi');
          screen = const HastalikIzinScreen();
          break;
        case 5: // Mazeret İzni
          print('  → Mazeret İzni seçildi');
          screen = const MazeretIzinScreen();
          break;
        case 6: // Dini İzin
          print('  → Dini İzin seçildi');
          screen = const DiniIzinScreen();
          break;
        case 7: // Doğum İzni
          print('  → Doğum İzni seçildi');
          screen = const DogumIzinScreen();
          break;
        case 8: // Kurum Görevlendirmesi
          print('  → Kurum Görevlendirmesi seçildi');
          screen = const KurumGorevlendirmesiIzinScreen();
          break;
        default:
          print(
            '  ⚠️ Bilinmeyen ID: ${neden.izinSebebiId}, Dini İzin yükleniyor',
          );
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

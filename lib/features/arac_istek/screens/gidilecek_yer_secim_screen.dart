import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';

// Arşiv: Bu dosya artık kullanılmıyor.
// İçerik `gidilecek_yer_secim_screen_sil.dart` dosyasına taşındı.
// "Binek Araç İsteği" ekranında bottom sheet ile yer seçimi yapılıyor.

class GidilecekYerSecimScreen extends ConsumerStatefulWidget {
  final List<GidilecekYer> initiallySelected;

  const GidilecekYerSecimScreen({super.key, this.initiallySelected = const []});

  @override
  ConsumerState<GidilecekYerSecimScreen> createState() =>
      _GidilecekYerSecimScreenState();
}

class _GidilecekYerSecimScreenState
    extends ConsumerState<GidilecekYerSecimScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: const Text('Gidilecek Yer Seçimi')),
      body: const Center(
        child: Text(
          'Bu ekran artık kullanılmıyor.\nYer seçimi "Binek Araç İsteği" ekranında yapılıyor.',
        ),
      ),
    );
  }
}

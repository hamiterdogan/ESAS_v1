import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_urun_bilgisi.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/widgets/sarf_malzeme_urun_card.dart';

class SarfMalzemeUrunEkleScreen extends ConsumerStatefulWidget {
  const SarfMalzemeUrunEkleScreen({
    this.initialBilgi,
    required this.talepTuru,
    super.key,
  });

  final SatinAlmaUrunBilgisi? initialBilgi;
  final String talepTuru;

  @override
  ConsumerState<SarfMalzemeUrunEkleScreen> createState() =>
      _SarfMalzemeUrunEkleScreenState();
}

class _SarfMalzemeUrunEkleScreenState
    extends ConsumerState<SarfMalzemeUrunEkleScreen> {
  final GlobalKey<SarfMalzemeUrunCardState> _cardKey =
      GlobalKey<SarfMalzemeUrunCardState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Ürün Ekle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        backgroundColor: const Color(0xFF014B92),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SarfMalzemeUrunCard(
              key: _cardKey,
              initialBilgi: widget.initialBilgi,
              talepTuru: widget.talepTuru,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientStart,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (!mounted) return;
                final bilgi = _cardKey.currentState?.getData();
                if (bilgi != null) {
                  Navigator.pop<SatinAlmaUrunBilgisi>(context, bilgi);
                }
              },
              child: const Text(
                'Tamam',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

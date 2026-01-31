import 'package:flutter/material.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_detay_screen.dart';
import 'package:esas_v1/features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_detay_screen.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_istek_detay_screen.dart';

/// Swipeable detay wrapper - Talep listesinde sağa-sola kaydırma ile geçiş
/// Temiz ve pürüzsüz geçiş animasyonu sağlar
class SwipeableDetayWrapper extends StatefulWidget {
  final List<Talep> talepList;
  final int initialIndex;
  final bool isGelenKutusu;

  const SwipeableDetayWrapper({
    super.key,
    required this.talepList,
    required this.initialIndex,
    this.isGelenKutusu = false,
  });

  @override
  State<SwipeableDetayWrapper> createState() => _SwipeableDetayWrapperState();
}

class _SwipeableDetayWrapperState extends State<SwipeableDetayWrapper> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Talep tipine göre detay ekranı widget'ını döndürür
  Widget _buildDetayScreen(Talep talep) {
    final onayTipi = talep.onayTipi.toLowerCase();

    // İzin İstek
    if (onayTipi.contains('izin')) {
      return IzinIstekDetayScreen(
        talepId: talep.onayKayitId,
        onayTipi: talep.onayTipi,
      );
    }
    // Araç İstek
    else if (onayTipi.contains('araç') || onayTipi.contains('arac')) {
      return AracIstekDetayScreen(talepId: talep.onayKayitId);
    }
    // Dokümantasyon İstek
    else if (onayTipi.contains('dok')) {
      return DokumantasyonIstekDetayScreen(
        talepId: talep.onayKayitId,
        onayTipi: talep.onayTipi,
      );
    }
    // Satın Alma
    else if (onayTipi.contains('satın') || onayTipi.contains('satin')) {
      return SatinAlmaDetayScreen(talepId: talep.onayKayitId);
    }
    // Teknik Destek / Bilgi Teknolojileri
    else if (onayTipi.contains('teknik destek')) {
      return TeknikDestekDetayScreen(talepId: talep.onayKayitId);
    }
    // Sarf Malzeme
    else if (onayTipi.contains('sarf malzeme')) {
      return SarfMalzemeDetayScreen(talepId: talep.onayKayitId);
    }
    // Yiyecek İçecek
    else if (onayTipi.contains('yiyecek') ||
        onayTipi.contains('içecek') ||
        onayTipi.contains('icecek')) {
      return YiyecekIcecekDetayScreen(talepId: talep.onayKayitId);
    }
    // Eğitim İstek
    else if (onayTipi.contains('eğitim') || onayTipi.contains('egitim')) {
      return EgitimIstekDetayScreen(talepId: talep.onayKayitId);
    }

    // Desteklenmeyen talep türü için boş ekran
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detay'),
      ),
      body: const Center(
        child: Text('Bu talep türü için detay ekranı henüz desteklenmiyor.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const PageScrollPhysics(), // Pürüzsüz kaydırma fizik
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemCount: widget.talepList.length,
      itemBuilder: (context, index) {
        return _buildDetayScreen(widget.talepList[index]);
      },
    );
  }
}

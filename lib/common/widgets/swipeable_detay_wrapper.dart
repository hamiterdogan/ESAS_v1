import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/constants/app_colors.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_detay_screen.dart';
import 'package:esas_v1/features/teknik_destek_istek/screens/teknik_destek_detay_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_detay_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_detay_screen.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_istek_detay_screen.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/providers/talep_yonetim_providers.dart';

/// Swipeable detay wrapper - Talep listesinde sağa-sola kaydırma ile geçiş
/// Temiz ve pürüzsüz geçiş animasyonu sağlar
/// AppBar sabit kalır, sadece içerik kayar
class SwipeableDetayWrapper extends ConsumerStatefulWidget {
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
  ConsumerState<SwipeableDetayWrapper> createState() => _SwipeableDetayWrapperState();
}

class _SwipeableDetayWrapperState extends ConsumerState<SwipeableDetayWrapper> {
  late PageController _pageController;
  late int _currentIndex;
  final Set<int> _markedAsRead = {}; // Okundu olarak işaretlenenler

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // İlk açılan sayfayı okundu olarak işaretle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead(widget.initialIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Belirtilen index'teki talebi okundu olarak işaretle
  Future<void> _markAsRead(int index) async {
    final talep = widget.talepList[index];
    
    // Zaten okunmuşsa veya daha önce işaretlediyse tekrar işaretleme
    if (_markedAsRead.contains(talep.onayKayitId)) return;
    if (talep.okundu?.toLowerCase() != 'false') return;

    try {
      final repository = ref.read(talepYonetimRepositoryProvider);
      await repository.okunduIsaretle(
        onayKayitId: talep.onayKayitId,
        onayTipi: talep.onayTipi,
      );
      
      // İşaretlendi olarak kaydet
      _markedAsRead.add(talep.onayKayitId);
      
      // Provider'ları yenile
      ref.read(devamEdenGelenKutusuProvider.notifier).refresh();
      ref.read(tamamlananGelenKutusuProvider.notifier).refresh();
      ref.invalidate(okunmayanTalepSayisiProvider);
    } catch (e) {
      debugPrint('Okundu işaretleme hatası: $e');
      // Hata olsa bile sessizce devam et
    }
  }

  /// Talep tipine göre başlık metnini döndürür
  String _getDetayBaslik(String onayTipi) {
    final lowerOnayTipi = onayTipi.toLowerCase();

    if (lowerOnayTipi.contains('izin')) {
      return 'İzin İstek Detayı';
    } else if (lowerOnayTipi.contains('araç') ||
        lowerOnayTipi.contains('arac')) {
      return 'Araç İstek Detayı';
    } else if (lowerOnayTipi.contains('dok')) {
      return 'Dokümantasyon İstek Detayı';
    } else if (lowerOnayTipi.contains('satın') ||
        lowerOnayTipi.contains('satin')) {
      return 'Satın Alma İstek Detayı';
    } else if (lowerOnayTipi.contains('teknik destek') ||
        lowerOnayTipi.contains('bilgi teknolojileri')) {
      return 'Teknik Destek İstek Detayı';
    } else if (lowerOnayTipi.contains('sarf malzeme')) {
      return 'Sarf Malzeme İstek Detayı';
    } else if (lowerOnayTipi.contains('yiyecek') ||
        lowerOnayTipi.contains('içecek') ||
        lowerOnayTipi.contains('icecek')) {
      return 'Yiyecek İçecek İstek Detayı';
    } else if (lowerOnayTipi.contains('eğitim') ||
        lowerOnayTipi.contains('egitim')) {
      return 'Eğitim İstek Detayı';
    }

    return 'İstek Detayı';
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
      body: const Center(
        child: Text('Bu talep türü için detay ekranı henüz desteklenmiyor.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTalep = widget.talepList[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${_getDetayBaslik(currentTalep.onayTipi)} (${currentTalep.onayKayitId})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        physics: const PageScrollPhysics(), // Pürüzsüz kaydırma fizik
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          // Yeni sayfaya geçildiğinde okundu olarak işaretle
          _markAsRead(index);
        },
        itemCount: widget.talepList.length,
        itemBuilder: (context, index) {
          // Detay ekranlarının kendi AppBar'larını gizlemek için Theme override
          return Theme(
            data: Theme.of(context).copyWith(
              appBarTheme: const AppBarTheme(toolbarHeight: 0, elevation: 0),
            ),
            child: _buildDetayScreen(widget.talepList[index]),
          );
        },
      ),
    );
  }
}

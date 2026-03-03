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
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_istek_detay_provider.dart';
import 'package:esas_v1/features/dokumantasyon_istek/providers/dokumantasyon_istek_detay_provider.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/teknik_destek_istek/providers/teknik_destek_detay_provider.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/providers/sarf_malzeme_providers.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/providers/yiyecek_icecek_providers.dart';
import 'package:esas_v1/features/egitim_istek/providers/egitim_istek_detay_provider.dart';

/// Swipeable detay wrapper - Talep listesinde sağa-sola kaydırma ile geçiş
/// Temiz ve pürüzsüz geçiş animasyonu sağlar
/// AppBar sabit kalır, sadece içerik kayar
class SwipeableDetayWrapper extends ConsumerStatefulWidget {
  final List<Talep> talepList;
  final int initialIndex;
  final bool isGelenKutusu;

  final bool isTamamlanan;

  const SwipeableDetayWrapper({
    super.key,
    required this.talepList,
    required this.initialIndex,
    this.isGelenKutusu = false,
    this.isTamamlanan = false,
  });

  @override
  ConsumerState<SwipeableDetayWrapper> createState() =>
      _SwipeableDetayWrapperState();
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

    // İlk açılan sayfanın provider'ını invalidate et - güncel veri çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invalidateDetayProvider(widget.talepList[widget.initialIndex]);
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
      // Hata oluşursa sessizce göz ardı et
      if (kDebugMode) debugPrint('Okundu işareti hatası: $e');
    }
  }

  /// Talep türüne göre ilgili detay provider'ı invalidate et
  void _invalidateDetayProvider(Talep talep) {
    final onayTipiLower = talep.onayTipi.toLowerCase();

    // Onay durumu provider'ı için kullanılacak onay tipi
    String? onayDurumuTipi;

    if (onayTipiLower.contains('izin')) {
      ref.invalidate(izinIstekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = talep.onayTipi;
    } else if (onayTipiLower.contains('araç') ||
        onayTipiLower.contains('arac')) {
      ref.invalidate(aracIstekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = 'Araç İstek';
    } else if (onayTipiLower.contains('dok')) {
      ref.invalidate(dokumantasyonIstekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = talep.onayTipi;
    } else if (onayTipiLower.contains('satın') ||
        onayTipiLower.contains('satin')) {
      ref.invalidate(satinAlmaDetayProvider(talep.onayKayitId));
      onayDurumuTipi = 'Satın Alma';
    } else if (onayTipiLower.contains('teknik destek')) {
      ref.invalidate(teknikDestekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = 'Teknik Destek';
    } else if (onayTipiLower.contains('sarf malzeme')) {
      ref.invalidate(sarfMalzemeDetayProvider(talep.onayKayitId));
      onayDurumuTipi =
          'Satın Alma'; // Sarf Malzeme detay ekranında 'Satın Alma' kullanılıyor
    } else if (onayTipiLower.contains('yiyecek') ||
        onayTipiLower.contains('içecek') ||
        onayTipiLower.contains('icecek')) {
      ref.invalidate(yiyecekIstekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = 'Yiyecek İçecek İstek';
    } else if (onayTipiLower.contains('eğitim') ||
        onayTipiLower.contains('egitim')) {
      ref.invalidate(egitimIstekDetayProvider(talep.onayKayitId));
      onayDurumuTipi = 'Eğitim İstek';
    }

    // Onay durumu provider'ını da invalidate et
    if (onayDurumuTipi != null) {
      ref.invalidate(
        onayDurumuProvider((
          talepId: talep.onayKayitId,
          onayTipi: onayDurumuTipi,
        )),
      );

      // Eğer talep.onayTipi belirlenen tipten farklıysa, onu da invalidate et (güvenlik için)
      if (onayDurumuTipi != talep.onayTipi &&
          onayDurumuTipi != talep.onayTipi.trim()) {
        ref.invalidate(
          onayDurumuProvider((
            talepId: talep.onayKayitId,
            onayTipi: talep.onayTipi,
          )),
        );
      }
    }
  }

  String _resolveTeknikBilgiBaslik(String? hizmetTuru) {
    final hizmetTuruLower = (hizmetTuru ?? '').toLowerCase().trim();
    if (hizmetTuruLower.contains('bilgi teknoloj')) {
      return 'Bilgi Teknolojileri İstek Detayı';
    }
    if (hizmetTuruLower.contains('teknik hizmet') ||
        hizmetTuruLower.contains('iç hizmet') ||
        hizmetTuruLower.contains('ic hizmet')) {
      return 'Teknik Destek İstek Detayı';
    }
    return 'Teknik Destek İstek Detayı';
  }

  String _resolveTeknikBilgiBaslikFromTalep(Talep talep) {
    final fromHizmetTuru = talep.hizmetTuru;
    if ((fromHizmetTuru ?? '').trim().isNotEmpty) {
      return _resolveTeknikBilgiBaslik(fromHizmetTuru);
    }

    final fromAction = talep.actionAdi;
    if ((fromAction ?? '').trim().isNotEmpty) {
      return _resolveTeknikBilgiBaslik(fromAction);
    }

    return 'Teknik Destek İstek Detayı';
  }

  /// Talep türüne göre Türkçe başlık döndür
  String _getDetayBaslik(Talep talep) {
    final onayTipiLower = talep.onayTipi.toLowerCase();

    if (onayTipiLower.contains('izin')) {
      return 'İzin İstek Detayı';
    } else if (onayTipiLower.contains('araç') ||
        onayTipiLower.contains('arac')) {
      return 'Araç İstek Detayı';
    } else if (onayTipiLower.contains('dok')) {
      return 'Dokümantasyon İstek Detayı';
    } else if (onayTipiLower.contains('satın') ||
        onayTipiLower.contains('satin')) {
      return 'Satın Alma Detayı';
    } else if (onayTipiLower.contains('teknik destek')) {
      return _resolveTeknikBilgiBaslik(talep.hizmetTuru);
    } else if (onayTipiLower.contains('sarf malzeme')) {
      return 'Sarf Malzeme Detayı';
    } else if (onayTipiLower.contains('yiyecek') ||
        onayTipiLower.contains('içecek') ||
        onayTipiLower.contains('icecek')) {
      return 'Yiyecek İçecek Detayı';
    } else if (onayTipiLower.contains('eğitim') ||
        onayTipiLower.contains('egitim')) {
      return 'Eğitim İstek Detayı';
    }

    return 'İstek Detayı';
  }

  /// Talep türüne göre uygun detay ekranını oluştur
  Widget _buildDetayScreen(Talep talep) {
    final onayTipi = talep.onayTipi.toLowerCase();

    if (onayTipi.contains('izin')) {
      return IzinIstekDetayScreen(
        talepId: talep.onayKayitId,
        onayTipi: talep.onayTipi,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('araç') || onayTipi.contains('arac')) {
      return AracIstekDetayScreen(
        talepId: talep.onayKayitId,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('dok')) {
      return DokumantasyonIstekDetayScreen(
        talepId: talep.onayKayitId,
        onayTipi: talep.onayTipi,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('satın') || onayTipi.contains('satin')) {
      return SatinAlmaDetayScreen(
        talepId: talep.onayKayitId,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('teknik destek')) {
      // Teknik destek ve Bilgi teknolojileri için isTamamlanan geçilmiyor (istenildiği gibi)
      return TeknikDestekDetayScreen(talepId: talep.onayKayitId);
    } else if (onayTipi.contains('sarf malzeme')) {
      return SarfMalzemeDetayScreen(
        talepId: talep.onayKayitId,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('yiyecek') ||
        onayTipi.contains('içecek') ||
        onayTipi.contains('icecek')) {
      return YiyecekIcecekDetayScreen(
        talepId: talep.onayKayitId,
        isTamamlanan: widget.isTamamlanan,
      );
    } else if (onayTipi.contains('eğitim') || onayTipi.contains('egitim')) {
      return EgitimIstekDetayScreen(
        talepId: talep.onayKayitId,
        isTamamlanan: widget.isTamamlanan,
      );
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
    final onayTipiLower = currentTalep.onayTipi.toLowerCase();

    final teknikDetayAsync = onayTipiLower.contains('teknik destek')
        ? ref.watch(teknikDestekDetayProvider(currentTalep.onayKayitId))
        : null;

    final detayBaslik = onayTipiLower.contains('teknik destek')
        ? teknikDetayAsync?.maybeWhen(
                data: (detay) => _resolveTeknikBilgiBaslik(detay.hizmetTuru),
                orElse: () => _resolveTeknikBilgiBaslikFromTalep(currentTalep),
              ) ??
              _resolveTeknikBilgiBaslikFromTalep(currentTalep)
        : _getDetayBaslik(currentTalep);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.of(context).pop(_currentIndex);
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            onPressed: () => Navigator.of(context).pop(_currentIndex),
          ),
          title: Text(
            '$detayBaslik (${currentTalep.onayKayitId})',
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
          physics:
              const ClampingScrollPhysics(), // Smooth scroll, no bounce or blur
          clipBehavior: Clip.hardEdge, // Hard edges without blur effects
          allowImplicitScrolling: false,
          pageSnapping: true,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            // Yeni sayfaya geçildiğinde provider'ı invalidate et - güncel veri çek
            _invalidateDetayProvider(widget.talepList[index]);
            // Yeni sayfayı okundu olarak işaretle
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
      ),
    );
  }
}

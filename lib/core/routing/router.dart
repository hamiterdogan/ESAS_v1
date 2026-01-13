import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/talep/screens/home_screen.dart';
import 'package:esas_v1/features/talep/screens/empty_talep_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_talep_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_talep_yonetim_screen.dart';
import 'package:esas_v1/features/satin_alma/screens/satin_alma_detay_screen.dart';
import 'package:esas_v1/features/talep/models/talep_turu.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_talep_yonetim_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_talep_ekle_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_yuk_ekle_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_turu_secim_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/gidilecek_yer_secim_screen.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_liste_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_ekle_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_talep_yonetim_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_turu_secim_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/a4_kagidi_istek_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_baski_istek_screen.dart';
import 'package:esas_v1/features/dokumantasyon_istek/screens/dokumantasyon_istek_detay_screen.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_talep_yonetim_screen.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_talep_screen.dart';
import 'package:esas_v1/features/egitim_istek/screens/egitim_istek_detay_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_talep_yonetim_screen.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/screens/sarf_malzeme_turu_secim_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_talep_yonetim_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_istek_screen.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/screens/yiyecek_icecek_detay_screen.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/screens/bilgi_teknoloji_talep_yonetim_screen.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/screens/bilgi_teknolojileri_istek_screen.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/screens/teknik_destek_turu_secim_screen.dart';
import 'package:esas_v1/features/teknik_destek_istek/screens/teknik_destek_talep_yonetim_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),

    GoRoute(
      path: '/arac_istek',
      builder: (context, state) => const AracTalepYonetimScreen(),
    ),
    GoRoute(
      path: '/arac/detay/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return AracIstekDetayScreen(talepId: id);
      },
    ),
    GoRoute(
      path: '/arac/turu_secim',
      builder: (context, state) => const AracTuruSecimScreen(),
    ),
    GoRoute(
      path: '/arac/ekle/:tuId',
      builder: (context, state) {
        final tuId = int.tryParse(state.pathParameters['tuId'] ?? '') ?? 0;
        return AracTalepEkleScreen(tuId: tuId);
      },
    ),
    GoRoute(
      path: '/arac/yuk/ekle/:tuId',
      builder: (context, state) {
        final tuId = int.tryParse(state.pathParameters['tuId'] ?? '') ?? 0;
        return AracIstekYukEkleScreen(tuId: tuId);
      },
    ),
    GoRoute(
      path: '/arac/gidilecek_yer_sec',
      builder: (context, state) {
        final initial = state.extra is List<GidilecekYer>
            ? state.extra as List<GidilecekYer>
            : const <GidilecekYer>[];
        return GidilecekYerSecimScreen(initiallySelected: initial);
      },
    ),

    GoRoute(
      path: '/izin_istek',
      builder: (context, state) => const IzinListeScreen(),
    ),
    GoRoute(path: '/izin/liste', redirect: (context, state) => '/izin_istek'),
    GoRoute(
      path: '/izin/ekle',
      builder: (context, state) => const IzinEkleScreen(),
    ),
    GoRoute(
      path: '/izin/detay/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return IzinIstekDetayScreen(talepId: id);
      },
    ),

    GoRoute(
      path: '/bilgi_teknolojileri',
      builder: (context, state) =>
          const BilgiTeknolojiBilgiTalepYonetimScreen(),
      routes: [
        GoRoute(
          path: 'ekle',
          builder: (context, state) => const BilgiTeknolojileriIstekScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/dokumantasyon_istek',
      builder: (context, state) => const DokumantasyonTalepYonetimScreen(),
    ),
    GoRoute(
      path: '/dokumantasyon/detay/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        final onayTipi = state.extra is String ? state.extra as String : null;
        return DokumantasyonIstekDetayScreen(talepId: id, onayTipi: onayTipi);
      },
    ),
    GoRoute(
      path: '/dokumantasyon/turu_secim',
      builder: (context, state) => const DokumantasyonTuruSecimScreen(),
    ),
    GoRoute(
      path: '/dokumantasyon/a4_kagidi',
      builder: (context, state) => const A4KagidiIstekScreen(),
    ),
    GoRoute(
      path: '/dokumantasyon/baski',
      builder: (context, state) => const DokumantasyonBaskiIstekScreen(),
    ),
    GoRoute(
      path: '/egitim_istek',
      builder: (context, state) => const EgitimTalepYonetimScreen(),
    ),
    GoRoute(
      path: '/egitim_istek/ekle',
      builder: (context, state) => const EgitimTalepScreen(),
    ),
    GoRoute(
      path: '/egitim_istek/detay/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return EgitimIstekDetayScreen(talepId: id);
      },
    ),
    GoRoute(
      path: '/sarf_malzeme_istek',
      builder: (context, state) => const SarfMalzemeTalepYonetimScreen(),
    ),
    GoRoute(
      path: '/sarf_malzeme_istek/tur-secim',
      builder: (context, state) => const SarfMalzemeTuruSecimScreen(),
    ),
    GoRoute(
      path: '/sarf_malzeme_istek/ekle',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.sarfMalzemeIstek),
      ),
    ),
    GoRoute(
      path: '/satin_alma',
      builder: (context, state) => const SatinAlmaTalepYonetimScreen(),
    ),
    GoRoute(
      path: '/satin_alma/ekle',
      builder: (context, state) => const SatinAlmaTalepScreen(),
    ),
    GoRoute(
      path: '/satin_alma/detay/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return SatinAlmaDetayScreen(talepId: id);
      },
    ),
    GoRoute(
      path: '/teknik_destek',
      builder: (context, state) => const TeknikDeskekTalepYonetimScreen(),
      routes: [
        GoRoute(
          path: 'ekle',
          builder: (context, state) => const TeknikDestekTuruSecimScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/yiyecek_icecek_istek',
      builder: (context, state) => const YiyecekIcecekTalepYonetimScreen(),
      routes: [
        GoRoute(
          path: 'ekle',
          builder: (context, state) => const YiyecekIcecekIstekScreen(),
        ),
        GoRoute(
          path: 'detay/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return YiyecekIcecekDetayScreen(talepId: id);
          },
        ),
      ],
    ),
  ],
);

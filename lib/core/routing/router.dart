import 'package:go_router/go_router.dart';
import 'package:esas_v1/features/talep/screens/home_screen.dart';
import 'package:esas_v1/features/talep/screens/empty_talep_screen.dart';
import 'package:esas_v1/features/talep/models/talep_turu.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_talep_yonetim_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_istek_detay_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_talep_ben_ekle_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/arac_turu_secim_screen.dart';
import 'package:esas_v1/features/arac_istek/screens/gidilecek_yer_secim_screen.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_liste_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_ekle_screen.dart';
import 'package:esas_v1/features/izin_istek/screens/izin_istek_detay_screen.dart';

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
        return AracTalepBenEkleScreen(tuId: tuId);
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
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.bilgiTeknolojileri),
      ),
    ),
    GoRoute(
      path: '/dokumantasyon_istek',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.dokumantasyonIstek),
      ),
    ),
    GoRoute(
      path: '/egitim_istek',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.egitimIstek),
      ),
    ),
    GoRoute(
      path: '/sarf_malzeme_istek',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.sarfMalzemeIstek),
      ),
    ),
    GoRoute(
      path: '/satin_alma',
      builder: (context, state) =>
          EmptyTalepScreen(talep: TalepTuru.fromEnum(TalepTuruEnum.satinAlma)),
    ),
    GoRoute(
      path: '/teknik_destek',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.teknikDestek),
      ),
    ),
    GoRoute(
      path: '/yiyecek_icecek_istek',
      builder: (context, state) => EmptyTalepScreen(
        talep: TalepTuru.fromEnum(TalepTuruEnum.yiyecekIcecekIstek),
      ),
    ),
  ],
);

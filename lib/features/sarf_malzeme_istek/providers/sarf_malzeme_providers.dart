import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_turu.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/repositories/sarf_malzeme_repository.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_kategori_models.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_detay_model.dart';
import 'package:esas_v1/core/utils/riverpod_extensions.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/repositories/satin_alma_repository.dart';

final sarfMalzemeRepositoryProvider = Provider<SarfMalzemeRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SarfMalzemeRepository(dio);
});

final sarfMalzemeTemizlikKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5)); // Cache for 5 minutes
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getTemizlikKategorileri();
    });

final sarfMalzemeKirtasiyeKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5)); // Cache for 5 minutes
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getKirtasiyeKategorileri();
    });

final sarfMalzemePromosyonKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5)); // Cache for 5 minutes
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getPromosyonKategorileri();
    });

final sarfMalzemeYiyecekKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5)); // Cache for 5 minutes
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getYiyecekKategorileri();
    });

final sarfMalzemeAltKategorilerProvider = FutureProvider.family
    .autoDispose<List<SarfMalzemeAltKategori>, int>((ref, anaKategoriId) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getAltKategoriler(anaKategoriId);
    });

final allSarfMalzemeTurleriProvider =
    FutureProvider.autoDispose<List<SarfMalzemeTuru>>((ref) async {
      ref.cacheFor(const Duration(minutes: 5)); // Cache for 5 minutes
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getSarfMalzemeTurleri();
    });

final sarfMalzemeDevamEdenTaleplerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeTalep>>((ref) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      final response = await repo.sarfMalzemeTaleplerimiGetir(tip: 0);
      return response.talepler;
    });

final sarfMalzemeTamamlananTaleplerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeTalep>>((ref) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      final response = await repo.sarfMalzemeTaleplerimiGetir(tip: 1);
      return response.talepler;
    });

final sarfMalzemeDetayProvider = FutureProvider.family
    .autoDispose<SarfMalzemeDetayResponse, int>((ref, id) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getSarfMalzemeDetay(id);
    });

// Combined provider for parallel loading of detay screen data
final sarfMalzemeDetayParalelProvider = FutureProvider.family
    .autoDispose<SarfMalzemeDetayParalelData, int>((ref, id) async {
      final results = await Future.wait([
        ref.watch(sarfMalzemeDetayProvider(id).future),
        ref.watch(personelBilgiProvider.future),
        ref.watch(satinAlmaBinalarProvider.future),
      ]);

      return SarfMalzemeDetayParalelData(
        detay: results[0] as SarfMalzemeDetayResponse,
        personel: results[1] as PersonelBilgiResponse,
        binalar: results[2] as List<SatinAlmaBina>,
      );
    });

class SarfMalzemeDetayParalelData {
  final SarfMalzemeDetayResponse detay;
  final PersonelBilgiResponse personel;
  final List<SatinAlmaBina> binalar;

  SarfMalzemeDetayParalelData({
    required this.detay,
    required this.personel,
    required this.binalar,
  });
}

final donemlerProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  ref.cacheFor(
    const Duration(minutes: 10),
  ); // Cache for 10 minutes - rarely changes
  final repo = ref.read(sarfMalzemeRepositoryProvider);
  return repo.getDonemler();
});

final etkinlikAdlariProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  ref.cacheFor(
    const Duration(minutes: 10),
  ); // Cache for 10 minutes - rarely changes
  final repo = ref.read(sarfMalzemeRepositoryProvider);
  return repo.getEtkinlikAdlari();
});

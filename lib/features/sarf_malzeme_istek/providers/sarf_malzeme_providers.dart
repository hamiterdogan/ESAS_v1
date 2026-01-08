import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_turu.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/repositories/sarf_malzeme_repository.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_kategori_models.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_detay_model.dart';

final sarfMalzemeRepositoryProvider = Provider<SarfMalzemeRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SarfMalzemeRepository(dio);
});

final sarfMalzemeTemizlikKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getTemizlikKategorileri();
    });

final sarfMalzemeKirtasiyeKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getKirtasiyeKategorileri();
    });

final sarfMalzemePromosyonKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
      final repo = ref.read(sarfMalzemeRepositoryProvider);
      return repo.getPromosyonKategorileri();
    });

final sarfMalzemeYiyecekKategorilerProvider =
    FutureProvider.autoDispose<List<SarfMalzemeAnaKategori>>((ref) async {
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

final donemlerProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.read(sarfMalzemeRepositoryProvider);
  return repo.getDonemler();
});

final etkinlikAdlariProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final repo = ref.read(sarfMalzemeRepositoryProvider);
  return repo.getEtkinlikAdlari();
});

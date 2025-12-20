import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';

class SatinAlmaRepository {
  SatinAlmaRepository(this._dio);

  final Dio _dio;

  Future<List<SatinAlmaBina>> fetchBinalar() async {
    final response = await _dio.get('/TalepYonetimi/BinalariGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => SatinAlmaBina.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <SatinAlmaBina>[];
  }

  Future<List<SatinAlmaAnaKategori>> getAnaKategoriler() async {
    final response = await _dio.get('/SatinAlma/SatinAlmaAnaKategorileriGetir');
    final data = response.data;
    if (data != null && data['anaKtKayitlar'] is List) {
      return (data['anaKtKayitlar'] as List)
          .map(
            (e) => SatinAlmaAnaKategori.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return const [];
  }

  Future<List<SatinAlmaAltKategori>> getAltKategoriler(
    int anaKategoriId,
  ) async {
    final response = await _dio.post(
      '/SatinAlma/SatinAlmaAltKategorileriGetir',
      data: {'satinAlmaAnaKategoriId': anaKategoriId},
    );
    final data = response.data;
    if (data != null && data['altKtKayitlar'] is List) {
      return (data['altKtKayitlar'] as List)
          .map(
            (e) => SatinAlmaAltKategori.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return const [];
  }

  Future<List<SatinAlmaOlcuBirim>> getOlcuBirimleri() async {
    final response = await _dio.get('/SatinAlma/OlcuBirimleriGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map(
            (e) => SatinAlmaOlcuBirim.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return const <SatinAlmaOlcuBirim>[];
  }
}

final satinAlmaRepositoryProvider = Provider<SatinAlmaRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SatinAlmaRepository(dio);
});

final satinAlmaBinalarProvider =
    FutureProvider.autoDispose<List<SatinAlmaBina>>((ref) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.fetchBinalar();
    });

final satinAlmaAnaKategorilerProvider =
    FutureProvider.autoDispose<List<SatinAlmaAnaKategori>>((ref) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getAnaKategoriler();
    });

final satinAlmaAltKategorilerProvider = FutureProvider.autoDispose
    .family<List<SatinAlmaAltKategori>, int>((ref, anaKategoriId) async {
  final repo = ref.read(satinAlmaRepositoryProvider);
  return repo.getAltKategoriler(anaKategoriId);
});

final satinAlmaOlcuBirimleriProvider =
    FutureProvider.autoDispose<List<SatinAlmaOlcuBirim>>((ref) async {
  final repo = ref.read(satinAlmaRepositoryProvider);
  return repo.getOlcuBirimleri();
});

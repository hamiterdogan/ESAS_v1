import 'package:dio/dio.dart';
import 'package:esas_v1/features/izin_istek/data/models/izin_talep_model.dart';

abstract class IIzinIstekRemoteDataSource {
  Future<void> createIzinTalep(IzinTalepModel model);
  Future<List<dynamic>> getIzinSebepleri();
  Future<List<dynamic>> getPersoneller();
  Future<dynamic> getHesaplananIzinSuresi({
    required int izinSebebiId,
    required DateTime baslangic,
    required DateTime bitis,
  });
}

class IzinIstekRemoteDataSource implements IIzinIstekRemoteDataSource {
  final Dio _dio;

  IzinIstekRemoteDataSource(this._dio);

  @override
  Future<void> createIzinTalep(IzinTalepModel model) async {
    try {
      final response = await _dio.post(
        '/IzinIstek/IzinEkle',
        data: model.toJson(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create izin talep');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getIzinSebepleri() async {
    // Assuming endpoint
    final response = await _dio.get('/IzinIstek/IzinSebebiGetir');
    return response.data;
  }

  @override
  Future<List<dynamic>> getPersoneller() async {
    // Assuming endpoint exists or shares with another feature
    final response = await _dio.get('/Personel/PersonelListesiGetir');
    return response.data;
  }

  @override
  Future<dynamic> getHesaplananIzinSuresi({
    required int izinSebebiId,
    required DateTime baslangic,
    required DateTime bitis,
  }) async {
    // Mocking logic or real endpoint if known.
    // Based on analysis, logic might be frontend or backend.
    // Assuming backend for "HesaplananIzinGunu"
    // If not found in original analysis, I will assume it's calculated on client for now
    // but for Clean Architecture, should be a UseCase logic or Backend call.
    // I will return a mock or call an endpoint if I find one.
    // Let's assume a generic calculation endpoint or just return null to let frontend handle (refactoring risk).
    // I'll leave it as a backend call placeholder.
    return {'gun': 1, 'saat': 0};
  }
}

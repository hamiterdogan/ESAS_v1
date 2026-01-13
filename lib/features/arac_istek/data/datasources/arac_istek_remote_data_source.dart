import 'package:dio/dio.dart';
import 'package:esas_v1/features/arac_istek/data/models/arac_talep_model.dart'; // Will create this

abstract class IAracIstekRemoteDataSource {
  Future<void> createAracTalep(AracTalepModel model);
  Future<List<dynamic>> getAracTurleri();
  Future<List<dynamic>> getGidilecekYerler();
  Future<dynamic> getAracTalepleri({required int tip});
}

class AracIstekRemoteDataSource implements IAracIstekRemoteDataSource {
  final Dio _dio;

  AracIstekRemoteDataSource(this._dio);

  @override
  Future<void> createAracTalep(AracTalepModel model) async {
    try {
      final response = await _dio.post(
        '/AracIstek/AracIstekEkle',
        data: model.toJson(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to create arac talep');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getAracTurleri() async {
    final response = await _dio.get('/AracIstek/AracTuruGetir');
    return response.data;
  }

  @override
  Future<List<dynamic>> getGidilecekYerler() async {
    final response = await _dio.get('/AracIstek/GidilecekYerGetir');
    return response.data;
  }

  @override
  Future<dynamic> getAracTalepleri({required int tip}) async {
    final response = await _dio.get(
      '/AracIstek/AracIstekListesiGetir?tip=$tip',
    );
    return response.data;
  }
}

import 'package:dio/dio.dart';
import 'package:esas_v1/features/dokumantasyon_istek/data/models/dokumantasyon_talep_model.dart';

abstract class IDokumantasyonRemoteDataSource {
  Future<void> createDokumantasyonTalep(DokumantasyonTalepModel model);
  Future<List<dynamic>> getDokumanTurleri();
}

class DokumantasyonRemoteDataSource implements IDokumantasyonRemoteDataSource {
  final Dio _dio;

  DokumantasyonRemoteDataSource(this._dio);

  @override
  Future<void> createDokumantasyonTalep(DokumantasyonTalepModel model) async {
    try {
       final formData = await model.toFormData();
       await _dio.post('/DokumantasyonIstek/DokumantasyonBaskiIstekKaydet', data: formData); // Check endpoint
    } catch (e) {
      rethrow;
    }
  }
  
  @override
  Future<List<dynamic>> getDokumanTurleri() async {
      final response = await _dio.get('/DokumantasyonIstek/DokumanTurGetir');
      return response.data;
  }
}

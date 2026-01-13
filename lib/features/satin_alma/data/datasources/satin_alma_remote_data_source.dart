import 'package:dio/dio.dart';
import 'package:esas_v1/features/satin_alma/data/models/satin_alma_talep_model.dart';

abstract class ISatinAlmaRemoteDataSource {
  Future<void> createSatinAlmaTalep(SatinAlmaTalepModel model);
  Future<List<dynamic>> getBinalar();
  Future<List<dynamic>> getAnaKategoriler();
  Future<List<dynamic>> getAltKategoriler(int anaKategoriId);
  Future<List<dynamic>> getBirimler();
  Future<List<dynamic>> getParaBirimleri();
  Future<List<dynamic>> getOdemeSekilleri();
}

class SatinAlmaRemoteDataSource implements ISatinAlmaRemoteDataSource {
  final Dio _dio;

  SatinAlmaRemoteDataSource(this._dio);

  @override
  Future<void> createSatinAlmaTalep(SatinAlmaTalepModel model) async {
    try {
      // Check if files exist, use FormData
      if (model.files.isNotEmpty) {
          final formData = await model.toFormData();
          await _dio.post('/SatinAlma/TalepEkle', data: formData); // Endpoint?
      } else {
          // JSON
          await _dio.post('/SatinAlma/TalepEkle', data: model.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<dynamic>> getBinalar() async {
    final response = await _dio.get('/Ortak/BinaListesiGetir'); // Validating endpoint names is hard without doc
    return response.data;
  }

  @override
  Future<List<dynamic>> getAnaKategoriler() async {
    final response = await _dio.get('/SatinAlma/AnaKategoriGetir');
    return response.data;
  }

  @override
  Future<List<dynamic>> getAltKategoriler(int anaKategoriId) async {
    final response = await _dio.get('/SatinAlma/AltKategoriGetir?anaKategoriId=$anaKategoriId');
    return response.data;
  }
  
  @override
  Future<List<dynamic>> getBirimler() async {
    final response = await _dio.get('/Ortak/BirimGetir');
    return response.data;
  }
  
  @override
  Future<List<dynamic>> getParaBirimleri() async {
    final response = await _dio.get('/Ortak/ParaBirimiGetir');
    return response.data;
  }
  
  @override
  Future<List<dynamic>> getOdemeSekilleri() async {
    final response = await _dio.get('/SatinAlma/OdemeSekliGetir');
    return response.data;
  }
}

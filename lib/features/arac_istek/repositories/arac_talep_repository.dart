import 'package:dio/dio.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_detay_model.dart';
import 'package:esas_v1/features/arac_istek/models/arac_turu_model.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';

abstract class AracTalepRepository {
  Future<Result<TalepYonetimResponse>> aracTaleplerimiGetir({
    required int tip, // 0: Devam eden, 1: Tamamlanan
  });

  Future<Result<AracIstekDetayResponse>> aracIstekDetayGetir({required int id});

  Future<Result<List<AracTuru>>> aracTurleriGetir();

  Future<Result<List<GidilecekYer>>> gidilecekYerleriGetir();
}

class AracTalepRepositoryImpl implements AracTalepRepository {
  final Dio _dio;

  AracTalepRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<TalepYonetimResponse>> aracTaleplerimiGetir({
    required int tip,
  }) async {
    try {
      print('📡 AracTaleplerimiGetir çağrısı: tip=$tip');

      final response = await _dio.post(
        '/AracIstek/AracTaleplerimiGetir',
        // Sunucu bu endpointte JSON string bekliyor; aynı izin istek yapısındaki gibi gönderiyoruz.
        data: '{"tip": $tip}',
        options: Options(contentType: 'application/json'),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = TalepYonetimResponse.fromJson(response.data);
        print('✅ ${data.talepler.length} araç talebi geldi');
        return Success(data);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<AracIstekDetayResponse>> aracIstekDetayGetir({
    required int id,
  }) async {
    try {
      final response = await _dio.post(
        '/AracIstek/AracIstekDetay',
        data: {'id': id},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> dataMap;
        if (response.data is Map) {
          dataMap = Map<String, dynamic>.from(response.data as Map);
          if (dataMap['data'] is Map) {
            dataMap = Map<String, dynamic>.from(dataMap['data'] as Map);
          }
        } else {
          dataMap = <String, dynamic>{};
        }

        return Success(AracIstekDetayResponse.fromJson(dataMap));
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<AracTuru>>> aracTurleriGetir() async {
    try {
      print('📡 AracTurleriGetir API çağrısı');

      final response = await _dio.get('/AracIstek/AracTuruGetir');

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final aracTurleri = data
            .map((item) => AracTuru.fromJson(item as Map<String, dynamic>))
            .toList();
        print('✅ ${aracTurleri.length} araç türü geldi');
        return Success(aracTurleri);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<GidilecekYer>>> gidilecekYerleriGetir() async {
    try {
      final response = await _dio.get('/TalepYonetimi/GidilecekYerGetir');

      if (response.statusCode == 200) {
        // API bazen List, bazen { data: [...] } dönebilir
        List<dynamic> listData;
        if (response.data is List) {
          listData = response.data as List<dynamic>;
        } else if (response.data is Map &&
            (response.data['data'] is List ||
                response.data['Data'] is List)) {
          listData = (response.data['data'] ?? response.data['Data'])
              as List<dynamic>;
        } else {
          listData = const [];
        }

        final yerler = listData
            .whereType<Map>()
            .map((item) =>
                GidilecekYer.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        return Success(yerler);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

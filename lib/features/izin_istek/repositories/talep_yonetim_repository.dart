import 'package:dio/dio.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay_model.dart';
import 'package:esas_v1/features/izin_istek/models/izin_talepleri_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_yeri_model.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';

abstract class TalepYonetimRepository {
  Future<Result<TalepYonetimResponse>> taleplerimiGetir({
    required int tip, // 0: Devam eden, 1: Tamamlanan
  });

  Future<Result<IzinTalepleriResponse>> izinTaleplerimiGetir();

  Future<Result<IzinTalepleriResponse>> izinTaleplerimiGetirByTip({
    required int tip, // 0: Onay Bekliyor, 1: Onaylanmış
  });

  Future<Result<IzinIstekDetayResponse>> izinIstekDetayiGetir({
    required int id,
  });

  Future<Result<void>> izinIstekSil({required int id});

  Future<Result<List<Gorev>>> gorevleriGetir();

  Future<Result<List<GorevYeri>>> gorevYerleriniGetir();

  Future<Result<OnayDurumuResponse>> onayDurumuGetir({
    required int talepId,
    required String onayTipi,
  });
}

class TalepYonetimRepositoryImpl implements TalepYonetimRepository {
  final Dio dio;

  TalepYonetimRepositoryImpl({required this.dio});

  @override
  Future<Result<TalepYonetimResponse>> taleplerimiGetir({
    required int tip,
  }) async {
    try {
      print('📡 TaleplerimiGetir API çağrısı: tip=$tip');

      final response = await dio.post(
        '/TalepYonetimi/TaleplerimiGetir',
        data: {'tip': tip},
        options: Options(contentType: 'application/json'),
      );

      print('📡 Response alındı. Status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = TalepYonetimResponse.fromJson(response.data);
        print('✅ Başarılı! ${data.talepler.length} talep bulundu');
        return Success(data);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<IzinTalepleriResponse>> izinTaleplerimiGetir() async {
    try {
      print('📡 API çağrısı başlıyor: /IzinIstek/IzinTaleplerimiGetir');
      final response = await dio.post(
        '/IzinIstek/IzinTaleplerimiGetir',
        data: '{}',
        options: Options(contentType: 'application/json'),
      );

      print('📡 Response alındı. Status: ${response.statusCode}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = IzinTalepleriResponse.fromJson(response.data);
        print('✅ Başarılı! ${data.talepler.length} talep bulundu');
        return Success(data);
      }

      print('❌ Status hata: ${response.statusCode}');
      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<IzinTalepleriResponse>> izinTaleplerimiGetirByTip({
    required int tip,
  }) async {
    try {
      print('🔹 [REPO] izinTaleplerimiGetirByTip başladı: tip=$tip');
      print(
        '📡 API çağrısı başlıyor: /IzinIstek/IzinTaleplerimiGetir (tip: $tip)',
      );
      final response = await dio.post(
        '/IzinIstek/IzinTaleplerimiGetir',
        data: '{"tip": $tip}',
        options: Options(contentType: 'application/json'),
      );

      print('🔹 [REPO] Response statusCode: ${response.statusCode}');
      print('🔹 [REPO] Response data type: ${response.data.runtimeType}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔹 [REPO] JSON parse başladı');
        final data = IzinTalepleriResponse.fromJson(response.data);
        print('✅ Başarılı! ${data.talepler.length} talep bulundu');
        data.talepler.forEach((t) {
          print('  ✓ ${t.onayKayitID}: ${t.izinTuru} - ${t.onayDurumu}');
        });
        return Success(data);
      }

      print('❌ Status hata: ${response.statusCode}');
      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<IzinIstekDetayResponse>> izinIstekDetayiGetir({
    required int id,
  }) async {
    try {
      final response = await dio.post(
        '/IzinIstek/IzinIstekDetay',
        data: {'id': id},
      );

      if (response.statusCode == 200) {
        final data = IzinIstekDetayResponse.fromJson(response.data);
        return Success(data);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> izinIstekSil({required int id}) async {
    try {
      final response = await dio.post(
        '/IzinIstek/IzinIstekSil',
        data: {'id': id},
      );

      if (response.statusCode == 200) {
        return Success(null);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Gorev>>> gorevleriGetir() async {
    try {
      print('📡 GorevDoldur API çağrısı başlıyor');
      final response = await dio.get('/TalepYonetimi/GorevDoldur');

      print('📡 Response alındı. Status: ${response.statusCode}');
      print('📡 Response data type: ${response.data.runtimeType}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic>? dataList;

        // Response doğrudan liste ise
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        }
        // Response obje içinde liste ise
        else if (response.data is Map) {
          final Map<String, dynamic> body =
              response.data as Map<String, dynamic>;
          if (body.containsKey('data') && body['data'] is List) {
            dataList = body['data'] as List<dynamic>;
          } else if (body.containsKey('result') && body['result'] is List) {
            dataList = body['result'] as List<dynamic>;
          } else if (body.containsKey('items') && body['items'] is List) {
            dataList = body['items'] as List<dynamic>;
          } else if (body.containsKey('gorevler') && body['gorevler'] is List) {
            dataList = body['gorevler'] as List<dynamic>;
          }
        }

        if (dataList != null) {
          final gorevler = dataList
              .map((e) => Gorev.fromJson(e as Map<String, dynamic>))
              .toList();
          print('✅ Başarılı! ${gorevler.length} görev bulundu');
          return Success(gorevler);
        }

        print('❌ Response formatı tanınmadı');
        return Failure('Beklenmeyen response formatı');
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<GorevYeri>>> gorevYerleriniGetir() async {
    try {
      print('📡 GorevYeriDoldur API çağrısı başlıyor');
      final response = await dio.get('/TalepYonetimi/GorevYeriDoldur');

      print('📡 Response alındı. Status: ${response.statusCode}');
      print('📡 Response data type: ${response.data.runtimeType}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic>? dataList;

        // Response doğrudan liste ise
        if (response.data is List) {
          dataList = response.data as List<dynamic>;
        }
        // Response obje içinde liste ise
        else if (response.data is Map) {
          final Map<String, dynamic> body =
              response.data as Map<String, dynamic>;
          if (body.containsKey('data') && body['data'] is List) {
            dataList = body['data'] as List<dynamic>;
          } else if (body.containsKey('result') && body['result'] is List) {
            dataList = body['result'] as List<dynamic>;
          } else if (body.containsKey('items') && body['items'] is List) {
            dataList = body['items'] as List<dynamic>;
          } else if (body.containsKey('gorevYerleri') &&
              body['gorevYerleri'] is List) {
            dataList = body['gorevYerleri'] as List<dynamic>;
          }
        }

        if (dataList != null) {
          final gorevYerleri = dataList
              .map((e) => GorevYeri.fromJson(e as Map<String, dynamic>))
              .toList();
          print('✅ Başarılı! ${gorevYerleri.length} görev yeri bulundu');
          return Success(gorevYerleri);
        }

        print('❌ Response formatı tanınmadı');
        return Failure('Beklenmeyen response formatı');
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<OnayDurumuResponse>> onayDurumuGetir({
    required int talepId,
    required String onayTipi,
  }) async {
    try {
      print(
        '📡 OnayDurumuGetir API çağrısı: talepId=$talepId, onayTipi=$onayTipi',
      );

      // onayTipi bazı listelerde farklı/boş gelebiliyor; API sabit "İzin İstek" bekliyor.
      final normalizedOnayTipi = onayTipi.trim().isNotEmpty
          ? onayTipi.trim()
          : 'İzin İstek';

      final response = await dio.post(
        '/TalepYonetimi/OnayDurumuGetir',
        data: {'onayTipi': normalizedOnayTipi, 'onayKayitID': talepId},
        options: Options(contentType: 'application/json'),
      );

      print('📡 Response alındı. Status: ${response.statusCode}');

      // API response'ı Map'e dönüştür
      late Map<String, dynamic> data;
      if (response.data is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(
          response.data as Map,
        );
        // Eğer { data: {...} } şeklinde sarmalanmışsa aç
        data = map.containsKey('data') && map['data'] is Map
            ? Map<String, dynamic>.from(map['data'] as Map)
            : map;
      } else {
        data = <String, dynamic>{};
      }

      if (data.isNotEmpty) {
        final result = OnayDurumuResponse.fromJson(data);
        print('✅ OnayDurumu başarıyla alındı');
        return Success(result);
      }

      return Failure('Onay durumu verisi boş');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }
}

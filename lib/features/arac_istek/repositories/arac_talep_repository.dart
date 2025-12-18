import 'package:dio/dio.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/utils/app_logger.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_detay_model.dart';
import 'package:esas_v1/features/arac_istek/models/arac_turu_model.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_ekle_req.dart';
import 'package:esas_v1/features/arac_istek/models/arac_talep_form_models.dart';

abstract class AracTalepRepository {
  Future<Result<TalepYonetimResponse>> aracTaleplerimiGetir({
    required int tip, // 0: Devam eden, 1: Tamamlanan
  });

  Future<Result<AracIstekDetayResponse>> aracIstekDetayGetir({required int id});

  Future<Result<List<AracTuru>>> aracTurleriGetir();

  Future<Result<List<GidilecekYer>>> gidilecekYerleriGetir();

  /// Yeni araç talebi oluştur
  Future<Result<void>> aracIstekEkle(AracIstekEkleReq request);

  /// Araç istek nedenleri dropdown'ı için verileri getir
  Future<Result<List<AracIstekNedeniItem>>> aracIstekNedenleriGetir();

  /// Personel seçimi için gerekli tüm verileri getir (personel + görev + görev yeri)
  Future<Result<PersonelSecimData>> personelSecimVerisiGetir();

  /// Öğrenci filtre verisi getir (ilk çağrı)
  Future<Result<OgrenciFilterResponse>> ogrenciFiltrele();

  /// Öğrenci filtre verisi getir (seçimlere göre)
  Future<Result<OgrenciFilterResponse>> mobilOgrenciFiltrele({
    required Set<String> okulKodlari,
    required Set<String> seviyeler,
    required Set<String> siniflar,
    required Set<String> kulupler,
    required Set<String> takimlar,
  });

  /// Araç istek formu için gidilecek yer dropdown'ı
  Future<Result<List<GidilecekYerItem>>> aracIstekGidilecekYerGetir();

  /// Araç isteğini sil
  Future<Result<void>> aracIstekSil({required int id});
}

class AracTalepRepositoryImpl implements AracTalepRepository {
  final Dio _dio;
  static const _tag = 'AracTalepRepository';

  AracTalepRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<TalepYonetimResponse>> aracTaleplerimiGetir({
    required int tip,
  }) async {
    try {
      AppLogger.api(
        'AracTaleplerimiGetir çağrısı',
        method: 'POST',
        url: '/AracIstek/AracTaleplerimiGetir',
      );

      final response = await _dio.post(
        '/AracIstek/AracTaleplerimiGetir',
        // Sunucu bu endpointte JSON string bekliyor; aynı izin istek yapısındaki gibi gönderiyoruz.
        data: '{"tip": $tip}',
        options: Options(contentType: 'application/json'),
      );

      AppLogger.api('Response received', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = TalepYonetimResponse.fromJson(response.data);
        AppLogger.info('${data.talepler.length} araç talebi geldi', tag: _tag);
        return Success(data);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('DioException: ${e.message}', tag: _tag, error: e);
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Unexpected error',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
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
      AppLogger.api(
        'AracTurleriGetir çağrısı',
        method: 'GET',
        url: '/AracIstek/AracTuruGetir',
      );

      final response = await _dio.get('/AracIstek/AracTuruGetir');

      AppLogger.api('Response received', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : [];
        final aracTurleri = data
            .map((item) => AracTuru.fromJson(item as Map<String, dynamic>))
            .toList();
        AppLogger.info('${aracTurleri.length} araç türü geldi', tag: _tag);
        return Success(aracTurleri);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('DioException: ${e.message}', tag: _tag, error: e);
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Unexpected error',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
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
            (response.data['data'] is List || response.data['Data'] is List)) {
          listData =
              (response.data['data'] ?? response.data['Data']) as List<dynamic>;
        } else {
          listData = const [];
        }

        final yerler = listData
            .whereType<Map>()
            .map(
              (item) => GidilecekYer.fromJson(Map<String, dynamic>.from(item)),
            )
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

  @override
  Future<Result<void>> aracIstekEkle(AracIstekEkleReq request) async {
    try {
      AppLogger.api(
        'AracIstekEkle çağrısı',
        method: 'POST',
        url: '/AracIstek/AracIstekEkle',
      );

      final response = await _dio.post(
        '/AracIstek/AracIstekEkle',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('DioException: ${e.message}', tag: _tag, error: e);
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Unexpected error',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<AracIstekNedeniItem>>> aracIstekNedenleriGetir() async {
    try {
      final response = await _dio.get('/AracIstek/AracIstekNedeniDoldur');
      final data = response.data as List<dynamic>;

      return Success([
        AracIstekNedeniItem(id: -1, ad: 'DİĞER'),
        ...data.map(
          (e) => AracIstekNedeniItem.fromJson(e as Map<String, dynamic>),
        ),
      ]);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure('Nedenler yüklenemedi: $e');
    }
  }

  @override
  Future<Result<PersonelSecimData>> personelSecimVerisiGetir() async {
    try {
      final results = await Future.wait([
        _dio.get('/Personel/PersonelleriGetir'),
        _dio.get('/TalepYonetimi/GorevDoldur'),
        _dio.get('/TalepYonetimi/GorevYeriDoldur'),
      ]);

      final personelData = results[0].data as List<dynamic>;
      final gorevData = results[1].data as List<dynamic>;
      final gorevYeriData = results[2].data as List<dynamic>;

      return Success(
        PersonelSecimData(
          personeller: personelData
              .map((e) => PersonelItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          gorevler: gorevData
              .map((e) => GorevItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          gorevYerleri: gorevYeriData
              .map((e) => GorevYeriItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure('Personel verisi alınamadı: $e');
    }
  }

  @override
  Future<Result<OgrenciFilterResponse>> ogrenciFiltrele() async {
    try {
      final response = await _dio.post(
        '/TalepYonetimi/OgrenciFiltrele',
        data: {
          'okulKodu': '0',
          'seviye': '0',
          'sinif': '0',
          'kulup': '0',
          'takim': '0',
        },
      );

      return Success(
        OgrenciFilterResponse.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure('Öğrenci verisi alınamadı: $e');
    }
  }

  @override
  Future<Result<OgrenciFilterResponse>> mobilOgrenciFiltrele({
    required Set<String> okulKodlari,
    required Set<String> seviyeler,
    required Set<String> siniflar,
    required Set<String> kulupler,
    required Set<String> takimlar,
  }) async {
    try {
      final response = await _dio.post(
        '/TalepYonetimi/MobilOgrenciFiltrele',
        data: {
          'okulKodlari': okulKodlari.isEmpty ? ['0'] : okulKodlari.toList(),
          'seviyeler': seviyeler.isEmpty ? ['0'] : seviyeler.toList(),
          'siniflar': siniflar.isEmpty ? ['0'] : siniflar.toList(),
          'kulupler': kulupler.isEmpty ? ['0'] : kulupler.toList(),
          'takimlar': takimlar.isEmpty ? [''] : takimlar.toList(),
        },
      );

      return Success(
        OgrenciFilterResponse.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure('Filtre uygulanırken hata: $e');
    }
  }

  @override
  Future<Result<List<GidilecekYerItem>>> aracIstekGidilecekYerGetir() async {
    try {
      final response = await _dio.get('/AracIstek/GidilecekYerGetir');
      final data = response.data as List<dynamic>;

      return Success([
        GidilecekYerItem(id: 'diger', yerAdi: 'Diğer'),
        ...data.map(
          (e) => GidilecekYerItem.fromJson(e as Map<String, dynamic>),
        ),
      ]);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure('Yerler yüklenemedi: $e');
    }
  }

  @override
  Future<Result<void>> aracIstekSil({required int id}) async {
    try {
      final response = await _dio.post(
        '/AracIstek/AracIstekSil',
        queryParameters: {'id': id},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Success(null);
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

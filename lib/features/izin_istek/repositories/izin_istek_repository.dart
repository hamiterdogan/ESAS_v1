import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_ekle_req.dart';
import 'package:esas_v1/features/izin_istek/models/izin_nedeni.dart';
import 'package:esas_v1/features/izin_istek/models/dini_gun_model.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';

// ===========================
// ABSTRACT REPOSITORY (SÖZLEŞME)
// ===========================
abstract class IzinIstekRepository {
  /// İzin nedenlerini getirir (API: IzinSebebiDoldur)
  Future<Result<List<IzinNedeni>>> getIzinNedenleri();

  /// Dini günleri getirir (API: DiniGunDoldur)
  Future<Result<List<DiniGun>>> getDiniGunler(int personelId);

  /// Yeni izin isteği oluşturur (dosya ile birlikte gönderilebilir)
  Future<Result<void>> izinIstekEkle(IzinIstekEkleReq request, {File? file});

  /// İzin detayını getirir
  Future<Result<IzinIstekDetay>> getIzinDetay(int id);

  /// İzin isteğini siler
  Future<Result<void>> izinIstekSil(int id);

  /// Personelleri getirir (başkası adına başvuru için)
  Future<Result<List<Personel>>> getPersoneller(String query);
}

// ===========================
// REPOSITORY IMPLEMENTATION
// ===========================
class IzinIstekRepositoryImpl implements IzinIstekRepository {
  final Dio _dio;

  IzinIstekRepositoryImpl(this._dio);

  @override
  Future<Result<List<IzinNedeni>>> getIzinNedenleri() async {
    try {
      print('🔍 İzin nedenleri getiriliyor...');
      final response = await _dio.get('/IzinIstek/IzinSebebiDoldur');
      print('✅ Response status: ${response.statusCode}');
      print('📋 Response data type: ${response.data.runtimeType}');
      print('📋 TAM Response data: ${response.data}');
      print('📋 JSON encoded: ${response.data.toString()}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<IzinNedeni> nedenler = (response.data as List).map((item) {
            print('📝 Item: $item');
            return IzinNedeni.fromJson(item as Map<String, dynamic>);
          }).toList();
          print('✅ ${nedenler.length} neden getirildi');
          for (int i = 0; i < nedenler.length; i++) {
            final neden = nedenler[i];
            print(
              '  [$i] ID: ${neden.izinSebebiId}, İçNedeni: ${neden.izinNedeni}, İzinAdı: ${neden.izinAdi}',
            );
          }
          return Success(nedenler);
        }

        if (response.data is Map) {
          final Map<String, dynamic> body =
              response.data as Map<String, dynamic>;

          // Farklı olası response formatlarını kontrol et
          List<dynamic>? dataList;

          if (body.containsKey('data') && body['data'] is List) {
            dataList = body['data'] as List<dynamic>;
          } else if (body.containsKey('result') && body['result'] is List) {
            dataList = body['result'] as List<dynamic>;
          } else if (body.containsKey('items') && body['items'] is List) {
            dataList = body['items'] as List<dynamic>;
          } else if (body.containsKey('value') && body['value'] is List) {
            dataList = body['value'] as List<dynamic>;
          }

          if (dataList != null) {
            final List<IzinNedeni> nedenler = dataList
                .map(
                  (item) => IzinNedeni.fromJson(item as Map<String, dynamic>),
                )
                .toList();
            print('✅ ${nedenler.length} neden getirildi');
            for (var neden in nedenler) {
              print(
                '  - ${neden.izinNedeni} (izinAdi: ${neden.izinAdi}, saatGoster: ${neden.saatGoster})',
              );
            }
            return Success(nedenler);
          }

          print('❌ Bilinmeyen response formatı: ${body.keys}');
          return Failure('Bilinmeyen response formatı: ${body.keys}');
        }

        return Failure(
          'Beklenmeyen response formatı: ${response.data.runtimeType}',
        );
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      return Failure('${e.message} - ${e.response?.data}');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure('Hata: $e');
    }
  }

  @override
  Future<Result<List<DiniGun>>> getDiniGunler(int personelId) async {
    try {
      print('🔍 Dini günler getiriliyor... PersonelId: $personelId');
      final response = await _dio.post(
        '/IzinIstek/DiniGunDoldur',
        data: {'personelId': personelId},
      );
      print('✅ Response status: ${response.statusCode}');
      print('📋 Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<DiniGun> gunler = (response.data as List)
              .map((item) => DiniGun.fromJson(item as Map<String, dynamic>))
              .toList();
          print('✅ ${gunler.length} dini gün getirildi');
          return Success(gunler);
        }
        return Failure('Beklenmeyen veri formatı');
      }
      return Failure('Dini günler getirilemedi: ${response.statusCode}');
    } catch (e) {
      print('❌ Hata: $e');
      return Failure('Bir hata oluştu: $e');
    }
  }

  @override
  Future<Result<void>> izinIstekEkle(
    IzinIstekEkleReq request, {
    File? file,
  }) async {
    try {
      print('🔍 İzin isteği ekleniyor...');

      // STEP 1: Create request via JSON payload
      final jsonPayload = request.toJson();
      print('📤 JSON Payload: $jsonPayload');

      final response = await _dio.post(
        '/IzinIstek/IzinIstekEkle',
        data: jsonPayload,
        options: Options(contentType: 'application/json'),
      );
      print('✅ Response status: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      if (response.statusCode != 200) {
        return Failure('Hata: ${response.statusCode} - ${response.data}');
      }

      // Başarılı response kontrolü
      final responseData = response.data;
      if (responseData == null ||
          (responseData is Map && responseData['basarili'] != true)) {
        return Failure(responseData?['mesaj'] ?? 'İstek oluşturulamadı.');
      }

      final int onayKayitId = responseData['onayKayitId'] ?? 0;
      print('✅ OnayKayitId alındı: $onayKayitId');

      // STEP 2: Upload file if exists
      if (file != null && await file.exists() && onayKayitId > 0) {
        print('📎 Dosya yükleniyor...');

        final fileName = file.path.split(Platform.pathSeparator).last;
        final extension = fileName.split('.').last.toLowerCase();

        // Dosya uzantısından MIME type belirle
        String contentType = 'application/octet-stream';
        switch (extension) {
          case 'pdf':
            contentType = 'application/pdf';
            break;
          case 'jpg':
          case 'jpeg':
            contentType = 'image/jpeg';
            break;
          case 'png':
            contentType = 'image/png';
            break;
          case 'bmp':
            contentType = 'image/bmp';
            break;
          case 'doc':
            contentType = 'application/msword';
            break;
          case 'docx':
            contentType =
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
            break;
          case 'xls':
            contentType = 'application/vnd.ms-excel';
            break;
          case 'xlsx':
            contentType =
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            break;
        }

        print('📎 Dosya: $fileName, MIME: $contentType');

        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );

        final formData = FormData.fromMap({
          'OnayKayitId': onayKayitId,
          'OnayTipi': 'İzin İstek',
          'FormFile': multipartFile,
          'DosyaAciklama': '',
        });

        final uploadResponse = await _dio.post(
          '/Dosya/DosyaYukle',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        print('✅ Dosya yükleme response: ${uploadResponse.statusCode}');
        print('✅ Dosya yükleme data: ${uploadResponse.data}');

        if (uploadResponse.statusCode != 200) {
          return Failure('Dosya yüklenemedi: ${uploadResponse.statusCode}');
        }
      }

      return const Success(null);
    } on DioException catch (e) {
      print('❌ DioException: ${e.message}');
      print('❌ Response data: ${e.response?.data}');
      print('❌ Response status: ${e.response?.statusCode}');
      print('❌ Error type: ${e.type}');

      // Sunucudan gelen hata mesajını çıkar
      String errorMessage = 'Sunucu hatası oluştu';

      if (e.response?.data != null) {
        final data = e.response!.data;
        print('❌ Data type: ${data.runtimeType}');

        if (data is Map<String, dynamic>) {
          if (data.containsKey('mesaj') &&
              data['mesaj'] != null &&
              data['mesaj'].toString().isNotEmpty) {
            errorMessage = data['mesaj'].toString();
          } else if (data.containsKey('message') &&
              data['message'] != null &&
              data['message'].toString().isNotEmpty) {
            errorMessage = data['message'].toString();
          } else if (data.containsKey('error') &&
              data['error'] != null &&
              data['error'].toString().isNotEmpty) {
            errorMessage = data['error'].toString();
          } else if (data.containsKey('title') &&
              data['title'] != null &&
              data['title'].toString().isNotEmpty) {
            errorMessage = data['title'].toString();
          } else if (data.containsKey('errors') && data['errors'] != null) {
            errorMessage = data['errors'].toString();
          } else {
            errorMessage = 'Sunucu hatası: ${e.response?.statusCode}';
          }
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        } else {
          errorMessage =
              'Sunucu hatası: ${e.response?.statusCode ?? "Bilinmeyen"}';
        }
      } else {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'Bağlantı zaman aşımına uğradı';
            break;
          case DioExceptionType.sendTimeout:
            errorMessage = 'İstek gönderme zaman aşımına uğradı';
            break;
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Yanıt alma zaman aşımına uğradı';
            break;
          case DioExceptionType.connectionError:
            errorMessage = 'Sunucuya bağlanılamadı';
            break;
          default:
            errorMessage = e.message ?? 'Bilinmeyen bir hata oluştu';
        }
      }

      print('❌ Final error message: $errorMessage');
      return Failure(errorMessage);
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<IzinIstekDetay>> getIzinDetay(int id) async {
    try {
      print('🔍 İzin detayı getiriliyor: $id');
      final response = await _dio.post(
        '/TalepYonetimi/IzinIstek/IzinIstekDetay',
        data: {'id': id},
      );
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final detay = IzinIstekDetay.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Success(detay);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: $e');
      return Failure(e.toString());
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> izinIstekSil(int id) async {
    try {
      print('🔍 İzin isteği siliniyor: $id');
      final response = await _dio.post(
        '/TalepYonetimi/IzinIstek/IzinIstekSil',
        data: {'id': id},
      );
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: $e');
      return Failure(e.toString());
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Personel>>> getPersoneller(String query) async {
    try {
      print('🔍 Personeller getiriliyor: $query');
      final response = await _dio.get(
        '/Personel/PersonelleriGetir',
        queryParameters: {'aktif': true},
      );
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<Personel> personeller = [];

        if (response.data is List) {
          personeller = (response.data as List)
              .map((item) => Personel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.data is Map &&
            (response.data as Map).containsKey('data')) {
          personeller = ((response.data as Map)['data'] as List)
              .map((item) => Personel.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Filtrele
        if (query.isNotEmpty) {
          final queryLower = query.toLowerCase().trim();
          personeller = personeller
              .where(
                (p) =>
                    p.fullName.toLowerCase().contains(queryLower) ||
                    (p.email?.toLowerCase().contains(queryLower) ?? false) ||
                    (p.telefon?.contains(queryLower) ?? false),
              )
              .toList();
        }

        print('✅ ${personeller.length} personel getirildi');
        return Success(personeller);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ DioException: $e');
      return Failure(e.toString());
    } catch (e) {
      print('❌ Hata: $e');
      return Failure(e.toString());
    }
  }
}

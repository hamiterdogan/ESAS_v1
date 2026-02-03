import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_baski_istek_req.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_guncelle_req.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_detay_model.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

abstract class DokumantasyonIstekRepository {
  Future<Result<void>> dokumantasyonIstekEkle({
    required int paket,
    required String aciklama,
    required DateTime teslimTarihi,
    required bool isA4Talebi,
    String? formFile,
  });

  Future<Result<void>> dokumantasyonBaskiIstekEkle({
    required DokumantasyonBaskiIstekReq request,
    List<File>? files,
  });

  Future<Result<TalepYonetimResponse>> dokumantasyonTaleplerimiGetir({
    required int tip, // 0: Devam eden, 1: Tamamlanan
  });

  Future<Result<DokumantasyonIstekDetayResponse>> dokumantasyonIstekDetayGetir({
    required int id,
  });

  Future<Result<void>> dokumantasyonIstekSil({required int id});

  Future<Result<void>> dokumantasyonIstekGuncelle({
    required DokumantasyonIstekGuncelleReq request,
  });
}

class DokumantasyonIstekRepositoryImpl implements DokumantasyonIstekRepository {
  final Dio _dio;

  DokumantasyonIstekRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<void>> dokumantasyonIstekEkle({
    required int paket,
    required String aciklama,
    required DateTime teslimTarihi,
    required bool isA4Talebi,
    String? formFile,
  }) async {
    try {
      final requestData = {
        'Paket': paket, 
        'teslimTarihi': teslimTarihi.toIso8601String(),
        'paket': paket,
        'aciklama': aciklama,
        'a4Talebi': isA4Talebi,
        'dosyaAciklama': '', 
        'baskiAdedi': 0,
        'kagitTalebi': 'A4', 
        'dokumanTuru': '',
        'departman': '',
        'baskiTuru': '',
        'onluArkali': false,
        'kopyaElden': false,
        'sayfaSayisi': 0,
        'toplamSayfa': 0,
        'ogrenciSayisi': 0,
        'okullarSatir': [],
        'olusturmaTarihi': DateTime.now().toIso8601String(),
      };

      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekEkle',
        data: requestData,
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
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

  @override
  Future<Result<TalepYonetimResponse>> dokumantasyonTaleplerimiGetir({
    required int tip,
  }) async {
    try {
      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonTaleplerimiGetir',
        data: '{"tip": $tip}',
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        return Success(TalepYonetimResponse.fromJson(response.data));
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
  Future<Result<DokumantasyonIstekDetayResponse>> dokumantasyonIstekDetayGetir({
    required int id,
  }) async {
    try {
      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekDetay',
        data: {'id': id},
      );

      if (response.statusCode == 200) {
        return Success(DokumantasyonIstekDetayResponse.fromJson(response.data));
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
  Future<Result<void>> dokumantasyonIstekSil({required int id}) async {
    try {
      final response = await _dio.delete(
        '/DokumantasyonIstek/DokumantasyonIstekSil',
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

  @override
  Future<Result<void>> dokumantasyonIstekGuncelle({
    required DokumantasyonIstekGuncelleReq request,
  }) async {
    try {
      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekGuncelle',
        data: request.toJson(),
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
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

  @override
  Future<Result<void>> dokumantasyonBaskiIstekEkle({
    required DokumantasyonBaskiIstekReq request,
    List<File>? files,
  }) async {
    try {
      // Step 1: Create request via JSON payload
      // Endpoint: /DokumantasyonIstek/DokumantasyonIstekEkle
      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekEkle',
        data: request.toJson(),
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode != 200) {
        return Failure('Hata: ${response.statusCode} - ${response.data}');
      }

      final responseData = response.data;
      if (responseData == null ||
          (responseData is Map && responseData['basarili'] != true)) {
        return Failure(responseData?['mesaj'] ?? 'İstek oluşturulamadı.');
      }

      final int onayKayitId = responseData['onayKayitId'] ?? 0;

      // Step 2: Upload files if any (all files in a single request)
      // Endpoint: /Dosya/DosyaYukle
      if (files != null && files.isNotEmpty && onayKayitId > 0) {
        final Map<String, dynamic> formDataMap = {
          'OnayKayitId': onayKayitId,
          'OnayTipi': 'Dokümantasyon İstek', // Türkçe karakter + boşluk
          'DosyaAciklama': request.dosyaAciklama,
        };

        // Birden fazla dosya için FormFile array oluştur
        final List<MultipartFile> multipartFiles = [];

        for (final file in files) {
          final fileName = file.path.split(Platform.pathSeparator).last;

          // Dosya uzantısından MIME type belirle
          String contentType = 'application/octet-stream';
          final extension = fileName.toLowerCase().split('.').last;
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

          multipartFiles.add(
            await MultipartFile.fromFile(
              file.path,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        }

        // Tüm dosyaları FormFile anahtarıyla ekle (array olarak)
        formDataMap['FormFile'] = multipartFiles;

        final formData = FormData.fromMap(formDataMap);

        final uploadResponse = await _dio.post(
          '/Dosya/DosyaYukle',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        if (uploadResponse.statusCode != 200) {
          return Failure('Dosyalar yüklenirken hata oluştu.');
        }
      }

      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

final dokumantasyonIstekRepositoryProvider =
    Provider<DokumantasyonIstekRepository>((ref) {
      final dio = ref.watch(dioProvider);
      return DokumantasyonIstekRepositoryImpl(dio: dio);
    });

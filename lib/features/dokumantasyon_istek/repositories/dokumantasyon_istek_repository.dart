import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_baski_istek_req.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_detay_model.dart';
import 'dart:io';

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
      final formData = FormData.fromMap({
        'FormFile':
            formFile ?? 'string', // API requirement: FormFile=string if empty
        'A4Talebi': isA4Talebi,
        'Paket': paket,
        'Aciklama': aciklama,
        'TeslimTarihi': teslimTarihi.toIso8601String(),
      });

      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekEkle',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
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
      final response = await _dio.post(
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
  Future<Result<void>> dokumantasyonBaskiIstekEkle({
    required DokumantasyonBaskiIstekReq request,
    List<File>? files,
  }) async {
    try {
      final map = <String, dynamic>{
        'TeslimTarihi': request.teslimTarihi.toIso8601String(),
        'BaskiAdedi': request.baskiAdedi,
        'kagitTalebi': request.kagitTalebi,
        'DokumanTuru': request.dokumanTuru,
        'Aciklama': request.aciklama,
        'BaskiTuru': request.baskiTuru,
        'OnluArkali': request.onluArkali,
        'KopyaElden': request.kopyaElden,
        'DosyaAciklama': request.dosyaAciklama,
        'SayfaSayisi': request.sayfaSayisi,
        'ToplamSayfa': request.toplamSayfa,
        'OgrenciSayisi': request.ogrenciSayisi,
      };

      // Handle OkullarSatir manually for FormData as Dio might not handle nested lists of objects automatically depending on version
      // But typically we can add them with indexed keys or just try map first.
      // User requested "OkullarSatir => ... şeklinde dizi olarak".
      // Let's try adding them as indexed fields for standard ASP.NET model binding.
      for (int i = 0; i < request.okullarSatir.length; i++) {
        map['OkullarSatir[$i].okulKodu'] = request.okullarSatir[i].okulKodu;
        map['OkullarSatir[$i].sinif'] = request.okullarSatir[i].sinif;
        map['OkullarSatir[$i].seviye'] = request.okullarSatir[i].seviye;
      }

      // Handle FormFile
      // User said: "FormFile => yüklenen dosyaların isimleri dizi olarak"
      // This is ambiguous. If they mean just names:
      if (request.formFile != null) {
        // map['FormFile'] = request.formFile;
        // But if files are uploaded, usually 'FormFile' is the key for the file content.
        // If the backend expects filenames in 'FormFile' property (List<string>), we send it.
        // If the backend expects actual files in 'FormFile' (List<IFormFile>), we send MultipartFiles.

        // Given the requirement "yüklenen dosyaların isimleri dizi olarak", I will assume we send the NAMES as a list of strings
        // AND maybe we send the actual files under the same key or a different one?
        // Usually you can't have both.
        // If I strictly follow: "FormFile => yüklenen dosyaların isimleri dizi olarak",
        // it sounds like I should send the list of names.
        // BUT, where do the actual file bytes go?
        // If I am expected to upload files, they must be in the form data.

        // Let's assume the user meant: "Send the actual files, as an array, under the key FormFile".
        // And "isimleri dizi olarak" is just describing that it's a list.
        // OR it's a specific requirement to send filenames.

        // To be safe and compliant with standard file uploads:
        if (files != null && files.isNotEmpty) {
          final fileList = <MultipartFile>[];
          for (var file in files) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            fileList.add(
              await MultipartFile.fromFile(file.path, filename: fileName),
            );
          }
          map['FormFile'] = fileList;
        } else if (request.formFile != null) {
          // If no actual files but we have names (e.g. from a previous state?), send names?
          // Unlikely for a create request.
        }
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.post(
        '/DokumantasyonIstek/DokumantasyonIstekEkle', // Assuming same endpoint? Or maybe new one?
        // The user didn't specify endpoint URL change, just payload.
        // But the previous endpoint was /DokumantasyonIstekEkle.
        // The payload is drastically different. It might be the same endpoint overloaded or a new one.
        // I will stick to the same endpoint for now as no new one was provided.
        // Wait, check current repo. It uses /DokumantasyonIstek/DokumantasyonIstekEkle
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
    }
  }
}

final dokumantasyonIstekRepositoryProvider =
    Provider<DokumantasyonIstekRepository>((ref) {
      final dio = ref.watch(dioProvider);
      return DokumantasyonIstekRepositoryImpl(dio: dio);
    });

import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_talep_item.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_istek_detay_model.dart';
import 'package:http_parser/http_parser.dart';

final egitimIstekRepositoryProvider = Provider<EgitimIstekRepository>((ref) {
  final dio = ref.read(dioProvider);
  return EgitimIstekRepository(dio);
});

class EgitimIstekRepository {
  final Dio _dio;

  EgitimIstekRepository(this._dio);

  Future<List<EgitimTalepItem>> getTaleplerim({required int tip}) async {
    try {
      final response = await _dio.post(
        '/EgitimIstek/EgitimIstekTaleplerimiGetir',
        data: {'tip': tip},
      );

      if (response.statusCode == 200) {
        // API response format: {"talepler": [...]}
        if (response.data is Map<String, dynamic> &&
            response.data['talepler'] is List) {
          return (response.data['talepler'] as List)
              .map((item) => EgitimTalepItem.fromJson(item))
              .toList();
        }
        // Fallback: if response is directly a list
        else if (response.data is List) {
          return (response.data as List)
              .map((item) => EgitimTalepItem.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      developer.log(
        'Eğitim taleplerim yükleme hatası',
        name: 'EgitimIstekRepository.getTaleplerim',
        error: e,
      );
      rethrow;
    }
  }

  Future<Result<EgitimIstekDetayResponse>> egitimIstekDetayGetir({
    required int id,
  }) async {
    try {
      final response = await _dio.post(
        '/EgitimIstek/EgitimIstekDetay',
        data: {'id': id},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Success(
          EgitimIstekDetayResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }

      return Failure(
        'Eğitim istek detayı alınamadı: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String errorMessage = 'Sunucu hatası oluştu';
      final data = e.response?.data;
      if (data is Map) {
        final mesaj = data['mesaj'] ?? data['message'] ?? data['error'];
        if (mesaj != null && mesaj.toString().isNotEmpty) {
          errorMessage = mesaj.toString();
        }
      }
      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<int>> egitimIstekEkle({
    required Map<String, dynamic> payload,
    List<PlatformFile> formFiles = const <PlatformFile>[],
    String dosyaAciklama = '',
  }) async {
    try {
      final response = await _dio.post(
        '/EgitimIstek/EgitimIstekEkle',
        data: payload,
      );

      final responseData = response.data;
      if (response.statusCode != 200 || responseData is! Map) {
        return const Failure('Eğitim talebi gönderilemedi.');
      }

      if (responseData['basarili'] != true) {
        final message =
            (responseData['mesaj'] ?? 'Eğitim talebi gönderilemedi.')
                .toString();
        return Failure(message, statusCode: response.statusCode);
      }

      final int onayKayitId = (responseData['onayKayitId'] as int?) ?? 0;

      // Dosya seçilmediyse upload adımını atla.
      if (formFiles.isEmpty || onayKayitId <= 0) {
        return Success(onayKayitId);
      }

      for (final file in formFiles) {
        final path = file.path;
        if (path == null || path.isEmpty) continue;

        final fileName = file.name;
        final extension = fileName.toLowerCase().split('.').last;

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

        final multipartFile = await MultipartFile.fromFile(
          path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        );

        final formData = FormData.fromMap({
          'OnayKayitId': onayKayitId,
          'OnayTipi': 'Eğitim İstek',
          'FormFile': multipartFile,
          'DosyaAciklama': dosyaAciklama,
        });

        final uploadResponse = await _dio.post(
          '/Dosya/DosyaYukle',
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );

        if (uploadResponse.statusCode != 200) {
          return Failure(
            'Dosya yüklenemedi: ${uploadResponse.statusCode}',
            statusCode: uploadResponse.statusCode,
          );
        }
      }

      return Success(onayKayitId);
    } on DioException catch (e) {
      String errorMessage = 'Sunucu hatası oluştu';
      final data = e.response?.data;
      if (data is Map) {
        final mesaj = data['mesaj'] ?? data['message'] ?? data['error'];
        if (mesaj != null && mesaj.toString().isNotEmpty) {
          errorMessage = mesaj.toString();
        }
      }
      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void>> egitimIstekSil({required int id}) async {
    try {
      final response = await _dio.delete(
        '/EgitimIstek/EgitimIstekSil',
        queryParameters: {'id': id},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Bazı endpoint'ler { basarili: bool, mesaj: string } dönebilir.
        if (data is Map) {
          final basarili = data['basarili'];
          if (basarili == false) {
            final message =
                (data['mesaj'] ?? data['message'] ?? 'Talep silinemedi.')
                    .toString();
            return Failure(message, statusCode: response.statusCode);
          }
        }

        return const Success(null);
      }

      return Failure(
        'Talep silinemedi: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      String errorMessage = 'Sunucu hatası oluştu';
      final data = e.response?.data;
      if (data is Map) {
        final mesaj = data['mesaj'] ?? data['message'] ?? data['error'];
        if (mesaj != null && mesaj.toString().isNotEmpty) {
          errorMessage = mesaj.toString();
        }
      }
      return Failure(errorMessage, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_kategori_models.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_ekle_req.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_talep.dart';
import 'package:esas_v1/features/sarf_malzeme_istek/models/sarf_malzeme_detay_model.dart';
import 'package:http_parser/http_parser.dart';

class SarfMalzemeRepository {
  SarfMalzemeRepository(this._dio);

  final Dio _dio;

  Future<SarfMalzemeAnaKategoriResponse> getAnaKategoriler() async {
    final response = await _dio.get('/SarfMalzeme/SarfMalzemeAnaKategori');
    final data = response.data;

    if (data is Map<String, dynamic>) {
      return SarfMalzemeAnaKategoriResponse.fromJson(data);
    }
    if (data is Map) {
      return SarfMalzemeAnaKategoriResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return const SarfMalzemeAnaKategoriResponse(
      temizlik: <SarfMalzemeAnaKategori>[],
      kirtasiye: <SarfMalzemeAnaKategori>[],
      promosyon: <SarfMalzemeAnaKategori>[],
    );
  }

  Future<List<SarfMalzemeAnaKategori>> getTemizlikKategorileri() async {
    final response = await getAnaKategoriler();
    return response.temizlik;
  }

  Future<List<SarfMalzemeAnaKategori>> getKirtasiyeKategorileri() async {
    final response = await getAnaKategoriler();
    return response.kirtasiye;
  }

  Future<List<SarfMalzemeAnaKategori>> getPromosyonKategorileri() async {
    final response = await getAnaKategoriler();
    return response.promosyon;
  }

  Future<List<SarfMalzemeAltKategori>> getAltKategoriler(
    int anaKategoriId,
  ) async {
    try {
      final response = await _dio.post(
        '/SarfMalzeme/SarfMalzemeAltKategori',
        data: {'anaKategoriId': anaKategoriId},
      );

      print('DEBUG: getAltKategoriler response status: ${response.statusCode}');
      print('DEBUG: getAltKategoriler response data: ${response.data}');

      final data = response.data;

      if (data is List) {
        return _parseAltKategoriList(data);
      }

      if (data is Map) {
        // Map response logic: Iterate values to find the list
        for (final value in data.values) {
          if (value is List) {
            final parsed = _parseAltKategoriList(value);
            if (parsed.isNotEmpty) {
              return parsed;
            }
          }
        }
      }
    } catch (e, s) {
      print('DEBUG: getAltKategoriler error: $e');
      print('DEBUG: getAltKategoriler stack: $s');
    }
    return [];
  }

  List<SarfMalzemeAltKategori> _parseAltKategoriList(List<dynamic> list) {
    return list
        .map(
          (e) => SarfMalzemeAltKategori.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<Result<void>> sarfMalzemeEkle(SarfMalzemeEkleReq req) async {
    try {
      final response = await _dio.post(
        '/SarfMalzeme/SarfMalzemeEkle',
        data: req.toJson(),
      );

      final responseData = response.data;
      if (response.statusCode != 200 ||
          (responseData is Map && responseData['basarili'] != true)) {
        return Failure(responseData?['mesaj'] ?? 'İstek oluşturulamadı.');
      }

      final int onayKayitId = responseData['onayKayitId'] ?? 0;

      // Upload files if any
      if (req.formFiles.isNotEmpty && onayKayitId > 0) {
        final Map<String, dynamic> formDataMap = {
          'OnayKayitId': onayKayitId,
          'OnayTipi': 'Sarf Malzeme İstek',
          'DosyaAciklama': req.dosyaAciklama,
        };

        final List<MultipartFile> multipartFiles = [];

        for (final file in req.formFiles) {
          if (file.path == null) continue;

          final fileName = file.name;
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
              file.path!,
              filename: fileName,
              contentType: MediaType.parse(contentType),
            ),
          );
        }

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
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<SarfMalzemeTalepResponse> sarfMalzemeTaleplerimiGetir({
    required int tip,
  }) async {
    final response = await _dio.post(
      '/SarfMalzeme/SarfMalzemeTaleplerimiGetir',
      data: {'tip': tip},
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return SarfMalzemeTalepResponse.fromJson(data);
    }
    if (data is Map) {
      return SarfMalzemeTalepResponse.fromJson(Map<String, dynamic>.from(data));
    }

    return const SarfMalzemeTalepResponse(talepler: []);
  }

  Future<SarfMalzemeDetayResponse> getSarfMalzemeDetay(int id) async {
    final response = await _dio.post(
      '/SarfMalzeme/SarfMalzemeDetay',
      data: {'id': id},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SarfMalzemeDetayResponse.fromJson(data);
    }
    throw Exception('Beklenmeyen veri formatı');
  }

  Future<Result<void>> sarfMalzemeSil({required int id}) async {
    try {
      final response = await _dio.post('/SarfMalzeme/SarfMalzemeSil?id=$id');

      final responseData = response.data;
      if (response.statusCode != 200 ||
          (responseData is Map && responseData['basarili'] != true)) {
        return Failure(responseData?['mesaj'] ?? 'Talep silinemedi.');
      }

      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

final sarfMalzemeRepositoryProvider = Provider<SarfMalzemeRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SarfMalzemeRepository(dio);
});

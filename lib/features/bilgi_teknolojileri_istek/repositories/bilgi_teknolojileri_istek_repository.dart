import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_talep_models.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_detay_model.dart';

class BilgiTeknolojileriIstekRepository {
  BilgiTeknolojileriIstekRepository(this._dio);

  final Dio _dio;

  Future<List<String>> getHizmetKategorileri(String destekTuru) async {
    final response = await _dio.get('/TeknikDestek/HizmetKategoriDoldur');
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final list = data[destekTuru];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    }

    return const <String>[];
  }

  // Backward compatibility
  Future<List<String>> getBilgiTekHizmetKategorileri() async {
    return getHizmetKategorileri('bilgiTek');
  }

  Future<Result<TalepYonetimResponse>> teknikDestekTaleplerimiGetir({
    required int tip, // 0: Devam eden, 1: Tamamlanan
    required int hizmetTuru,
  }) async {
    try {
      final response = await _dio.post(
        '/TeknikDestek/TeknikDestekTaleplerimiGetir',
        data: '{"tip": $tip, "hizmetTuru": $hizmetTuru}',
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

  Future<Result<TeknikDestekTalepEkleResponse>> teknikDestekTalepEkle(
    TeknikDestekTalepEkleRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/TeknikDestek/TeknikDestekTalepEkle',
        data: request.toJson(),
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        return Success(TeknikDestekTalepEkleResponse.fromJson(response.data));
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

  Future<Result<TeknikDestekDetayResponse>> teknikDestekDetayGetir({
    required int id,
  }) async {
    try {
      final response = await _dio.post(
        '/TeknikDestek/TeknikDestekDetay',
        data: {'id': id},
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        return Success(TeknikDestekDetayResponse.fromJson(response.data));
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

  Future<Result<void>> dosyaYukle({
    required int onayKayitId,
    required String onayTipi,
    required List<(String path, String fileName)> files,
    required String dosyaAciklama,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('OnayKayitId', onayKayitId.toString()));
      formData.fields.add(MapEntry('OnayTipi', onayTipi));
      formData.fields.add(MapEntry('DosyaAciklama', dosyaAciklama));

      for (final (filePath, fileName) in files) {
        formData.files.add(
          MapEntry(
            'FormFile',
            await MultipartFile.fromFile(filePath, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '/Dosya/DosyaYukle',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        return const Success(null);
      }

      return Failure('Dosya yükleme hatası: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(
        e.response?.data?.toString() ?? e.message ?? 'Bağlantı hatası',
      );
      return Failure(e.toString());
    }
  }

  Future<Result<void>> aciklamaYaz({
    required int teknikDestekId,
    required String aciklama,
  }) async {
    try {
      final response = await _dio.post(
        '/TeknikDestek/AciklamaYaz',
        data: {
          'teknikDestekId': teknikDestekId,
          'aciklama': aciklama,
        },
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

  Future<Result<void>> talepKapat({
    required int teknikDestekId,
    required int puan,
    required String aciklama,
  }) async {
    try {
      final response = await _dio.post(
        '/TeknikDestek/TalepKapat',
        data: {
          'teknikDestekId': teknikDestekId,
          'puan': puan,
          'aciklama': aciklama,
        },
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

  Future<Result<void>> deleteTalep({required int id}) async {
    try {
      final response = await _dio.delete(
        '/TeknikDestek/TeknikDestekSil?id=$id',
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
}

final bilgiTeknolojileriIstekRepositoryProvider =
    Provider<BilgiTeknolojileriIstekRepository>((ref) {
      final dio = ref.read(dioProvider);
      return BilgiTeknolojileriIstekRepository(dio);
    });

final bilgiTekHizmetKategorileriProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
      final repo = ref.read(bilgiTeknolojileriIstekRepositoryProvider);
      return repo.getBilgiTekHizmetKategorileri();
    });

// Parametreli provider - destekTuru'ya göre kategorileri çeker
final hizmetKategorileriProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, destekTuru) async {
      final repo = ref.read(bilgiTeknolojileriIstekRepositoryProvider);
      return repo.getHizmetKategorileri(destekTuru);
    });

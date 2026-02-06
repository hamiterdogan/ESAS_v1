import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';
import 'package:esas_v1/features/satin_alma/models/para_birimi.dart';
import 'package:esas_v1/features/satin_alma/models/doviz_kuru.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_detay_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';
import 'package:esas_v1/core/utils/riverpod_extensions.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_talep.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_ekle_req.dart';
import 'package:esas_v1/features/satin_alma/models/odeme_turu.dart';
import 'package:http_parser/http_parser.dart';

class SatinAlmaRepository {
  SatinAlmaRepository(this._dio);

  final Dio _dio;

  Future<Result<void>> satinAlmaEkle(SatinAlmaEkleReq req) async {
    try {
      // Step 1: Create satın alma request - send JSON
      final response = await _dio.post(
        '/SatinAlma/SatinAlmaEkle',
        data: req.toJson(),
      );

      // Check response
      final responseData = response.data;
      if (response.statusCode != 200 ||
          (responseData is Map && responseData['basarili'] != true)) {
        return Failure(responseData?['mesaj'] ?? 'İstek oluşturulamadı.');
      }

      final int onayKayitId = responseData['onayKayitId'] ?? 0;

      // Step 2: Upload files if any (all files in a single request)
      // Endpoint: /Dosya/DosyaYukle
      if (req.formFiles.isNotEmpty && onayKayitId > 0) {
        final Map<String, dynamic> formDataMap = {
          'OnayKayitId': onayKayitId,
          'OnayTipi': 'Satın Alma',
          'DosyaAciklama': req.dosyaAciklama,
        };

        // Birden fazla dosya için FormFile array oluştur
        final List<MultipartFile> multipartFiles = [];

        for (final file in req.formFiles) {
          if (file.path == null) continue;

          final fileName = file.name;

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
              file.path!,
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
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<List<SatinAlmaBina>> fetchBinalar() async {
    final response = await _dio.get('/TalepYonetimi/BinalariGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => SatinAlmaBina.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <SatinAlmaBina>[];
  }

  Future<List<SatinAlmaAnaKategori>> getAnaKategoriler() async {
    final response = await _dio.get('/SatinAlma/SatinAlmaAnaKategorileriGetir');
    final data = response.data;
    if (data != null && data['anaKtKayitlar'] is List) {
      return (data['anaKtKayitlar'] as List)
          .map(
            (e) => SatinAlmaAnaKategori.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return const [];
  }

  Future<List<SatinAlmaAltKategori>> getAltKategoriler(
    int anaKategoriId,
  ) async {
    final response = await _dio.post(
      '/SatinAlma/SatinAlmaAltKategorileriGetir',
      data: {'satinAlmaAnaKategoriId': anaKategoriId},
    );
    final data = response.data;
    if (data != null && data['altKtKayitlar'] is List) {
      return (data['altKtKayitlar'] as List)
          .map(
            (e) => SatinAlmaAltKategori.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return const [];
  }

  Future<List<SatinAlmaOlcuBirim>> getOlcuBirimleri() async {
    final response = await _dio.get('/SatinAlma/OlcuBirimleriGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map(
            (e) => SatinAlmaOlcuBirim.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return const <SatinAlmaOlcuBirim>[];
  }

  Future<List<ParaBirimi>> getParaBirimleri() async {
    final response = await _dio.get('/Finans/ParaBirimleriniGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => ParaBirimi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const <ParaBirimi>[];
  }

  Future<List<OdemeTuru>> getOdemeTurleri() async {
    final response = await _dio.get('/Finans/OdemeTurleriniGetir');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => OdemeTuru.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const <OdemeTuru>[];
  }

  Future<DovizKuru> getDovizKuru(String dovizKodu) async {
    final response = await _dio.post(
      '/Finans/DovizKuruGetir',
      data: {
        'dovizKodu': dovizKodu,
        'DovizKodu': dovizKodu,
        'dovizKuru': dovizKodu,
        'DovizKuru': dovizKodu,
      },
    );
    return DovizKuru.fromAny(response.data, fallbackDovizKodu: dovizKodu);
  }

  Future<void> guncelleMerkezBankasiDovizKurlari() async {
    await _dio.post('/Finans/MerkezBankasiDovizKurlariniGuncelle');
  }

  Future<List<SatinAlmaTalep>> getTalepler({required int tip}) async {
    final response = await _dio.post(
      '/SatinAlma/SatinAlmaTaleplerimiGetir',
      data: {'tip': tip},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SatinAlmaTalepListResponse.fromJson(data).talepler;
    }
    return const <SatinAlmaTalep>[];
  }

  Future<SatinAlmaDetayResponse> getDetay(int id) async {
    final response = await _dio.post(
      '/SatinAlma/SatinAlmaDetay',
      data: {'id': id},
    );

    if (response.data is Map<String, dynamic>) {
      return SatinAlmaDetayResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    }

    throw Exception('Beklenmeyen cevap formatı');
  }

  Future<Result<void>> deleteTalep({required int id}) async {
    try {
      await _dio.delete('/SatinAlma/SatinAlmaSil', queryParameters: {'id': id});
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

final satinAlmaRepositoryProvider = Provider<SatinAlmaRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SatinAlmaRepository(dio);
});

final satinAlmaBinalarProvider =
    FutureProvider.autoDispose<List<SatinAlmaBina>>((ref) async {
      ref.cacheFor(const Duration(minutes: 10)); // Cache for 10 minutes
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.fetchBinalar();
    });

final satinAlmaAnaKategorilerProvider =
    FutureProvider.autoDispose<List<SatinAlmaAnaKategori>>((ref) async {
      ref.cacheFor(const Duration(minutes: 10)); // Cache for 10 minutes
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getAnaKategoriler();
    });

final satinAlmaAltKategorilerProvider = FutureProvider.autoDispose
    .family<List<SatinAlmaAltKategori>, int>((ref, anaKategoriId) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getAltKategoriler(anaKategoriId);
    });

final satinAlmaOlcuBirimleriProvider =
    FutureProvider.autoDispose<List<SatinAlmaOlcuBirim>>((ref) async {
      ref.cacheFor(
        const Duration(minutes: 15),
      ); // Cache for 15 minutes - rarely changes
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getOlcuBirimleri();
    });

final paraBirimlerProvider = FutureProvider.autoDispose<List<ParaBirimi>>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 15)); // Cache for 15 minutes
  final repo = ref.read(satinAlmaRepositoryProvider);
  return repo.getParaBirimleri();
});

final odemeTurleriProvider = FutureProvider.autoDispose<List<OdemeTuru>>((
  ref,
) async {
  ref.cacheFor(const Duration(minutes: 15)); // Cache for 15 minutes
  final repo = ref.read(satinAlmaRepositoryProvider);
  return repo.getOdemeTurleri();
});

final satinAlmaDevamEdenTaleplerProvider =
    FutureProvider.autoDispose<List<SatinAlmaTalep>>((ref) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getTalepler(tip: 0);
    });

final satinAlmaTamamlananTaleplerProvider =
    FutureProvider.autoDispose<List<SatinAlmaTalep>>((ref) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getTalepler(tip: 1);
    });

final satinAlmaDetayProvider = FutureProvider.autoDispose
    .family<SatinAlmaDetayResponse, int>((ref, id) {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getDetay(id);
    });

// Combined provider for parallel loading of detay screen data
final satinAlmaDetayParalelProvider = FutureProvider.autoDispose
    .family<SatinAlmaDetayParalelData, int>((ref, id) async {
      final results = await Future.wait([
        ref.watch(satinAlmaDetayProvider(id).future),
        ref.watch(personelBilgiProvider.future),
        ref.watch(satinAlmaBinalarProvider.future),
      ]);

      return SatinAlmaDetayParalelData(
        detay: results[0] as SatinAlmaDetayResponse,
        personel: results[1] as PersonelBilgiResponse,
        binalar: results[2] as List<SatinAlmaBina>,
      );
    });

class SatinAlmaDetayParalelData {
  final SatinAlmaDetayResponse detay;
  final PersonelBilgiResponse personel;
  final List<SatinAlmaBina> binalar;

  SatinAlmaDetayParalelData({
    required this.detay,
    required this.personel,
    required this.binalar,
  });
}

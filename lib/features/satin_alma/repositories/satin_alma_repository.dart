import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_kategori_models.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_bina.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_olcu_birim.dart';
import 'package:esas_v1/features/satin_alma/models/para_birimi.dart';
import 'package:esas_v1/features/satin_alma/models/doviz_kuru.dart';
import 'package:esas_v1/features/satin_alma/models/satin_alma_talep.dart';

import 'package:esas_v1/features/satin_alma/models/satin_alma_ekle_req.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class SatinAlmaRepository {
  SatinAlmaRepository(this._dio);

  final Dio _dio;

  Future<Result<void>> satinAlmaEkle(SatinAlmaEkleReq req) async {
    try {
      final map = <String, dynamic>{
        'Pesin': req.pesin,
        'SonTeslimTarihi': req.sonTeslimTarihi.toIso8601String(),
        'AliminAmaci': req.aliminAmaci,
        'OdemeSekliId': req.odemeSekliId,
        'WebSitesi': req.webSitesi,
        'SaticiTel': req.saticiTel,
        'OdemeVadesiGun': req.odemeVadesiGun,
        'SaticiFirma': req.saticiFirma,
        'GenelToplam': req.genelToplam,
        'DosyaAciklama': req.dosyaAciklama,
      };

      // BinaId (List mapping)
      if (req.binaIds.isNotEmpty) {
        if (req.binaIds.length == 1) {
          map['BinaId'] = req.binaIds.first;
        } else {
          map['BinaId'] = req.binaIds;
        }
      } else {
        map['BinaId'] = 0;
      }

      // UrunSatir (JSON String of List)
      // The API expects UrunSatir to be a list of objects.
      // In multipart, sending a JSON string for complex objects is common if the backend expects it so.
      // Based on curl 'UrunSatir={...}', it might expect a single string if only one item,
      // or simply the body is bound from JSON.
      // However, usually with multipart, you can't mix JSON body + files easily without custom binding.
      // We will try sending the list serialized as JSON string.
      // If that fails, we might need index notation (UrunSatir[0].prop).
      // But let's stick to the JSON string hypothesis first as it's cleaner to implement.
      // Actually, if I look at the curl again: -F 'UrunSatir={...}'
      // This implies the value of the field `UrunSatir` IS the JSON object string.
      // If we have multiple, we probably send `UrunSatir` field multiple times, OR a JSON array string.
      // Let's send a JSON Array String.
      map['UrunSatir'] = jsonEncode(
        req.urunSatirlar.map((e) => e.toJson()).toList(),
      );

      final formData = FormData.fromMap(map);

      // Add Files
      for (final file in req.formFiles) {
        if (file.path != null) {
          final filename = file.name;
          final validExtensions = [
            'pdf',
            'png',
            'jpg',
            'jpeg',
            'doc',
            'docx',
            'xls',
            'xlsx',
          ];
          final ext = filename.split('.').last.toLowerCase();

          MediaType? contentType;
          if (validExtensions.contains(ext)) {
            if (ext == 'pdf')
              contentType = MediaType('application', 'pdf');
            else if (['png', 'jpg', 'jpeg'].contains(ext))
              contentType = MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
            else if (['doc', 'docx'].contains(ext))
              contentType = MediaType('application', 'msword'); // simplified
            else if (['xls', 'xlsx'].contains(ext))
              contentType = MediaType('application', 'vnd.ms-excel');
          }

          formData.files.add(
            MapEntry(
              'FormFile',
              await MultipartFile.fromFile(
                file.path!,
                filename: filename,
                contentType: contentType,
              ),
            ),
          );
        }
      }

      await _dio.post('/SatinAlma/SatinAlmaEkle', data: formData);
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
}

final satinAlmaRepositoryProvider = Provider<SatinAlmaRepository>((ref) {
  final dio = ref.read(dioProvider);
  return SatinAlmaRepository(dio);
});

final satinAlmaBinalarProvider =
    FutureProvider.autoDispose<List<SatinAlmaBina>>((ref) async {
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.fetchBinalar();
    });

final satinAlmaAnaKategorilerProvider =
    FutureProvider.autoDispose<List<SatinAlmaAnaKategori>>((ref) async {
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
      final repo = ref.read(satinAlmaRepositoryProvider);
      return repo.getOlcuBirimleri();
    });

final paraBirimlerProvider = FutureProvider.autoDispose<List<ParaBirimi>>((
  ref,
) async {
  final repo = ref.read(satinAlmaRepositoryProvider);
  return repo.getParaBirimleri();
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

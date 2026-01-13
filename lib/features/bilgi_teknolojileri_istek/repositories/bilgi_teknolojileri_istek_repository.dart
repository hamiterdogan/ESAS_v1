import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:esas_v1/core/network/dio_provider.dart';

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

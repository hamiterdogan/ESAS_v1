import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/repositories/yiyecek_icecek_repository.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_taleplerimi_getir_models.dart';

import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_istek_detay_model.dart';

final yiyecekIstekDetayProvider = FutureProvider.family<YiyecekIcecekIstekDetayRes, int>((ref, id) async {
  final repo = ref.watch(yiyecekIcecekRepositoryProvider);
  final result = await repo.getYiyecekIstekDetay(id);
  
  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

final yiyecekIcecekRepositoryProvider = Provider<YiyecekIcecekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return YiyecekIcecekRepository(dio: dio);
});

final ikramTurleriProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(yiyecekIcecekRepositoryProvider);
  return repository.getIkramTurleri();
});

final yiyecekIstekDevamEdenTaleplerProvider =
    FutureProvider<List<YiyecekIstekTalep>>((ref) async {
  final repository = ref.watch(yiyecekIcecekRepositoryProvider);
  final res = await repository.getYiyecekIstekTaleplerim(tip: 0);
  return res.talepler;
});

final yiyecekIstekTamamlananTaleplerProvider =
    FutureProvider<List<YiyecekIstekTalep>>((ref) async {
  final repository = ref.watch(yiyecekIcecekRepositoryProvider);
  final res = await repository.getYiyecekIstekTaleplerim(tip: 1);
  return res.talepler;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_istek_detay_model.dart';
import 'package:esas_v1/features/egitim_istek/repositories/egitim_istek_repository.dart';

final egitimIstekDetayProvider =
    FutureProvider.family<EgitimIstekDetayResponse, int>((ref, id) async {
      final repo = ref.watch(egitimIstekRepositoryProvider);
      final result = await repo.egitimIstekDetayGetir(id: id);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

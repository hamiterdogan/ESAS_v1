import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/dokumantasyon_istek/models/dokumantasyon_istek_detay_model.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';

final dokumantasyonIstekDetayProvider =
    FutureProvider.family<DokumantasyonIstekDetayResponse, int>((
      ref,
      id,
    ) async {
      final repo = ref.watch(dokumantasyonIstekRepositoryProvider);
      final result = await repo.dokumantasyonIstekDetayGetir(id: id);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Yükleniyor'),
      };
    });

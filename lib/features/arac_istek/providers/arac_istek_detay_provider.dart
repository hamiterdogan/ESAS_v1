import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/models/arac_istek_detay_model.dart';
import 'package:esas_v1/features/arac_istek/providers/arac_talep_providers.dart';
import 'package:esas_v1/features/arac_istek/repositories/arac_talep_repository.dart';

final aracIstekDetayRepositoryProvider = Provider<AracTalepRepository>((ref) {
  return ref.watch(aracTalepRepositoryProvider);
});

final aracIstekDetayProvider =
    FutureProvider.family<AracIstekDetayResponse, int>((ref, id) async {
      final repo = ref.watch(aracIstekDetayRepositoryProvider);
      final result = await repo.aracIstekDetayGetir(id: id);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

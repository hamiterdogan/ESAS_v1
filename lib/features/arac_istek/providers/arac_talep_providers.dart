import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/repositories/arac_talep_repository.dart';
import 'package:esas_v1/features/arac_istek/models/arac_turu_model.dart';
import 'package:esas_v1/features/arac_istek/models/gidilecek_yer_model.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';

final aracTalepRepositoryProvider = Provider<AracTalepRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AracTalepRepositoryImpl(dio: dio);
});

final aracDevamEdenTaleplerProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(aracTalepRepositoryProvider);
      final result = await repo.aracTaleplerimiGetir(tip: 0);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

final aracTamamlananTaleplerProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(aracTalepRepositoryProvider);
      final result = await repo.aracTaleplerimiGetir(tip: 1);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

final aracTurleriProvider = FutureProvider.autoDispose<List<AracTuru>>((
  ref,
) async {
  final repo = ref.watch(aracTalepRepositoryProvider);
  final result = await repo.aracTurleriGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

final gidilecekYerlerProvider =
    FutureProvider.autoDispose<List<GidilecekYer>>((ref) async {
  final repo = ref.watch(aracTalepRepositoryProvider);
  final result = await repo.gidilecekYerleriGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

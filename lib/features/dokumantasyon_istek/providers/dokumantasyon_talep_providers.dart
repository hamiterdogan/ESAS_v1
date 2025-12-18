import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/dokumantasyon_istek/repositories/dokumantasyon_istek_repository.dart';

final dokumantasyonDevamEdenTaleplerProvider = FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
  final repo = ref.watch(dokumantasyonIstekRepositoryProvider);
  final result = await repo.dokumantasyonTaleplerimiGetir(tip: 0);
  
  return switch (result) {
    Success(data: final data) => data,
    Failure(message: final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor...'),
  };
});

final dokumantasyonTamamlananTaleplerProvider = FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
  final repo = ref.watch(dokumantasyonIstekRepositoryProvider);
  final result = await repo.dokumantasyonTaleplerimiGetir(tip: 1);
  
  return switch (result) {
    Success(data: final data) => data,
    Failure(message: final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor...'),
  };
});

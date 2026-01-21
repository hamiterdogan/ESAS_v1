import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';

const int _teknikDestekHizmetTuru = 1;

final teknikDestekDevamEdenTaleplerProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(bilgiTeknolojileriIstekRepositoryProvider);
      final result = await repo.teknikDestekTaleplerimiGetir(
        tip: 0,
        hizmetTuru: _teknikDestekHizmetTuru,
      );

      return switch (result) {
        Success(data: final data) => data,
        Failure(message: final message) => throw Exception(message),
        Loading() => throw Exception('Yükleniyor...'),
      };
    });

final teknikDestekTamamlananTaleplerProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(bilgiTeknolojileriIstekRepositoryProvider);
      final result = await repo.teknikDestekTaleplerimiGetir(
        tip: 1,
        hizmetTuru: _teknikDestekHizmetTuru,
      );

      return switch (result) {
        Success(data: final data) => data,
        Failure(message: final message) => throw Exception(message),
        Loading() => throw Exception('Yükleniyor...'),
      };
    });

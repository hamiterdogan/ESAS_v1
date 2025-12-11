import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/models/talep_yonetim_models.dart';
import 'package:esas_v1/features/izin_istek/models/izin_talepleri_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_model.dart';
import 'package:esas_v1/features/izin_istek/models/gorev_yeri_model.dart';

final talepYonetimRepositoryProvider = Provider<TalepYonetimRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TalepYonetimRepositoryImpl(dio: dio);
});

// Yeni endpoint: IzinTaleplerimiGetir (parametresiz)
final izinTalepleriProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Onay Bekliyor Talepler (tip: 0)
final onayBekleyenTaleplerProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetirByTip(tip: 0);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Onaylanmış Talepler (tip: 1)
final onaylananTaleplerProvider = FutureProvider<IzinTalepleriResponse>((
  ref,
) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.izinTaleplerimiGetirByTip(tip: 1);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Devam eden talepler (tip: 0) - İsteklerim tabı için
final devamEdenIsteklerimProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(talepYonetimRepositoryProvider);
      final result = await repo.taleplerimiGetir(tip: 0);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Tamamlanan talepler (tip: 1) - İsteklerim tabı için
final tamamlananIsteklerimProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(talepYonetimRepositoryProvider);
      final result = await repo.taleplerimiGetir(tip: 1);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Devam eden talepler (tip: 2) - Gelen Kutusu tabı için
final devamEdenGelenKutusuProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(talepYonetimRepositoryProvider);
      final result = await repo.taleplerimiGetir(tip: 2);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Tamamlanan talepler (tip: 3) - Gelen Kutusu tabı için
final tamamlananGelenKutusuProvider =
    FutureProvider.autoDispose<TalepYonetimResponse>((ref) async {
      final repo = ref.watch(talepYonetimRepositoryProvider);
      final result = await repo.taleplerimiGetir(tip: 3);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Görev listesi provider - GorevDoldur endpoint'i
final gorevlerProvider = FutureProvider.autoDispose<List<Gorev>>((ref) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.gorevleriGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

// Görev Yeri listesi provider - GorevYeriDoldur endpoint'i
final gorevYerleriProvider = FutureProvider<List<GorevYeri>>((ref) async {
  final repo = ref.watch(talepYonetimRepositoryProvider);
  final result = await repo.gorevYerleriniGetir();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Loading'),
  };
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay.dart';
import 'package:esas_v1/features/izin_istek/models/izin_nedeni.dart';
import 'package:esas_v1/features/izin_istek/models/dini_gun_model.dart';
import 'package:esas_v1/features/izin_istek/repositories/izin_istek_repository.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';
import 'package:esas_v1/core/utils/riverpod_extensions.dart';

// Repository provider
final izinIstekRepositoryProvider = Provider<IzinIstekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return IzinIstekRepositoryImpl(dio);
});

// Izin detayi provider
final izinDetayProvider = FutureProvider.autoDispose
    .family<IzinIstekDetay, int>((ref, id) async {
      final repo = ref.watch(izinIstekRepositoryProvider);
      final result = await repo.getIzinDetay(id);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Yukleniyor'),
      };
    });

// Personel secim ekrani icin arama sorgusu - NotifierProvider ile
class PersonelSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final personelSecimSearchQueryProvider =
    NotifierProvider<PersonelSearchNotifier, String>(
      () => PersonelSearchNotifier(),
    );

// Tum personelleri getir (bir kez yukle, cache'le)
final allPersonelProvider = FutureProvider.autoDispose<List<Personel>>((
  ref,
) async {
  // Cache'leme icin cacheFor - 10 dakika boyunca cache'de tut
  ref.cacheFor(const Duration(minutes: 10));
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getPersoneller('');

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yukleniyor'),
  };
});

// Filtrelenmis personel listesi (client-side filtering)
final filteredPersonelProvider = Provider<AsyncValue<List<Personel>>>((ref) {
  final allPersonelAsync = ref.watch(allPersonelProvider);
  final searchQuery = ref.watch(personelSecimSearchQueryProvider);

  return allPersonelAsync.whenData((personeller) {
    if (searchQuery.isEmpty) {
      return personeller;
    }

    final query = searchQuery.toLowerCase();
    return personeller
        .where(
          (p) =>
              p.ad.toLowerCase().contains(query) ||
              p.soyad.toLowerCase().contains(query),
        )
        .toList();
  });
});

// Izin nedenlerini getir (bir kez yukle, cache'le)
final allIzinNedenlerProvider = FutureProvider.autoDispose<List<IzinNedeni>>((
  ref,
) async {
  // Cache'leme icin cacheFor - 10 dakika boyunca cache'de tut
  ref.cacheFor(const Duration(minutes: 10));
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getIzinNedenleri();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yukleniyor'),
  };
});

// Dini gunleri getir (bir kez yukle, cache'le)
final diniGunlerProvider = FutureProvider.autoDispose
    .family<List<DiniGun>, int>((ref, personelId) async {
      final repo = ref.watch(izinIstekRepositoryProvider);
      final result = await repo.getDiniGunler(personelId);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Yukleniyor'),
      };
    });

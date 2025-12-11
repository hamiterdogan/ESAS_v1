import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay.dart';
import 'package:esas_v1/features/izin_istek/models/izin_nedeni.dart';
import 'package:esas_v1/features/izin_istek/models/dini_gun_model.dart';
import 'package:esas_v1/features/izin_istek/repositories/izin_istek_repository.dart';
import 'package:esas_v1/features/personel/models/personel_models.dart';

// Repository provider
final izinIstekRepositoryProvider = Provider<IzinIstekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return IzinIstekRepositoryImpl(dio);
});

// İzin detayı provider
final izinDetayProvider = FutureProvider.family<IzinIstekDetay, int>((
  ref,
  id,
) async {
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getIzinDetay(id);

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor'),
  };
});

// Personel seçim ekranı için arama sorgusu - NotifierProvider ile
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

// Tüm personelleri getir (bir kez yükle, cache'le)
final allPersonelProvider = FutureProvider<List<Personel>>((ref) async {
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getPersoneller('');

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor'),
  };
});

// Filtrelenmiş personel listesi (client-side filtering)
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

// İzin nedenlerini getir (bir kez yükle, cache'le)
final allIzinNedenlerProvider = FutureProvider<List<IzinNedeni>>((ref) async {
  final repo = ref.watch(izinIstekRepositoryProvider);
  final result = await repo.getIzinNedenleri();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor'),
  };
});

// Dini günleri getir (bir kez yükle, cache'le)
final diniGunlerProvider = FutureProvider.autoDispose
    .family<List<DiniGun>, int>((ref, personelId) async {
      final repo = ref.watch(izinIstekRepositoryProvider);
      final result = await repo.getDiniGunler(personelId);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Yükleniyor'),
      };
    });

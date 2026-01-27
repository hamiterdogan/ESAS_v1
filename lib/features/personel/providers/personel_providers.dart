import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/models/result.dart';
import '../repositories/personel_repository.dart';
import '../models/personel_models.dart';
import '../../../core/utils/riverpod_extensions.dart';

// Repository Provider
final personelRepositoryProvider = Provider<PersonelRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PersonelRepositoryImpl(dio);
});

// Personel Listesi Provider
final personellerProvider = FutureProvider.autoDispose<List<Personel>>((
  ref,
) async {
  // Cache'leme için cacheFor - 10 dakika boyunca cache'de tut
  ref.cacheFor(const Duration(minutes: 10));
  final repo = ref.watch(personelRepositoryProvider);
  final result = await repo.getPersoneller();

  return switch (result) {
    Success(:final data) => data,
    Failure(:final message) => throw Exception(message),
    Loading() => throw Exception('Yükleniyor...'),
  };
});

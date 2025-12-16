import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/repositories/talep_yonetim_repository.dart';
import 'package:esas_v1/features/izin_istek/models/izin_istek_detay_model.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/models/onay_durumu_model.dart';

final izinIstekDetayRepositoryProvider = Provider<TalepYonetimRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return TalepYonetimRepositoryImpl(dio: dio);
});
final izinIstekDetayProvider =
    FutureProvider.family<IzinIstekDetayResponse, int>((ref, id) async {
      final repo = ref.watch(izinIstekDetayRepositoryProvider);
      final result = await repo.izinIstekDetayiGetir(id: id);

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Onay durumu getir (onayTipi dinamik)
typedef OnayDurumuArgs = ({int talepId, String onayTipi});

final onayDurumuProvider =
    FutureProvider.family<OnayDurumuResponse, OnayDurumuArgs>((
      ref,
      args,
    ) async {
      final repo = ref.watch(izinIstekDetayRepositoryProvider);
      final result = await repo.onayDurumuGetir(
        talepId: args.talepId,
        onayTipi: args.onayTipi,
      );

      return switch (result) {
        Success(:final data) => data,
        Failure(:final message) => throw Exception(message),
        Loading() => throw Exception('Loading'),
      };
    });

// Personel bilgisi getir
final personelBilgiProvider = FutureProvider<PersonelBilgiResponse>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final personelId = ref.watch(currentPersonelIdProvider);

  try {
    final response = await dio.get(
      '/Personel/PersonelBilgiGetir?personelId=$personelId',
    );
    return PersonelBilgiResponse.fromJson(response.data);
  } catch (e) {
    throw Exception('Personel bilgisi alınamadı: $e');
  }
});

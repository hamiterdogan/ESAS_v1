import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_detay_model.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';
import 'package:esas_v1/features/izin_istek/models/personel_bilgi_model.dart';
import 'package:esas_v1/features/izin_istek/providers/izin_istek_detay_provider.dart';

final teknikDestekDetayProvider = FutureProvider.family
    .autoDispose<TeknikDestekDetayResponse, int>((ref, id) async {
      final repo = ref.watch(bilgiTeknolojileriIstekRepositoryProvider);
      final result = await repo.teknikDestekDetayGetir(id: id);

      return switch (result) {
        Success(data: final data) => data,
        Failure(message: final message) => throw Exception(message),
        Loading() => throw Exception('Yükleniyor...'),
      };
    });

// Combined provider for parallel loading of detay screen data
final teknikDestekDetayParalelProvider = FutureProvider.family
    .autoDispose<TeknikDestekDetayParalelData, int>((ref, id) async {
      final results = await Future.wait([
        ref.watch(teknikDestekDetayProvider(id).future),
        ref.watch(personelBilgiProvider.future),
      ]);

      return TeknikDestekDetayParalelData(
        detay: results[0] as TeknikDestekDetayResponse,
        personel: results[1] as PersonelBilgiResponse,
      );
    });

class TeknikDestekDetayParalelData {
  final TeknikDestekDetayResponse detay;
  final PersonelBilgiResponse personel;

  TeknikDestekDetayParalelData({required this.detay, required this.personel});
}

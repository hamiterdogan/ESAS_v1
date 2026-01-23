import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/models/teknik_destek_detay_model.dart';
import 'package:esas_v1/features/bilgi_teknolojileri_istek/repositories/bilgi_teknolojileri_istek_repository.dart';

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

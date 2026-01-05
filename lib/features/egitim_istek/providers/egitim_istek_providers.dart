import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/features/egitim_istek/models/egitim_talep_item.dart';
import 'package:esas_v1/features/egitim_istek/repositories/egitim_istek_repository.dart';

// Devam Eden Talepler Provider (tip: 0)
final egitimDevamEdenTaleplerProvider =
    FutureProvider.autoDispose<List<EgitimTalepItem>>((ref) async {
      final repository = ref.read(egitimIstekRepositoryProvider);
      return await repository.getTaleplerim(tip: 0);
    });

// Tamamlanan Talepler Provider (tip: 1)
final egitimTamamlananTaleplerProvider =
    FutureProvider.autoDispose<List<EgitimTalepItem>>((ref) async {
      final repository = ref.read(egitimIstekRepositoryProvider);
      return await repository.getTaleplerim(tip: 1);
    });

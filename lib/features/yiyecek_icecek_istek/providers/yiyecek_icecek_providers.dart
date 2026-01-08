import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/repositories/yiyecek_icecek_repository.dart';

final yiyecekIcecekRepositoryProvider = Provider<YiyecekIcecekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return YiyecekIcecekRepository(dio);
});

final ikramTurleriProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(yiyecekIcecekRepositoryProvider);
  return repository.getIkramTurleri();
});

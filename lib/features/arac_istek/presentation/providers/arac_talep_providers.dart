import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/arac_istek/data/datasources/arac_istek_remote_data_source.dart';
import 'package:esas_v1/features/arac_istek/data/repositories/arac_istek_repository_impl.dart';
import 'package:esas_v1/features/arac_istek/domain/repositories/arac_istek_repository.dart';
import 'package:esas_v1/features/arac_istek/domain/usecases/create_arac_talep_usecase.dart';
import 'package:esas_v1/features/arac_istek/presentation/providers/arac_talep_form_notifier.dart';

// Repository Provider
final aracIstekRepositoryProvider = Provider<IAracIstekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = AracIstekRemoteDataSource(dio);
  return AracIstekRepositoryImpl(dataSource);
});

// UseCase Providers
final createAracTalepUseCaseProvider = Provider<CreateAracTalepUseCase>((ref) {
  final repository = ref.watch(aracIstekRepositoryProvider);
  return CreateAracTalepUseCase(repository);
});

// Providers for Data Lists
final aracTurleriProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(aracIstekRepositoryProvider);
  final result = await repository.getAracTurleri();
  return result.when(
    success: (data) => data,
    failure: (message) => throw Exception(message),
  );
});

final gidilecekYerlerProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(aracIstekRepositoryProvider);
  final result = await repository.getGidilecekYerler();
  return result.when(
    success: (data) => data,
    failure: (message) => throw Exception(message),
  );
});

// Form Notifier Provider
final aracTalepFormProvider = StateNotifierProvider.autoDispose<AracTalepFormNotifier, AracTalepFormState>((ref) {
  final createAracTalepUseCase = ref.watch(createAracTalepUseCaseProvider);
  return AracTalepFormNotifier(createAracTalepUseCase);
});

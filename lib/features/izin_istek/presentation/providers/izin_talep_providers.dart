import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/izin_istek/data/datasources/izin_istek_remote_data_source.dart';
import 'package:esas_v1/features/izin_istek/data/repositories/izin_istek_repository_impl.dart';
import 'package:esas_v1/features/izin_istek/domain/repositories/izin_istek_repository.dart';
import 'package:esas_v1/features/izin_istek/domain/usecases/create_izin_talep_usecase.dart';
import 'package:esas_v1/features/izin_istek/presentation/providers/izin_talep_form_notifier.dart';

// Repository
final izinIstekRepositoryProvider = Provider<IIzinIstekRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = IzinIstekRemoteDataSource(dio);
  return IzinIstekRepositoryImpl(dataSource);
});

// UseCase
final createIzinTalepUseCaseProvider = Provider<CreateIzinTalepUseCase>((ref) {
  final repository = ref.watch(izinIstekRepositoryProvider);
  return CreateIzinTalepUseCase(repository);
});

// Providers for Lists
final izinSebepleriProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(izinIstekRepositoryProvider);
  final result = await repository.getIzinSebepleri();
  return result.when(
    success: (data) => data,
    failure: (message) => throw Exception(message),
  );
});

// Form Notifier
final izinTalepFormProvider =
    StateNotifierProvider.autoDispose<
      IzinTalepFormNotifier,
      IzinTalepFormState
    >((ref) {
      final createUseCase = ref.watch(createIzinTalepUseCaseProvider);
      return IzinTalepFormNotifier(createUseCase);
    });

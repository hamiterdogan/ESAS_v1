import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/satin_alma/data/datasources/satin_alma_remote_data_source.dart';
import 'package:esas_v1/features/satin_alma/data/repositories/satin_alma_repository_impl.dart';
import 'package:esas_v1/features/satin_alma/domain/repositories/satin_alma_repository.dart';
import 'package:esas_v1/features/satin_alma/domain/usecases/create_satin_alma_talep_usecase.dart';
import 'package:esas_v1/features/satin_alma/presentation/providers/satin_alma_form_notifier.dart';
import 'package:esas_v1/common/providers/file_attachment_provider.dart';

// Repository
final satinAlmaRepositoryProvider = Provider<ISatinAlmaRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = SatinAlmaRemoteDataSource(dio);
  return SatinAlmaRepositoryImpl(dataSource);
});

// UseCase
final createSatinAlmaTalepUseCaseProvider =
    Provider<CreateSatinAlmaTalepUseCase>((ref) {
      final repository = ref.watch(satinAlmaRepositoryProvider);
      return CreateSatinAlmaTalepUseCase(repository);
    });

// Providers for Lists
final binalarProvider = FutureProvider<List<dynamic>>(
  (ref) async => (await ref.watch(satinAlmaRepositoryProvider).getBinalar())
      .when(success: (d) => d, failure: (e) => throw e),
);
final anaKategorilerProvider = FutureProvider<List<dynamic>>(
  (ref) async =>
      (await ref.watch(satinAlmaRepositoryProvider).getAnaKategoriler()).when(
        success: (d) => d,
        failure: (e) => throw e,
      ),
);
final altKategorilerProvider = FutureProvider.family<List<dynamic>, int>(
  (ref, id) async =>
      (await ref.watch(satinAlmaRepositoryProvider).getAltKategoriler(id)).when(
        success: (d) => d,
        failure: (e) => throw e,
      ),
);
final birimlerProvider = FutureProvider<List<dynamic>>(
  (ref) async => (await ref.watch(satinAlmaRepositoryProvider).getBirimler())
      .when(success: (d) => d, failure: (e) => throw e),
);
final paraBirimleriProvider = FutureProvider<List<dynamic>>(
  (ref) async =>
      (await ref.watch(satinAlmaRepositoryProvider).getParaBirimleri()).when(
        success: (d) => d,
        failure: (e) => throw e,
      ),
);
final odemeSekilleriProvider = FutureProvider<List<dynamic>>(
  (ref) async =>
      (await ref.watch(satinAlmaRepositoryProvider).getOdemeSekilleri()).when(
        success: (d) => d,
        failure: (e) => throw e,
      ),
);

// File Attachment Provider for Satin Alma - Riverpod 3 pattern
// Uses the shared fileAttachmentProvider
final satinAlmaFileProvider = fileAttachmentProvider;

// Form Notifier - Riverpod 3 pattern
final satinAlmaFormProvider =
    NotifierProvider<SatinAlmaFormNotifier, SatinAlmaFormState>(
      SatinAlmaFormNotifier.new,
    );

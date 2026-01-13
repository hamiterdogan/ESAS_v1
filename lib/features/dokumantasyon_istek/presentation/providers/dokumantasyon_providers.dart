import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/features/dokumantasyon_istek/data/datasources/dokumantasyon_remote_data_source.dart';
import 'package:esas_v1/features/dokumantasyon_istek/data/repositories/dokumantasyon_repository_impl.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/repositories/dokumantasyon_repository.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/usecases/create_dokumantasyon_talep_usecase.dart';
import 'package:esas_v1/features/dokumantasyon_istek/presentation/providers/dokumantasyon_form_notifier.dart';
import 'package:esas_v1/common/providers/file_attachment_provider.dart';

final dokumantasyonRepositoryProvider = Provider<IDokumantasyonRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  final ds = DokumantasyonRemoteDataSource(dio);
  return DokumantasyonRepositoryImpl(ds);
});

final createDokumantasyonUseCaseProvider =
    Provider<CreateDokumantasyonTalepUseCase>((ref) {
      return CreateDokumantasyonTalepUseCase(
        ref.watch(dokumantasyonRepositoryProvider),
      );
    });

final dokumanTurleriProvider = FutureProvider<List<dynamic>>(
  (ref) async =>
      (await ref.watch(dokumantasyonRepositoryProvider).getDokumanTurleri())
          .when(success: (d) => d, failure: (e) => throw e),
);

// File Attachment Provider - Riverpod 3 pattern
// Uses the shared fileAttachmentProvider
final dokumantasyonFileProvider = fileAttachmentProvider;

// Form Notifier - Riverpod 3 pattern
final dokumantasyonFormProvider =
    NotifierProvider<DokumantasyonFormNotifier, DokumantasyonFormState>(
      DokumantasyonFormNotifier.new,
    );

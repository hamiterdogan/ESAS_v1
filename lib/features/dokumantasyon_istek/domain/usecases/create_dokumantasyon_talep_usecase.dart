import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/entities/dokumantasyon_talep.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/repositories/dokumantasyon_repository.dart';

class CreateDokumantasyonTalepUseCase {
  final IDokumantasyonRepository _repository;

  CreateDokumantasyonTalepUseCase(this._repository);

  Future<Result<void>> call(DokumantasyonTalep talep) {
    return _repository.createDokumantasyonTalep(talep);
  }
}

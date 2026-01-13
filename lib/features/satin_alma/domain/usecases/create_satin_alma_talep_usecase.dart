import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/domain/entities/satin_alma_talep_entity.dart';
import 'package:esas_v1/features/satin_alma/domain/repositories/satin_alma_repository.dart';

class CreateSatinAlmaTalepUseCase {
  final ISatinAlmaRepository _repository;

  CreateSatinAlmaTalepUseCase(this._repository);

  Future<Result<void>> call(SatinAlmaTalep talep) {
    return _repository.createSatinAlmaTalep(talep);
  }
}

import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';
import 'package:esas_v1/features/arac_istek/domain/repositories/arac_istek_repository.dart';

class CreateAracTalepUseCase {
  final IAracIstekRepository _repository;

  CreateAracTalepUseCase(this._repository);

  Future<Result<void>> call(AracTalep talep) async {
    return _repository.createAracTalep(talep);
  }
}

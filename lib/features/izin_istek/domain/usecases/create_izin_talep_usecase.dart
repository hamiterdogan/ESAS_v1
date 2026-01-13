import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/domain/entities/izin_talep.dart';
import 'package:esas_v1/features/izin_istek/domain/repositories/izin_istek_repository.dart';

class CreateIzinTalepUseCase {
  final IIzinIstekRepository _repository;

  CreateIzinTalepUseCase(this._repository);

  Future<Result<void>> call(IzinTalep talep) async {
    return _repository.createIzinTalep(talep);
  }
}

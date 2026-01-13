import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/dokumantasyon_istek/data/datasources/dokumantasyon_remote_data_source.dart';
import 'package:esas_v1/features/dokumantasyon_istek/data/models/dokumantasyon_talep_model.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/entities/dokumantasyon_talep.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/repositories/dokumantasyon_repository.dart';

class DokumantasyonRepositoryImpl implements IDokumantasyonRepository {
  final IDokumantasyonRemoteDataSource _dataSource;

  DokumantasyonRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> createDokumantasyonTalep(
    DokumantasyonTalep talep,
  ) async {
    try {
      final model = DokumantasyonTalepModel.fromEntity(talep);
      await _dataSource.createDokumantasyonTalep(model);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getDokumanTurleri() async {
    try {
      final res = await _dataSource.getDokumanTurleri();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

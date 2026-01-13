import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/data/datasources/arac_istek_remote_data_source.dart';
import 'package:esas_v1/features/arac_istek/data/models/arac_talep_model.dart';
import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';
import 'package:esas_v1/features/arac_istek/domain/repositories/arac_istek_repository.dart';

class AracIstekRepositoryImpl implements IAracIstekRepository {
  final IAracIstekRemoteDataSource _dataSource;

  AracIstekRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> createAracTalep(AracTalep talep) async {
    try {
      final model = AracTalepModel.fromEntity(talep);
      await _dataSource.createAracTalep(model);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getAracTurleri() async {
    try {
      final result = await _dataSource.getAracTurleri();
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getGidilecekYerler() async {
    try {
      final result = await _dataSource.getGidilecekYerler();
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<dynamic>> getAracTalepleri({required int tip}) async {
    try {
      final result = await _dataSource.getAracTalepleri(tip: tip);
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

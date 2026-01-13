import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/data/datasources/satin_alma_remote_data_source.dart';
import 'package:esas_v1/features/satin_alma/data/models/satin_alma_talep_model.dart';
import 'package:esas_v1/features/satin_alma/domain/entities/satin_alma_talep_entity.dart';
import 'package:esas_v1/features/satin_alma/domain/repositories/satin_alma_repository.dart';

class SatinAlmaRepositoryImpl implements ISatinAlmaRepository {
  final ISatinAlmaRemoteDataSource _dataSource;

  SatinAlmaRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> createSatinAlmaTalep(SatinAlmaTalep talep) async {
    try {
      final model = SatinAlmaTalepModel.fromEntity(talep);
      await _dataSource.createSatinAlmaTalep(model);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getBinalar() async {
    try {
      final res = await _dataSource.getBinalar();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getAnaKategoriler() async {
    try {
      final res = await _dataSource.getAnaKategoriler();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getAltKategoriler(int anaKategoriId) async {
    try {
      final res = await _dataSource.getAltKategoriler(anaKategoriId);
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getBirimler() async {
    try {
      final res = await _dataSource.getBirimler();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getParaBirimleri() async {
    try {
      final res = await _dataSource.getParaBirimleri();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getOdemeSekilleri() async {
    try {
      final res = await _dataSource.getOdemeSekilleri();
      return Result.success(res);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

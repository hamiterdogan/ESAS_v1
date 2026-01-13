import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/data/datasources/izin_istek_remote_data_source.dart';
import 'package:esas_v1/features/izin_istek/data/models/izin_talep_model.dart';
import 'package:esas_v1/features/izin_istek/domain/entities/izin_talep.dart';
import 'package:esas_v1/features/izin_istek/domain/repositories/izin_istek_repository.dart';

class IzinIstekRepositoryImpl implements IIzinIstekRepository {
  final IIzinIstekRemoteDataSource _dataSource;

  IzinIstekRepositoryImpl(this._dataSource);

  @override
  Future<Result<void>> createIzinTalep(IzinTalep talep) async {
    try {
      final model = IzinTalepModel.fromEntity(talep);
      await _dataSource.createIzinTalep(model);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getIzinSebepleri() async {
    try {
      final result = await _dataSource.getIzinSebepleri();
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<List<dynamic>>> getPersoneller() async {
    try {
      final result = await _dataSource.getPersoneller();
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<dynamic>> getHesaplananIzinSuresi({
    required int izinSebebiId,
    required DateTime baslangic,
    required DateTime bitis,
  }) async {
    try {
      final result = await _dataSource.getHesaplananIzinSuresi(
        izinSebebiId: izinSebebiId,
        baslangic: baslangic,
        bitis: bitis,
      );
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}

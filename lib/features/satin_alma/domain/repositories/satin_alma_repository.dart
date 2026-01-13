import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/satin_alma/domain/entities/satin_alma_talep_entity.dart';

abstract class ISatinAlmaRepository {
  Future<Result<void>> createSatinAlmaTalep(SatinAlmaTalep talep);
  Future<Result<List<dynamic>>> getBinalar();
  Future<Result<List<dynamic>>> getAnaKategoriler();
  Future<Result<List<dynamic>>> getAltKategoriler(int anaKategoriId);
  Future<Result<List<dynamic>>> getBirimler();
  Future<Result<List<dynamic>>> getParaBirimleri();
  Future<Result<List<dynamic>>> getOdemeSekilleri();
}

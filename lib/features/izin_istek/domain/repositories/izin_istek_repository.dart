import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/izin_istek/domain/entities/izin_talep.dart';

abstract class IIzinIstekRepository {
  Future<Result<void>> createIzinTalep(IzinTalep talep);
  Future<Result<List<dynamic>>> getIzinSebepleri(); // Simplification
  Future<Result<List<dynamic>>> getPersoneller();
  Future<Result<dynamic>> getHesaplananIzinSuresi({
    required int izinSebebiId, 
    required DateTime baslangic, 
    required DateTime bitis
  });
}

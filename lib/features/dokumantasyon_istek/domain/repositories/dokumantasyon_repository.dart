import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/entities/dokumantasyon_talep.dart';

abstract class IDokumantasyonRepository {
  Future<Result<void>> createDokumantasyonTalep(DokumantasyonTalep talep);
  // Add gets if needed (e.g. Kagıt Turleri, Dokuman Turleri)
  Future<Result<List<dynamic>>> getDokumanTurleri();
}

import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';

abstract class IAracIstekRepository {

  Future<Result<void>> createAracTalep(AracTalep talep);
  Future<Result<List<dynamic>>> getAracTurleri(); // Using dynamic for now, should be Entity
  Future<Result<List<dynamic>>> getGidilecekYerler(); // Using dynamic for now, should be Entity
  Future<Result<dynamic>> getAracTalepleri({required int tip}); // Using dynamic for now
}


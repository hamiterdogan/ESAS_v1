import 'package:dio/dio.dart';
import '../../../core/repositories/base_repository.dart';
import '../../../core/models/result.dart';
import '../../../core/utils/app_logger.dart';
import '../models/personel_models.dart';

abstract class PersonelRepository {
  Future<Result<List<Personel>>> getPersoneller();
}

class PersonelRepositoryImpl extends BaseRepository
    implements PersonelRepository {
  final Dio _dio;
  static const _tag = 'PersonelRepository';

  PersonelRepositoryImpl(this._dio);

  @override
  Future<Result<List<Personel>>> getPersoneller() async {
    try {
      AppLogger.api(
        'Fetching personel',
        url: '/Personel/PersonelleriGetir',
        method: 'GET',
      );
      final response = await _dio.get('/Personel/PersonelleriGetir');
      AppLogger.api('Response received', statusCode: response.statusCode);

      return handleResponse(response, (data) {
        if (data is List) {
          AppLogger.debug('Personel count: ${data.length}', tag: _tag);
          final personeller = data.map((item) {
            try {
              return Personel.fromJson(item as Map<String, dynamic>);
            } catch (e, stack) {
              AppLogger.error(
                'Error parsing personel',
                tag: _tag,
                error: e,
                stackTrace: stack,
              );
              rethrow;
            }
          }).toList();
          AppLogger.info(
            'Successfully parsed ${personeller.length} personel',
            tag: _tag,
          );
          return personeller;
        } else {
          throw Exception('Expected List but got ${data.runtimeType}');
        }
      });
    } on DioException catch (e) {
      AppLogger.error('Dio Error: ${e.message}', tag: _tag, error: e);
      return handleError(e);
    } catch (e, stack) {
      AppLogger.error(
        'Unexpected error',
        tag: _tag,
        error: e,
        stackTrace: stack,
      );
      return Failure('Unexpected error: $e');
    }
  }
}

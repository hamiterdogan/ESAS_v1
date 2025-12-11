import 'package:dio/dio.dart';
import '../../../core/repositories/base_repository.dart';
import '../../../core/models/result.dart';
import '../models/personel_models.dart';

abstract class PersonelRepository {
  Future<Result<List<Personel>>> getPersoneller();
}

class PersonelRepositoryImpl extends BaseRepository
    implements PersonelRepository {
  final Dio _dio;

  PersonelRepositoryImpl(this._dio);

  @override
  Future<Result<List<Personel>>> getPersoneller() async {
    try {
      print('🔍 Fetching personel from: /Personel/PersonelleriGetir');
      final response = await _dio.get('/Personel/PersonelleriGetir');
      print('✅ Response status: ${response.statusCode}');
      print('📦 Response data type: ${response.data.runtimeType}');

      return handleResponse(response, (data) {
        if (data is List) {
          print('📋 Personel count: ${data.length}');
          final personeller = data.map((item) {
            try {
              return Personel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              print('❌ Error parsing personel: $e');
              print('🔍 Item data: $item');
              rethrow;
            }
          }).toList();
          print('✅ Successfully parsed ${personeller.length} personel');
          return personeller;
        } else {
          throw Exception('Expected List but got ${data.runtimeType}');
        }
      });
    } on DioException catch (e) {
      print('❌ Dio Error: ${e.message}');
      print('🔍 Error type: ${e.type}');
      return handleError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return Failure('Unexpected error: $e');
    }
  }
}

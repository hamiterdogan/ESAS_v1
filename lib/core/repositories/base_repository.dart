import 'package:dio/dio.dart';
import '../models/result.dart';

abstract class BaseRepository {
  Result<T> handleResponse<T>(
    Response response,
    T Function(dynamic data) fromJson,
  ) {
    try {
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = fromJson(response.data);
        return Success(data);
      } else {
        return Failure(
          'Request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return Failure('Error parsing response: $e');
    }
  }

  Result<T> handleError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const Failure('Connection timeout');
      case DioExceptionType.sendTimeout:
        return const Failure('Send timeout');
      case DioExceptionType.receiveTimeout:
        return const Failure('Receive timeout');
      case DioExceptionType.badResponse:
        return Failure(
          'Server error: ${error.response?.statusMessage ?? 'Unknown error'}',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const Failure('Request cancelled');
      case DioExceptionType.connectionError:
        return const Failure('No internet connection');
      default:
        return Failure('Unexpected error: ${error.message}');
    }
  }
}

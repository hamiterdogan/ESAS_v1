import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

/// API çağrıları için stabilize edilmiş wrapper.
///
/// Bu class:
/// - Retry mekanizması sağlar (3 deneme)
/// - Tutarlı error mapping yapar
/// - Timeout'ları yönetir
/// - Debug logging yapar
///
/// ⚠️ NOT: Bu bir geçici stabilizasyon katmanıdır.
/// Gelecekte proper repository pattern ile değiştirilecek.
class ApiStabilizer {
  final Dio _dio;

  /// Varsayılan retry sayısı
  static const int _maxRetries = 3;

  /// Retry'lar arası bekleme süresi (ms)
  static const int _retryDelayMs = 1000;

  ApiStabilizer(this._dio);

  /// GET isteği yapar - retry mekanizmalı
  ///
  /// [endpoint] API endpoint (örn: '/EgitimIstek/EgitimAdlariDoldur')
  /// [retries] Maksimum deneme sayısı (varsayılan: 3)
  ///
  /// Returns: Response data veya null (hata durumunda)
  Future<dynamic> get(
    String endpoint, {
    int retries = _maxRetries,
    Map<String, dynamic>? queryParameters,
  }) async {
    int attempt = 0;

    while (attempt < retries) {
      try {
        final response = await _dio.get(
          endpoint,
          queryParameters: queryParameters,
        );

        if (response.statusCode == 200) {
          return response.data;
        }

        _logWarning(
          'GET $endpoint - Unexpected status: ${response.statusCode}',
        );
        return null;
      } on DioException catch (e) {
        attempt++;

        if (_shouldRetry(e) && attempt < retries) {
          _logInfo('GET $endpoint - Retry $attempt/$retries');
          await Future.delayed(Duration(milliseconds: _retryDelayMs * attempt));
          continue;
        }

        _logError('GET $endpoint', e);
        return null;
      }
    }

    return null;
  }

  /// POST isteği yapar - retry mekanizmalı
  Future<dynamic> post(
    String endpoint, {
    dynamic data,
    int retries = _maxRetries,
  }) async {
    int attempt = 0;

    while (attempt < retries) {
      try {
        final response = await _dio.post(endpoint, data: data);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        }

        _logWarning(
          'POST $endpoint - Unexpected status: ${response.statusCode}',
        );
        return null;
      } on DioException catch (e) {
        attempt++;

        // POST için sadece network hataları için retry yap
        // (duplicate submission riski var)
        if (_isNetworkError(e) && attempt < retries) {
          _logInfo('POST $endpoint - Retry $attempt/$retries (network error)');
          await Future.delayed(Duration(milliseconds: _retryDelayMs * attempt));
          continue;
        }

        _logError('POST $endpoint', e);
        return null;
      }
    }

    return null;
  }

  /// Hatanın retry yapılabilir olup olmadığını kontrol eder
  bool _shouldRetry(DioException e) {
    return _isNetworkError(e) || _isTimeout(e) || _isServerError(e);
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  bool _isTimeout(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  bool _isServerError(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    return statusCode >= 500 && statusCode < 600;
  }

  /// API hatasını kullanıcı dostu mesaja çevirir
  static String getErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';

      case DioExceptionType.connectionError:
        return 'İnternet bağlantınızı kontrol edin.';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        if (statusCode == 401) {
          return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
        } else if (statusCode == 403) {
          return 'Bu işlem için yetkiniz bulunmamaktadır.';
        } else if (statusCode == 404) {
          return 'İstenen kaynak bulunamadı.';
        } else if (statusCode >= 500) {
          return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
        }
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';

      default:
        return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  void _logInfo(String message) {
    if (kDebugMode) {
      print('📡 [ApiStabilizer] $message');
    }
  }

  void _logWarning(String message) {
    if (kDebugMode) {
      print('⚠️ [ApiStabilizer] $message');
    }
  }

  void _logError(String endpoint, DioException e) {
    if (kDebugMode) {
      print('❌ [ApiStabilizer] $endpoint failed: ${e.type} - ${e.message}');
    }
  }
}

/// API Stabilizer provider
///
/// Kullanım:
/// ```dart
/// final stabilizer = ref.read(apiStabilizerProvider);
/// final data = await stabilizer.get('/EgitimIstek/EgitimAdlariDoldur');
/// ```
final apiStabilizerProvider = Provider<ApiStabilizer>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiStabilizer(dio);
});

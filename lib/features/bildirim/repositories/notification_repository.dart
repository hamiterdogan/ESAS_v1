import 'package:dio/dio.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/repositories/base_repository.dart';
import 'package:esas_v1/features/bildirim/models/notification_model.dart';

/// Bildirim repository - API iletişimi
abstract class NotificationRepository {
  Future<Result<TokenKaydetResponse>> tokenKaydet({
    required String fcmToken,
    required String platform,
    required String deviceId,
    required String deviceBrand,
    required String deviceModel,
    required String osVersion,
  });

  Future<Result<BildirimListResponse>> bildirimListesiGetir({
    bool sadeceOkunmayan = false,
    int take = 40,
    int pageIndex = 0,
    int pageSize = 40,
  });

  Future<Result<int>> okunmamisSayisiGetir();

  Future<Result<bool>> okunduIsaretle({required int bildirimId});

  Future<Result<bool>> tumunuOkunduIsaretle();

  Future<Result<BildirimAksiyonResponse>> bildirimAksiyon({
    required int bildirimId,
    required int onayKayitId,
    required String onayTipi,
    required String aksiyon, // "onayla" veya "reddet"
  });

  /// Cihazın FCM token kaydını backend'den siler (logout).
  Future<Result<bool>> tokenSil({required String deviceId});
}

class NotificationRepositoryImpl extends BaseRepository
    implements NotificationRepository {
  final Dio _dio;

  NotificationRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<TokenKaydetResponse>> tokenKaydet({
    required String fcmToken,
    required String platform,
    required String deviceId,
    required String deviceBrand,
    required String deviceModel,
    required String osVersion,
  }) async {
    try {
      final response = await _dio.post(
        '/Notification/RegisterToken',
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
          'deviceId': deviceId,
          'deviceBrand': deviceBrand,
          'deviceModel': deviceModel,
          'osVersion': osVersion,
        },
      );
      return handleResponse(
        response,
        (data) => TokenKaydetResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  @override
  Future<Result<BildirimListResponse>> bildirimListesiGetir({
    bool sadeceOkunmayan = false,
    int take = 40,
    int pageIndex = 0,
    int pageSize = 40,
  }) async {
    try {
      final effectiveTake = take > 0 ? take : pageSize;
      final response = await _dio.get(
        '/Notification/BildirimListele',
        queryParameters: {
          'sadeceOkunmayan': sadeceOkunmayan,
          'take': effectiveTake,
        },
      );
      return handleResponse(
        response,
        (data) => BildirimListResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  @override
  Future<Result<int>> okunmamisSayisiGetir() async {
    try {
      final response = await _dio.get('/Notification/OkunmayanBildirimSayisi');
      return handleResponse(response, _parseUnreadCount);
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  int _parseUnreadCount(dynamic data) {
    if (data is int) return data;
    if (data is num) return data.toInt();
    if (data is String) return int.tryParse(data) ?? 0;

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'] ?? data['Data'];
      if (nestedData is int) return nestedData;
      if (nestedData is num) return nestedData.toInt();
      if (nestedData is String) return int.tryParse(nestedData) ?? 0;

      final count =
          data['okunmayanBildirimSayisi'] ??
          data['okunmamisSayisi'] ??
          data['count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      if (count is String) return int.tryParse(count) ?? 0;
    }

    return 0;
  }

  @override
  Future<Result<bool>> okunduIsaretle({required int bildirimId}) async {
    try {
      final response = await _dio.post(
        '/Notification/OkunduIsaretle',
        data: {
          'bildirimId': [bildirimId],
          'tumunuIsaretle': false,
        },
      );
      return handleResponse(response, (data) => true);
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  @override
  Future<Result<bool>> tumunuOkunduIsaretle() async {
    try {
      final response = await _dio.post(
        '/Notification/OkunduIsaretle',
        data: {
          'bildirimId': [0],
          'tumunuIsaretle': true,
        },
      );
      return handleResponse(response, (data) => true);
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  @override
  Future<Result<BildirimAksiyonResponse>> bildirimAksiyon({
    required int bildirimId,
    required int onayKayitId,
    required String onayTipi,
    required String aksiyon,
  }) async {
    try {
      final response = await _dio.post(
        '/Bildirim/BildirimAksiyon',
        data: {
          'bildirimId': bildirimId,
          'onayKayitId': onayKayitId,
          'onayTipi': onayTipi,
          'aksiyon': aksiyon,
        },
      );
      return handleResponse(
        response,
        (data) =>
            BildirimAksiyonResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    }
  }

  @override
  Future<Result<bool>> tokenSil({required String deviceId}) async {
    try {
      final response = await _dio.post(
        '/Notification/UnregisterToken',
        data: {'deviceId': deviceId},
      );
      return handleResponse(response, (_) => true);
    } on DioException catch (e) {
      return handleError(e);
    }
  }
}

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bildirim/repositories/notification_repository.dart';

/// Cihaz kayıt servisi
///
/// Uygulama ilk açıldığında (veya token yenilendiğinde) cihazı
/// `/Notification/RegisterToken` endpoint'ine kaydeder.
/// Kayıt başarılıysa SharedPreferences'e işaret bırakır; sonraki açılışlarda
/// tekrar kayıt yapmaz.
class DeviceRegistrationService {
  static final DeviceRegistrationService _instance =
      DeviceRegistrationService._internal();
  factory DeviceRegistrationService() => _instance;
  DeviceRegistrationService._internal();

  static const String _registeredTokenKey = 'device_registered_fcm_token';
  static const String _deviceIdKey = 'device_unique_id';

  /// Cihazı kaydet.
  ///
  /// [fcmToken] zaten kaydedilmişse (SharedPreferences'de aynı token varsa)
  /// API çağrısı yapılmaz. [forceRefresh] true ise kayıt durumuna bakılmaksızın
  /// her zaman API'ye gönderilir.
  Future<bool> registerDevice({
    required String fcmToken,
    required NotificationRepository repo,
    bool forceRefresh = false,
  }) async {
    // Daha önce aynı token ile kayıt yapıldıysa atla
    if (!forceRefresh) {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_registeredTokenKey);
      if (savedToken == fcmToken) {
        if (kDebugMode) {
          print('📱 Cihaz daha önce kaydedilmiş, atlanıyor.');
        }
        return true;
      }
    }

    // Cihaz bilgilerini topla
    final info = await _collectDeviceInfo();

    if (kDebugMode) {
      print('📲 Cihaz kaydı başlatılıyor...');
      print('   platform   : ${info.platform}');
      print('   deviceId   : ${info.deviceId}');
      print('   deviceBrand: ${info.deviceBrand}');
      print('   deviceModel: ${info.deviceModel}');
      print('   osVersion  : ${info.osVersion}');
    }

    final result = await repo.tokenKaydet(
      fcmToken: fcmToken,
      platform: info.platform,
      deviceId: info.deviceId,
      deviceBrand: info.deviceBrand,
      deviceModel: info.deviceModel,
      osVersion: info.osVersion,
    );

    switch (result) {
      case Success():
        // Başarılı → token'ı kaydet, bir daha sorma
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_registeredTokenKey, fcmToken);
        if (kDebugMode) {
          print('✅ Cihaz başarıyla kaydedildi.');
        }
        return true;
      case Failure(:final message):
        if (kDebugMode) {
          print('❌ Cihaz kaydı başarısız: $message');
        }
        return false;
      case Loading():
        return false;
    }
  }

  /// Token yenilendiğinde mevcut kaydı sıfırla (bir sonraki açılışta yeniden kayıt yapılacak).
  Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registeredTokenKey);
  }

  /// Cihazın kalıcı benzersiz kimliğini döndürür.
  /// İlk çağrıda UUID v4 üretilir ve SharedPreferences'e kaydedilir.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final newId = const Uuid().v4();
    await prefs.setString(_deviceIdKey, newId);
    if (kDebugMode) print('📱 Yeni DeviceId üretildi: $newId');
    return newId;
  }

  // ---------------------------------------------------------------------------
  // Cihaz bilgilerini platform bazlı topla
  // ---------------------------------------------------------------------------

  Future<_DeviceInfo> _collectDeviceInfo() async {
    final plugin = DeviceInfoPlugin();

    // Tüm platformlarda bizim ürettiğimiz UUID kullanılır.
    // Platform native ID'ler (android.id, identifierForVendor) kullanılmaz.
    final deviceId = await getDeviceId();

    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      return _DeviceInfo(
        platform: 'android',
        deviceId: deviceId,
        deviceBrand: android.brand,
        deviceModel: android.model,
        osVersion:
            'Android ${android.version.release} (SDK ${android.version.sdkInt})',
      );
    } else if (Platform.isIOS) {
      final ios = await plugin.iosInfo;
      return _DeviceInfo(
        platform: 'iOS',
        deviceId: deviceId,
        deviceBrand: 'Apple',
        deviceModel: ios.utsname.machine,
        osVersion: 'iOS ${ios.systemVersion}',
      );
    } else {
      // Web / masaüstü – zorunlu alan, varsayılan değer gönder
      return _DeviceInfo(
        platform: 'other',
        deviceId: deviceId,
        deviceBrand: 'unknown',
        deviceModel: 'unknown',
        osVersion: 'unknown',
      );
    }
  }
}

class _DeviceInfo {
  final String platform;
  final String deviceId;
  final String deviceBrand;
  final String deviceModel;
  final String osVersion;

  const _DeviceInfo({
    required this.platform,
    required this.deviceId,
    required this.deviceBrand,
    required this.deviceModel,
    required this.osVersion,
  });
}

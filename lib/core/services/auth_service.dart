import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:esas_v1/core/routing/router.dart';
import 'package:esas_v1/core/services/auth_storage_service.dart';
import 'package:esas_v1/core/services/device_registration_service.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';

/// Merkezi oturum yönetimi servisi.
///
/// Logout akışı:
/// 1. Backend'e UnregisterToken (best-effort)
/// 2. Firebase FCM token'ını tamamen yok et (deleteToken)
/// 3. Local kayıtları temizle
/// 4. Riverpod state'lerini sıfırla
/// 5. Login ekranına yönlendir
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Tam logout: FCM deregistration + local temizlik + yönlendirme.
  ///
  /// [ref] Riverpod ref'i (provider invalidation için)
  Future<void> logout(WidgetRef ref) async {
    try {
      // 1. Backend'e UnregisterToken (best-effort — hata olursa devam et)
      await _unregisterFromBackend(ref);
    } catch (e) {
      if (kDebugMode)
        print('⚠️ Backend UnregisterToken hatası (devam ediliyor): $e');
    }

    try {
      // 2. Firebase FCM token'ını tamamen yok et
      await FirebaseMessaging.instance.deleteToken();
      if (kDebugMode) print('🗑️ FCM token Firebase\'den silindi.');
    } catch (e) {
      if (kDebugMode) print('⚠️ FCM deleteToken hatası (devam ediliyor): $e');
    }

    // 3. Local FCM kayıt işaretini temizle (sonraki login'de yeniden register olsun)
    await DeviceRegistrationService().clearRegistration();

    // 4. AuthStorage'ı temizle (token - SecureStorage + kullanıcı verileri - SP)
    await AuthStorageService().clear();

    // 5. Riverpod token'ını sıfırla (Dio header'dan Bearer kaldırılır)
    ref.read(tokenProvider.notifier).setToken('');
    ref.read(authErrorProvider.notifier).setError(false);
    authStateNotifier.value = false;

    // 6. İlgili provider'ları invalidate et (UI cache'leri temizle)
    ref.invalidate(dioProvider);
    ref.invalidate(notificationRepositoryProvider);
    ref.invalidate(okunmamisBildirimSayisiProvider);
    ref.invalidate(bildirimListProvider);

    if (kDebugMode) print('✅ Logout tamamlandı.');

    // 7. Login ekranına yönlendir
    appRouter.go('/login');
  }

  /// Tam logout (401 handler gibi noktalarda WidgetRef ile kullanılır).
  Future<void> logoutWithoutRef(WidgetRef ref) async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      if (kDebugMode) print('🗑️ FCM token Firebase\'den silindi.');
    } catch (e) {
      if (kDebugMode) print('⚠️ FCM deleteToken hatası: $e');
    }

    await DeviceRegistrationService().clearRegistration();
    await AuthStorageService().clear();

    // Riverpod auth state mutlaka sıfırlanır
    ref.read(tokenProvider.notifier).setToken('');
    ref.read(authErrorProvider.notifier).setError(false);
    authStateNotifier.value = false;
    ref.invalidate(dioProvider);
    ref.invalidate(notificationRepositoryProvider);
    ref.invalidate(okunmamisBildirimSayisiProvider);
    ref.invalidate(bildirimListProvider);

    appRouter.go('/login');
  }

  // ---------------------------------------------------------------------------

  Future<void> _unregisterFromBackend(WidgetRef ref) async {
    final deviceId = await DeviceRegistrationService().getDeviceId();
    final repo = ref.read(notificationRepositoryProvider);
    await repo.tokenSil(deviceId: deviceId);
    if (kDebugMode)
      print('📤 Backend UnregisterToken gönderildi: deviceId=$deviceId');
  }
}

/// Riverpod provider — her yerden erişim için
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

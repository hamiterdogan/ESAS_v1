import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/core/services/device_registration_service.dart';
import 'package:esas_v1/features/bildirim/repositories/notification_repository.dart';
import 'package:esas_v1/core/routing/router.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';

/// Background mesaj handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // iOS hariç Firebase'i initialize et
  if (!Platform.isIOS) {
    await Firebase.initializeApp();
  }
  if (kDebugMode) {
    print('📩 Background mesaj alındı: ${message.messageId}');
  }
}

/// FCM Notification Service
/// FCM başlatma, token yönetimi, mesaj handling ve local notification gösterme
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Her yerden navigasyon için global navigator key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Riverpod ProviderContainer - initialization sırasında set edilir
  ProviderContainer? _container;

  // Uygulama kapalıyken tıklanan bildirim için bekleyen route
  String? _pendingRoute;

  // FCM token yenileme listener'ı (resetRegistrationFlow için)
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Firebase mesaj listener'ları (resetRegistrationFlow'da iptal edilir)
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  // Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'esas_notifications',
    'ESAS Bildirimler',
    description: 'ESAS uygulama bildirimleri',
    importance: Importance.high,
    enableVibration: true,
    playSound: true,
  );

  /// Servisi başlat
  Future<void> initialize() async {
    // Background handler kaydet (sync, hemen)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // İzin isteği, local notifications kurulumu ve başlangıç mesajını paralel çalıştır
    final results = await Future.wait([
      _requestPermission(),
      _setupLocalNotifications(),
      _messaging.getInitialMessage(),
    ]);

    // Android notification channel (local notifications hazır olduktan sonra)
    await _createNotificationChannel();

    // Foreground mesaj dinle
    _onMessageSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    // Bildirime tıklama (app background'dayken)
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageOpenedApp,
    );

    // App tamamen kapalıyken bildirime tıklama
    // → route'u pending olarak sakla, HomeScreen mount olduktan sonra navigate et
    final initialMessage = results[2] as RemoteMessage?;
    if (initialMessage != null) {
      final data = initialMessage.data;
      _storeAsPendingRoute(data);
    }

    if (kDebugMode) {
      print('✅ NotificationService initialized');
    }
  }

  /// Riverpod ProviderContainer'ı set et (main.dart'tan çağrılır)
  void setContainer(ProviderContainer container) {
    _container = container;
  }

  /// Uygulama kapalıyken tıklanan bildirim route'unu pending olarak sakla
  void _storeAsPendingRoute(Map<String, dynamic> data) {
    Map<String, dynamic> resolved = data;
    final payloadStr = data['payload'];
    if (payloadStr is String && payloadStr.isNotEmpty) {
      try {
        final parsed = jsonDecode(payloadStr);
        if (parsed is Map<String, dynamic>) resolved = parsed;
      } catch (_) {}
    }

    final onayTipi =
        resolved['onayTipi'] as String? ?? resolved['OnayTipi'] as String?;
    final onayKayitIdRaw = resolved['onayKayitId'] ?? resolved['OnayKayitId'];
    final onayKayitId = onayKayitIdRaw is int
        ? onayKayitIdRaw
        : int.tryParse(onayKayitIdRaw?.toString() ?? '');

    if (onayTipi != null && onayKayitId != null) {
      _pendingRoute = _getRouteFromOnayTipi(onayTipi, onayKayitId);
    }

    if (_pendingRoute == null) {
      final bildirimTipi = resolved['bildirimTipi'] as String?;
      final talepId = int.tryParse(resolved['talepId']?.toString() ?? '');
      if (bildirimTipi != null && talepId != null) {
        _pendingRoute = _getRouteFromBildirimTipi(bildirimTipi, talepId);
      }
    }

    if (kDebugMode) print('📌 Pending route saklandı: $_pendingRoute');
  }

  /// HomeScreen mount olduktan sonra pending route'u tüket ve navigate et
  void consumePendingRoute() {
    final route = _pendingRoute;
    if (route == null) return;
    _pendingRoute = null;
    if (kDebugMode) print('🚀 Pending route tüketiliyor: $route');
    // postFrameCallback: HomeScreen tam olarak render olduktan sonra push et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateTo(route);
    });
  }

  /// FCM Token'ı al ve API'ye cihaz bilgileriyle birlikte kaydet.
  /// [forceRefresh] true ise cache kontrolü atlanır ve API her durumda çağrılır.
  Future<String?> getAndRegisterToken(
    NotificationRepository repo, {
    bool forceRefresh = false,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('\n🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥');
          print('🔥 FCM Token: $token');
          print('🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥\n');
        }

        final isRegistered = await DeviceRegistrationService().registerDevice(
          fcmToken: token,
          repo: repo,
          forceRefresh: forceRefresh,
        );
        if (!isRegistered) {
          if (kDebugMode) {
            print('❌ RegisterToken çağrısı başarısız.');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print(
            '❌ FCM token alınamadı (null). RegisterToken çağrısı yapılamadı.',
          );
        }
        return null;
      }

      // Token yenilendiğinde eski kaydı sıfırla ve yeniden kayıt yap
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((
        newToken,
      ) async {
        if (kDebugMode) {
          print('🔄 FCM Token yenilendi: $newToken');
        }
        // Eski kaydı sil, yeni token'ı zorla kaydet
        await DeviceRegistrationService().clearRegistration();
        await DeviceRegistrationService().registerDevice(
          fcmToken: newToken,
          repo: repo,
          forceRefresh: true,
        );
      });

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Token alma hatası: $e');
      }
      return null;
    }
  }

  /// Tüm kayıt akışını sıfırlar (logout/unauthorized senaryolarında).
  /// Eski listener'ları iptal eder ve Firebase'den token'ı siler.
  Future<void> resetRegistrationFlow() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = null;
    try {
      await _messaging.deleteToken();
    } catch (e) {
      if (kDebugMode) print('⚠️ FCM deleteToken hatası: $e');
    }
  }

  /// İzin iste
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('📱 Bildirim izni: ${settings.authorizationStatus}');
    }

    // iOS foreground ayarları
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Local notifications kur
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS notification categories (aksiyon butonları için)
    final List<DarwinNotificationCategory> darwinNotificationCategories =
        <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            'ONAY_BEKLIYOR',
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain('onayla', 'Onayla'),
              DarwinNotificationAction.plain(
                'reddet',
                'Reddet',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.destructive,
                },
              ),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ];

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: darwinNotificationCategories,
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Android notification channel oluştur
  Future<void> _createNotificationChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  /// Foreground mesaj geldiğinde
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📬 Foreground mesaj: ${message.notification?.title}');
    }

    // Local notification göster
    _showLocalNotification(message);

    // Badge sayısını güncelle
    _container?.invalidate(okunmamisBildirimSayisiProvider);
  }

  /// Local notification göster
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final aksiyonTipi = data['aksiyonTipi'] ?? 'bilgilendirme';

    // Android notification detayları
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(notification.body ?? ''),
      // Onay bekleyen bildirimler için action button'ları
      actions: aksiyonTipi == 'onay_bekliyor'
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'onayla',
                'Onayla',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'reddet',
                'Reddet',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: aksiyonTipi == 'onay_bekliyor'
          ? 'ONAY_BEKLIYOR'
          : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // payload olarak data'yı JSON string olarak gönder
    final payload = _encodePayload(data);

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body?.replaceAll('<br />', '\n'),
      details,
      payload: payload,
    );
  }

  /// Bildirime tıklandığında (local notification'dan)
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('👆 Bildirime tıklandı: ${response.payload}');
    }

    // Action button'a tıklandıysa
    if (response.actionId == 'onayla' || response.actionId == 'reddet') {
      _handleNotificationAction(response.actionId!, response.payload);
      return;
    }

    // Normal tıklanma → deep link
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _navigateFromData(data);
    }
  }

  /// Background'dan açılan mesaj
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('🚀 Bildirimle uygulama açıldı: ${message.notification?.title}');
    }

    _navigateFromData(message.data);
  }

  /// Data'dan navigasyon yap
  void _navigateFromData(Map<String, dynamic> data) {
    if (kDebugMode) print('🗺️ _navigateFromData: $data');

    // FCM data might have a 'payload' key containing a nested JSON string.
    // jsonDecode properly converts unicode escapes (e.g. \u0131 → ı).
    Map<String, dynamic> resolved = data;
    final payloadStr = data['payload'];
    if (payloadStr is String && payloadStr.isNotEmpty) {
      try {
        final parsed = jsonDecode(payloadStr);
        if (parsed is Map<String, dynamic>) resolved = parsed;
      } catch (_) {}
    }

    // New format: onayTipi + onayKayitId
    final onayTipi =
        resolved['onayTipi'] as String? ?? resolved['OnayTipi'] as String?;
    final onayKayitIdRaw = resolved['onayKayitId'] ?? resolved['OnayKayitId'];
    final onayKayitId = onayKayitIdRaw is int
        ? onayKayitIdRaw
        : int.tryParse(onayKayitIdRaw?.toString() ?? '');

    if (onayTipi != null && onayKayitId != null) {
      final route = _getRouteFromOnayTipi(onayTipi, onayKayitId);
      if (route != null) {
        if (kDebugMode) print('🚀 Deep link → $route');
        _navigateTo(route);
        return;
      }
    }

    // Fallback: old format bildirimTipi + talepId
    final bildirimTipi =
        resolved['bildirimTipi'] as String? ?? data['bildirimTipi'] as String?;
    final talepIdStr =
        resolved['talepId'] as String? ?? data['talepId'] as String?;
    final talepId = int.tryParse(talepIdStr ?? '');

    if (bildirimTipi != null && talepId != null) {
      final route = _getRouteFromBildirimTipi(bildirimTipi, talepId);
      if (route != null) {
        _navigateTo(route);
        return;
      }
    }

    _navigateTo('/bildirimler');
  }

  /// onayTipi (Turkish human-readable) → route
  String? _getRouteFromOnayTipi(String onayTipi, int onayKayitId) {
    final n = _normalizeOnayTipi(onayTipi);
    if (n.contains('satinalma')) return '/satin_alma/detay/$onayKayitId';
    if (n.contains('izin')) return '/izin/detay/$onayKayitId';
    if (n.contains('arac') || n.contains('arac'))
      return '/arac/detay/$onayKayitId';
    if (n.contains('dokumantasyon') || n.contains('dokuman')) {
      return '/dokumantasyon/detay/$onayKayitId';
    }
    if (n.contains('egitim')) return '/egitim_istek/detay/$onayKayitId';
    if (n.contains('yiyecek') || n.contains('icecek')) {
      return '/yiyecek_icecek_istek/detay/$onayKayitId';
    }
    if (n.contains('sarfmalzeme') || n.contains('sarf')) {
      return '/sarf_malzeme_istek/detay/$onayKayitId';
    }
    if (n.contains('bilgiteknoloji')) {
      return '/teknik_destek/detay/$onayKayitId';
    }
    if (n.contains('teknikdestek') || n.contains('teknik'))
      return '/teknik_destek/detay/$onayKayitId';
    if (kDebugMode) print('⚠️ Bilinmeyen onayTipi: $onayTipi (normalized: $n)');
    return null;
  }

  /// Türkçe karakterleri normalize et (karşılaştırma için)
  String _normalizeOnayTipi(String s) => s
      .replaceAll('İ', 'I')
      .replaceAll('Ğ', 'G')
      .replaceAll('Ü', 'U')
      .replaceAll('Ş', 'S')
      .replaceAll('Ö', 'O')
      .replaceAll('Ç', 'C')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(' ', '');

  /// Bildirim tipinden route hesapla (eski format)
  String? _getRouteFromBildirimTipi(String bildirimTipi, int talepId) {
    switch (bildirimTipi) {
      case 'satin_alma':
        return '/satin_alma/detay/$talepId';
      case 'arac_istek':
        return '/arac/detay/$talepId';
      case 'izin_istek':
        return '/izin/detay/$talepId';
      case 'dokumantasyon_istek':
        return '/dokumantasyon/detay/$talepId';
      case 'egitim_istek':
        return '/egitim_istek/detay/$talepId';
      case 'yiyecek_icecek_istek':
        return '/yiyecek_icecek_istek/detay/$talepId';
      case 'bilgi_teknolojileri':
        return '/teknik_destek/detay/$talepId';
      case 'teknik_destek':
        return '/teknik_destek/detay/$talepId';
      case 'sarf_malzeme_istek':
        return '/sarf_malzeme_istek/detay/$talepId';
      default:
        return null;
    }
  }

  /// Route'a git
  void _navigateTo(String route) {
    // Use appRouter directly — navigatorKey is not bound to GoRouter
    try {
      appRouter.push(route);
      if (kDebugMode) print('✅ Navigated to $route');
    } catch (e) {
      if (kDebugMode) print('❌ Navigation failed: $e');
    }
  }

  /// Bildirim action button handler (Onayla/Reddet)
  Future<void> _handleNotificationAction(
    String actionId,
    String? payload,
  ) async {
    if (payload == null || _container == null) return;

    final data = _decodePayload(payload);
    final bildirimIdStr = data['bildirimId'] as String?;
    final onayKayitIdStr = data['onayKayitId'] as String?;
    final onayTipi = data['onayTipi'] as String?;

    final bildirimId = int.tryParse(bildirimIdStr ?? '');
    final onayKayitId = int.tryParse(onayKayitIdStr ?? '');

    if (bildirimId == null || onayKayitId == null || onayTipi == null) return;

    final repo = _container!.read(notificationRepositoryProvider);
    final aksiyon = actionId == 'onayla' ? 'onayla' : 'reddet';

    final result = await repo.bildirimAksiyon(
      bildirimId: bildirimId,
      onayKayitId: onayKayitId,
      onayTipi: onayTipi,
      aksiyon: aksiyon,
    );

    if (kDebugMode) {
      switch (result) {
        case Success(:final data):
          print('✅ Bildirim aksiyon başarılı: ${data.mesaj}');
        case Failure(:final message):
          print('❌ Bildirim aksiyon hata: $message');
        case Loading():
          break;
      }
    }

    // Badge ve listeyi güncelle
    _container!.invalidate(okunmamisBildirimSayisiProvider);
  }

  /// Payload encode (Map → String)
  String _encodePayload(Map<String, dynamic> data) {
    // Basit key=value formatında encode
    return data.entries.map((e) => '${e.key}=${e.value}').join('|');
  }

  /// Payload decode (String → Map)
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final part in payload.split('|')) {
      final index = part.indexOf('=');
      if (index > 0) {
        map[part.substring(0, index)] = part.substring(index + 1);
      }
    }
    return map;
  }
}

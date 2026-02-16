import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/bildirim/repositories/notification_repository.dart';
import 'package:esas_v1/features/bildirim/providers/notification_providers.dart';

/// Background mesaj handler (top-level function olmalı)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

  // Riverpod ref - initialization sırasında set edilir
  WidgetRef? _ref;

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
    // Background handler kaydet
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // İzin iste
    await _requestPermission();

    // Local notifications kur
    await _setupLocalNotifications();

    // Android notification channel oluştur
    await _createNotificationChannel();

    // Foreground mesaj dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklama (app background'dayken)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App tamamen kapalıyken bildirime tıklama
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    if (kDebugMode) {
      print('✅ NotificationService initialized');
    }
  }

  /// Riverpod ref'i set et (ProviderScope içinden çağrılır)
  void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// FCM Token'ı al ve API'ye kaydet
  Future<String?> getAndRegisterToken(NotificationRepository repo) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('🔑 FCM Token: $token');
        }

        final platform = Platform.isIOS ? 'ios' : 'android';
        await repo.tokenKaydet(fcmToken: token, platform: platform);
      }

      // Token yenilendiğinde tekrar kaydet
      _messaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('🔄 FCM Token yenilendi: $newToken');
        }
        final platform = Platform.isIOS ? 'ios' : 'android';
        await repo.tokenKaydet(fcmToken: newToken, platform: platform);
      });

      return token;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Token alma hatası: $e');
      }
      return null;
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
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
      )
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
            AndroidFlutterLocalNotificationsPlugin>()
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
    _ref?.invalidate(okunmamisBildirimSayisiProvider);
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
      categoryIdentifier: aksiyonTipi == 'onay_bekliyor' ? 'ONAY_BEKLIYOR' : null,
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
      notification.body,
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
    final bildirimTipi = data['bildirimTipi'] as String?;
    final talepIdStr = data['talepId'] as String?;
    final talepId = int.tryParse(talepIdStr ?? '');

    if (bildirimTipi == null || talepId == null) {
      // Bildirimler sayfasına git
      _navigateTo('/bildirimler');
      return;
    }

    // Deep link route oluştur
    final route = _getRouteFromBildirimTipi(bildirimTipi, talepId);
    if (route != null) {
      _navigateTo(route);
    } else {
      _navigateTo('/bildirimler');
    }
  }

  /// Bildirim tipinden route hesapla
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
        return '/bilgi_teknolojileri';
      case 'teknik_destek':
        return '/teknik_destek';
      case 'sarf_malzeme_istek':
        return '/sarf_malzeme_istek';
      default:
        return null;
    }
  }

  /// Route'a git
  void _navigateTo(String route) {
    // GoRouter kullanarak navigasyon
    final context = navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).push(route);
    }
  }

  /// Bildirim action button handler (Onayla/Reddet)
  Future<void> _handleNotificationAction(
      String actionId, String? payload) async {
    if (payload == null || _ref == null) return;

    final data = _decodePayload(payload);
    final bildirimIdStr = data['bildirimId'] as String?;
    final onayKayitIdStr = data['onayKayitId'] as String?;
    final onayTipi = data['onayTipi'] as String?;

    final bildirimId = int.tryParse(bildirimIdStr ?? '');
    final onayKayitId = int.tryParse(onayKayitIdStr ?? '');

    if (bildirimId == null || onayKayitId == null || onayTipi == null) return;

    final repo = _ref!.read(notificationRepositoryProvider);
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
    _ref!.invalidate(okunmamisBildirimSayisiProvider);
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

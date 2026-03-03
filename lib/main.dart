import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routing/router.dart';
import 'core/network/dio_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/auth_storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/utils/jwt_decoder.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Global Flutter framework error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kDebugMode) {
          FlutterError.presentError(details);
        }
        // TODO: integrate crash reporting (e.g. FirebaseCrashlytics) here
      };

      // 1. Firebase'i başlat (AppRoot'tan taşındı — tek splash için)
      // NotificationService build içinde hemen çağırıldığı için main'de await edilmeli.
      await Firebase.initializeApp();

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      // Catches async errors outside Flutter's widget layer
      if (kDebugMode) {
        debugPrint('Unhandled error: $error\n$stack');
      }
      // TODO: integrate crash reporting (e.g. FirebaseCrashlytics) here
    },
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialized = false;
  bool _isReady = false; // Token kontrolü tamamlanana kadar ekranda kalacak
  bool _notificationContainerSet = false;

  @override
  void initState() {
    super.initState();
    _loadTokenAndInit();
  }

  Future<void> _loadTokenAndInit() async {
    final storage = AuthStorageService();

    // 2. Eski SharedPreferences token'ı SecureStorage'a taşı (tek seferlik migrasyon)
    await storage.migrateIfNeeded();

    // 3. Kaydedilmiş token'ı oku
    final savedToken = await storage.getToken();

    if (savedToken != null && savedToken.isNotEmpty) {
      // JWT expiry kontrolü: süresi dolmuşsa temizle
      if (JwtDecoder.isExpired(savedToken)) {
        await storage.clear();
        ref.read(tokenProvider.notifier).setToken('');
        authStateNotifier.value = false;
      } else {
        ref.read(tokenProvider.notifier).setToken(savedToken);
        authStateNotifier.value = true;
      }
    } else {
      ref.read(tokenProvider.notifier).setToken('');
      authStateNotifier.value = false;
    }

    // 4. Bildirim servisini başlat (izinler, kanallar, foreground listener'lar)
    await _initNotificationServiceOnly();

    // RegisterToken çağrısı login akışında zorunlu olarak yapılır.
    // App start'ta otomatik register yapmayarak eski JWT ile yarış durumlarını engelleriz.

    // İşlemler tamamlandı, UI'yi aç
    if (mounted) {
      setState(() {
        _isReady = true;
      });
      FlutterNativeSplash.remove();
    }
  }

  /// Bildirim servisini başlat (sadece izinler, kanallar, listener'lar).
  Future<void> _initNotificationServiceOnly() async {
    if (_initialized) return;
    _initialized = true;
    await NotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    // 401 hatası dinle: kullanıcıyı bilgilendir ve login'e yönlendir
    // ProviderContainer''ı NotificationService''e bağla (C1 fix: WidgetRef yerine ProviderContainer kullan)
    if (!_notificationContainerSet) {
      _notificationContainerSet = true;
      NotificationService().setContainer(ProviderScope.containerOf(context));
    }

    ref.listen<bool>(authErrorProvider, (previous, hasError) {
      if (hasError && previous != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // AuthService aracılığıyla tam logout (FCM deleteToken + UnregisterToken + temizlik)
          await AuthService().logoutWithoutRef(ref);
        });
        // Auth hata durumunu sıfırla
        ref.read(authErrorProvider.notifier).setError(false);
      }
    });

    // Token okuması ve yönlendirme tamamlanana kadar splash ekranı göster
    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Image.asset(
              'assets/images/eek_esas_logo.png',
              width: 400,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'ESAS - İzin İstek',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      routerConfig: appRouter,
    );
  }
}

// Global scaffold messenger key for showing snackbars from anywhere
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

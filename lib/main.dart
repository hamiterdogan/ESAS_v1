import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routing/router.dart';
import 'core/network/dio_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'core/services/auth_storage_service.dart';
import 'core/services/auth_service.dart';
import 'core/utils/jwt_decoder.dart';
import 'features/bildirim/providers/notification_providers.dart';
import 'features/bildirim/repositories/notification_repository.dart';
import 'common/widgets/branded_loading_indicator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AppRoot()));
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  // Firebase ve diğer kritik başlatma işlemlerini burada yapıyoruz
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _init();
  }

  Future<void> _init() async {
    await Firebase.initializeApp();
    // Token loading will be handled in MyApp initState
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ProviderScope(child: const MyApp());
        }

        // Açılış (Splash) ekranı
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/images/logo_icon.png', width: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Load token from storage and initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTokenAndInit();
    });
  }

  Future<void> _loadTokenAndInit() async {
    final storage = AuthStorageService();

    // 1. Eski SharedPreferences token'ı SecureStorage'a taşı (tek seferlik migrasyon)
    await storage.migrateIfNeeded();

    // 2. Kaydedilmiş token'ı oku
    final savedToken = await storage.getToken();

    if (savedToken != null && savedToken.isNotEmpty) {
      // 3. JWT expiry kontrolü: süresi dolmuşsa temizle
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

    // 5. Kullanıcı zaten authenticated ise → FCM token'ı kaydedilmiş JWT ile kaydet
    //    ⚡ Riverpod provider zincirine güvenmiyoruz; doğrudan fresh Dio oluşturuyoruz.
    if (savedToken != null && savedToken.isNotEmpty && !JwtDecoder.isExpired(savedToken)) {
      unawaited(_registerFcmTokenWithJwt(savedToken));
    }
  }

  /// Bildirim servisini başlat (sadece izinler, kanallar, listener'lar).
  Future<void> _initNotificationServiceOnly() async {
    if (_initialized) return;
    _initialized = true;
    await NotificationService().initialize();
  }

  /// Kaydedilmiş JWT ile doğrudan fresh Dio oluşturup RegisterToken çağır.
  /// Riverpod provider zincirine güvenmez.
  Future<void> _registerFcmTokenWithJwt(String jwt) async {
    try {
      final freshDio = Dio(BaseOptions(
        baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
      ));
      final freshRepo = NotificationRepositoryImpl(dio: freshDio);
      await NotificationService().getAndRegisterToken(freshRepo);
      if (kDebugMode) print('✅ App restart: RegisterToken (freshDio) tamamlandı.');
    } catch (e) {
      if (kDebugMode) print('⚠️ App restart RegisterToken hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 401 hatası dinle: kullanıcıyı bilgilendir ve login'e yönlendir
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

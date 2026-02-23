import 'dart:async';
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
  bool _tokenRegistered = false;
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
        // 4. FCM kaydı sadece authenticated kullanıcı için
        _initNotificationService();
      }
    } else {
      ref.read(tokenProvider.notifier).setToken('');
      authStateNotifier.value = false;
      // Bildirimleri başlat ama token register etme
      _initNotificationServiceOnly();
    }
  }

  Future<void> _initNotificationService() async {
    if (_initialized) return;
    _initialized = true;

    unawaited(
      NotificationService().initialize().then((_) => _registerFcmToken()),
    );
  }

  /// Sadece servisi başlat, token register etme (login olmamış kullanıcı için)
  Future<void> _initNotificationServiceOnly() async {
    if (_initialized) return;
    _initialized = true;
    unawaited(NotificationService().initialize());
  }

  Future<void> _registerFcmToken() async {
    if (_tokenRegistered) return;
    _tokenRegistered = true;

    final notificationService = NotificationService();
    notificationService.setRef(ref);

    final repo = ref.read(notificationRepositoryProvider);
    await notificationService.getAndRegisterToken(repo);
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

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
    // Load saved token from storage
    final storage = AuthStorageService();
    final savedToken = await storage.getToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      ref.read(tokenProvider.notifier).setToken(savedToken);
    }

    // Then init notification service
    _initNotificationService();
  }

  Future<void> _initNotificationService() async {
    if (_initialized) return;
    _initialized = true;

    // Servisi başlat (izin iste vs.) — token kaydı ile paralel
    // Fire-and-forget: açılışı bloklamayacak şekilde arka planda çalışır
    unawaited(
      NotificationService().initialize().then((_) => _registerFcmToken()),
    );
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
          // Storage'ı temizle ve token provider'ı sıfırla
          await AuthStorageService().clear();
          ref.read(tokenProvider.notifier).setToken('');

          // Login ekranına yönlendir
          appRouter.go('/login');

          // Snackbar ile kullanıcıyı bilgilendir
          final messenger = rootScaffoldMessengerKey.currentState;
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('Oturum süresi doldu. Lütfen tekrar giriş yapın.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
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

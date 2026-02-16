import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/routing/router.dart';
import 'core/network/dio_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/services/notification_service.dart';
import 'features/bildirim/providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
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
    // Bildirim servisini ve token kaydını başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotificationService();
    });
  }

  Future<void> _initNotificationService() async {
    if (_initialized) return;
    _initialized = true;

    // Servisi başlat (izin iste vs.)
    await NotificationService().initialize();

    // Token kaydet
    await _registerFcmToken();
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
    // 401 hatası dinle ve kullanıcıyı bilgilendir
    ref.listen<bool>(authErrorProvider, (previous, hasError) {
      if (hasError && previous != true) {
        // Navigasyon context'i olmadan global key ile erişiyoruz
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final messenger = rootScaffoldMessengerKey.currentState;
          if (messenger != null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
                ),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
        // Reset auth error state
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

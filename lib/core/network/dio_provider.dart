import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/utils/jwt_decoder.dart';
import 'package:esas_v1/core/services/auth_storage_service.dart';

// Token Notifier
class TokenNotifier extends Notifier<String> {
  @override
  String build() {
    // Başlangıçta boş; main.dart'ta storage'dan yüklenir
    return '';
  }

  void setToken(String token) {
    state = token;
  }
}

// Token Provider
final tokenProvider = NotifierProvider<TokenNotifier, String>(
  TokenNotifier.new,
);

// Auth Error Notifier - Riverpod 3 pattern (StateProvider yerine)
class AuthErrorNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setError(bool value) {
    state = value;
  }
}

// Auth state provider - 401 durumunda true olur
final authErrorProvider = NotifierProvider<AuthErrorNotifier, bool>(
  AuthErrorNotifier.new,
);

// Current User PersonelId Provider
final currentPersonelIdProvider = Provider<int>((ref) {
  final token = ref.watch(tokenProvider);
  final personelId = JwtDecoder.getPersonelId(token);
  return personelId ?? 0; // Default 0 if decode fails
});

// Current User KullaniciAdi Provider
final currentKullaniciAdiProvider = Provider<String>((ref) {
  final token = ref.watch(tokenProvider);
  final kullaniciAdi = JwtDecoder.getKullaniciAdi(token);
  return kullaniciAdi ?? ''; // Default empty string if decode fails
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final token = ref.watch(tokenProvider);

  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }

  dio.options = BaseOptions(
    baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: headers,
  );

  // Sadece debug modda log interceptor aktif
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final authHeader = options.headers['Authorization']?.toString() ?? '';
        final requestToken = authHeader.startsWith('Bearer ')
            ? authHeader.substring(7)
            : authHeader;
        options.extra['requestToken'] = requestToken;
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          final requestToken =
              error.requestOptions.extra['requestToken']?.toString() ?? '';
          final currentToken = ref.read(tokenProvider);

          // Public login endpointinde 401 beklenebilir (yanlış şifre vb.), global logout tetikleme.
          if (path.contains('/Kullanici/GirisYap')) {
            handler.next(error);
            return;
          }

          // İstek token'ı güncel token ile eşleşmiyorsa bu stale bir request'tir; logout tetikleme.
          if (requestToken.isNotEmpty &&
              currentToken.isNotEmpty &&
              requestToken != currentToken) {
            if (kDebugMode) {
              print('ℹ️ 401 stale request ignore edildi (eski token).');
            }
            handler.next(error);
            return;
          }

          // Token geçersiz veya süresi dolmuş (güncel token için)
          ref.read(authErrorProvider.notifier).setError(true);
          if (kDebugMode) {
            print('⚠️ 401 Unauthorized - Token expired or invalid');
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

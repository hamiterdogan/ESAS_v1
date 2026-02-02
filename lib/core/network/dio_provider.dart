import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/utils/jwt_decoder.dart';

// Token Provider
final tokenProvider = Provider<String>((ref) {
  return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJQZXJzb25lbElkIjoiMTMxIiwiRW1haWwiOiJ0ZXN0bXVzdGFmYS55aWxtYXpAZXl1Ym9nbHUuazEyLnRyIiwiS3VsbGFuaWNpQWRpIjoiTVVZSUxNQVoiLCJHb3JldklkIjoiNTkiLCJuYmYiOjE3Njk1ODU0MzcsImV4cCI6MTgwMDY4OTQzNywiaXNzIjoiaHR0cDovL2xvY2FsaG9zdCIsImF1ZCI6Imh0dHA6Ly9sb2NhbGhvc3QifQ.buPMZKXqq4geAw6GI2hKxUJONUTd0CzWOOT8y1SV52Y';
});

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
  final token = ref.read(tokenProvider);

  dio.options = BaseOptions(
    baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  // Sadece debug modda log interceptor aktif
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token geçersiz veya süresi dolmuş
          // authErrorProvider'ı true yap - UI bunu dinleyip kullanıcıyı bilgilendirecek
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

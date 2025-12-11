import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/utils/jwt_decoder.dart';

// Token Provider
final tokenProvider = Provider<String>((ref) {
  return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJQZXJzb25lbElkIjoiNDUwNyIsIkVtYWlsIjoidGVzdGV2cmVuLnRvbWJ1bEBleXVib2dsdS5rMTIudHIiLCJLdWxsYW5pY2lBZGkiOiJFVE9NQlVMIiwiR29yZXZJZCI6IjQ2IiwibmJmIjoxNzY0MzI5NDUwLCJleHAiOjE3OTU0MzM0NTAsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3QiLCJhdWQiOiJodHRwOi8vbG9jYWxob3N0In0.lSaV7AXUSEvbNb6m4YCwCyUcP7Tbs5hn4YoJt7WzrGg';
});

// Current User PersonelId Provider
final currentPersonelIdProvider = Provider<int>((ref) {
  final token = ref.watch(tokenProvider);
  final personelId = JwtDecoder.getPersonelId(token);
  return personelId ?? 0; // Default 0 if decode fails
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final token = ref.read(tokenProvider);

  dio.options = BaseOptions(
    baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {}
        handler.next(error);
      },
    ),
  );

  return dio;
});

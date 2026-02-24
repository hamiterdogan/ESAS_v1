import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService(ref.read(dioProvider));
});

class EmailService {
  final Dio _dio;

  EmailService(this._dio);

  Future<void> emailIcerikOlustur({
    required int id,
    required String kategori,
    required String aksiyon,
  }) async {
    try {
      await _dio.post(
        '/Email/EmailIcerikOlustur',
        data: {
          'id': id,
          'kategori': kategori,
          'aksiyon': aksiyon,
        },
      );
      log('Email trigger sent for id: $id, kategori: $kategori');
    } catch (e) {
      log('Email trigger failed: $e');
    }
  }
}

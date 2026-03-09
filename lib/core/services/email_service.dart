import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

final emailServiceProvider = Provider<EmailService>((ref) {
  return EmailService(ref.read(dioProvider));
});

class EmailService {
  final Dio _dio;
  final Map<String, Future<void>> _pendingRequests = {};
  final Map<String, DateTime> _recentRequests = {};

  static const Duration _duplicateWindow = Duration(seconds: 5);

  EmailService(this._dio);

  Future<void> emailIcerikOlustur({
    required int id,
    required String kategori,
    required String aksiyon,
  }) async {
    final requestKey = '$id|$kategori|$aksiyon';
    final now = DateTime.now();
    final lastSentAt = _recentRequests[requestKey];

    if (lastSentAt != null && now.difference(lastSentAt) < _duplicateWindow) {
      log('Duplicate email trigger skipped for $requestKey');
      return;
    }

    final pendingRequest = _pendingRequests[requestKey];
    if (pendingRequest != null) {
      log('In-flight email trigger reused for $requestKey');
      return pendingRequest;
    }

    final requestFuture = _sendEmailRequest(
      id: id,
      kategori: kategori,
      aksiyon: aksiyon,
      requestKey: requestKey,
    );

    _pendingRequests[requestKey] = requestFuture;

    try {
      await requestFuture;
    } finally {
      _pendingRequests.remove(requestKey);
    }
  }

  Future<void> _sendEmailRequest({
    required int id,
    required String kategori,
    required String aksiyon,
    required String requestKey,
  }) async {
    try {
      await _dio.post(
        '/Email/EmailIcerikOlustur',
        data: {'id': id, 'kategori': kategori, 'aksiyon': aksiyon},
      );
      _recentRequests[requestKey] = DateTime.now();
      log('Email trigger sent for id: $id, kategori: $kategori');
    } catch (e) {
      log('Email trigger failed: $e');
    }
  }
}

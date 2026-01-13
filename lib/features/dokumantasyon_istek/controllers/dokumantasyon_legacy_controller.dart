import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

/// Dokumantasyon İstek ekranındaki API çağrılarını izole eden controller.
///
/// Bu controller'ın amacı:
/// - Screen'den API mantığını ayırmak
/// - Error handling'i merkezileştirmek
/// - Gelecekte test edilebilirlik sağlamak
///
/// ⚠️ NOT: Bu bir geçici stabilizasyon katmanıdır.
class DokumantasyonLegacyController {
  final Dio _dio;

  DokumantasyonLegacyController(this._dio);

  /// Doküman türlerini API'den getirir
  Future<List<Map<String, dynamic>>> fetchDokumanTurleri() async {
    try {
      final response = await _dio.get('/DokumantasyonIstek/DokumanTuruGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      developer.log(
        'Doküman türleri yükleme hatası',
        name: 'DokumantasyonLegacyController.fetchDokumanTurleri',
        error: e,
      );
      rethrow;
    }
  }

  /// Baskı boyutlarını API'den getirir
  Future<List<Map<String, dynamic>>> fetchBaskiBoyutlari() async {
    try {
      final response = await _dio.get('/DokumantasyonIstek/BaskiBoyutuGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      developer.log(
        'Baskı boyutları yükleme hatası',
        name: 'DokumantasyonLegacyController.fetchBaskiBoyutlari',
        error: e,
      );
      rethrow;
    }
  }
}

/// Dokumantasyon Legacy Controller provider
final dokumantasyonLegacyControllerProvider =
    Provider<DokumantasyonLegacyController>((ref) {
      final dio = ref.watch(dioProvider);
      return DokumantasyonLegacyController(dio);
    });

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

/// Satın Alma ekranındaki API çağrılarını izole eden controller.
///
/// Bu controller'ın amacı:
/// - Screen'den API mantığını ayırmak
/// - Error handling'i merkezileştirmek
/// - Gelecekte test edilebilirlik sağlamak
///
/// ⚠️ NOT: Bu bir geçici stabilizasyon katmanıdır.
class SatinAlmaLegacyController {
  final Dio _dio;

  SatinAlmaLegacyController(this._dio);

  /// Döviz kurlarını günceller (Merkez Bankası)
  ///
  /// Bu çağrı kritik değil - başarısız olursa sessizce devam eder.
  /// Returns: true if success, false if failed
  Future<bool> updateExchangeRates() async {
    try {
      await _dio.post('/Finans/MerkezBankasiDovizKurlariniGuncelle', data: {});
      return true;
    } catch (e) {
      developer.log(
        'Döviz kurları güncelleme hatası (non-critical)',
        name: 'SatinAlmaLegacyController.updateExchangeRates',
        error: e,
      );
      // Silently fail - bu kritik değil
      return false;
    }
  }
}

/// Satın Alma Legacy Controller provider
final satinAlmaLegacyControllerProvider = Provider<SatinAlmaLegacyController>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return SatinAlmaLegacyController(dio);
});

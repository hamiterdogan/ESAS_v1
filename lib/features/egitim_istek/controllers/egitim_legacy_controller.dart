import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';

/// Egitim Talep ekranındaki API çağrılarını izole eden controller.
///
/// Bu controller'ın amacı:
/// - Screen'den API mantığını ayırmak
/// - Error handling'i merkezileştirmek
/// - Gelecekte test edilebilirlik sağlamak
///
/// ⚠️ NOT: Bu bir geçici stabilizasyon katmanıdır.
/// Mimari yeniden yazımda Clean Architecture ile değiştirilecek.
class EgitimLegacyController {
  final Dio _dio;

  EgitimLegacyController(this._dio);

  /// Eğitim adlarını API'den getirir
  /// Returns: ['DİĞER', ...egitimAdlari] listesi
  Future<List<String>> fetchEgitimAdlari() async {
    try {
      final response = await _dio.get('/EgitimIstek/EgitimAdlariDoldur');

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> egitimAdlari = [];

        if (data is Map<String, dynamic> && data.containsKey('egitimAdi')) {
          final adlar = data['egitimAdi'];
          if (adlar is List) {
            egitimAdlari = List<String>.from(adlar);
          }
        }

        return ['DİĞER', ...egitimAdlari];
      }
      return ['DİĞER'];
    } catch (e) {
      developer.log(
        'Eğitim adları yükleme hatası',
        name: 'EgitimLegacyController.fetchEgitimAdlari',
        error: e,
      );
      rethrow;
    }
  }

  /// Eğitim türlerini API'den getirir
  Future<List<String>> fetchEgitimTurleri() async {
    try {
      final response = await _dio.get('/EgitimIstek/EgitimTurleriDoldur');

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> egitimTurleri = [];

        if (data is Map<String, dynamic> && data.containsKey('egitimTurleri')) {
          final turler = data['egitimTurleri'];
          if (turler is List) {
            egitimTurleri = List<String>.from(turler);
          }
        }

        return egitimTurleri;
      }
      return [];
    } catch (e) {
      developer.log(
        'Eğitim türleri yükleme hatası',
        name: 'EgitimLegacyController.fetchEgitimTurleri',
        error: e,
      );
      rethrow;
    }
  }

  /// Şehir listesini API'den getirir
  /// Returns: ID'ye göre sıralı şehir listesi
  Future<List<Map<String, dynamic>>> fetchSehirler() async {
    try {
      final response = await _dio.get('/TalepYonetimi/SehirleriGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          final sehirler = List<Map<String, dynamic>>.from(data);
          sehirler.sort((a, b) {
            final idA = a['id'] as int? ?? 0;
            final idB = b['id'] as int? ?? 0;
            return idA.compareTo(idB);
          });
          return sehirler;
        }
      }
      return [];
    } catch (e) {
      developer.log(
        'Şehirler yükleme hatası',
        name: 'EgitimLegacyController.fetchSehirler',
        error: e,
      );
      rethrow;
    }
  }

  /// Alınan eğitim ücretini API'den getirir
  Future<double> fetchAlinanEgitimUcreti() async {
    try {
      final response = await _dio.get('/EgitimIstek/AlinanEgitimUcretiGetir');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> &&
            data.containsKey('aldigiEgitimUcreti')) {
          return (data['aldigiEgitimUcreti'] ?? 0).toDouble();
        }
      }
      return 0.0;
    } catch (e) {
      developer.log(
        'Alınan eğitim ücreti yükleme hatası',
        name: 'EgitimLegacyController.fetchAlinanEgitimUcreti',
        error: e,
      );
      // Ücret yüklenemezse 0 dön - kritik değil
      return 0.0;
    }
  }
}

/// Egitim Legacy Controller provider
///
/// Kullanım:
/// ```dart
/// final controller = ref.read(egitimLegacyControllerProvider);
/// final adlar = await controller.fetchEgitimAdlari();
/// ```
final egitimLegacyControllerProvider = Provider<EgitimLegacyController>((ref) {
  final dio = ref.watch(dioProvider);
  return EgitimLegacyController(dio);
});

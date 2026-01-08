import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:esas_v1/core/network/dio_provider.dart';
import 'package:dio/dio.dart';

class YiyecekIcecekRepository {
  final Dio _dio;

  YiyecekIcecekRepository(this._dio);

  Future<List<String>> getIkramTurleri() async {
    try {
      final response = await _dio.get('/YiyecekIstek/IkramDoldur');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => e.toString()).toList();
      } else {
        throw Exception('İkram türleri yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('İkram türleri yüklenirken hata oluştu: $e');
    }
  }
}

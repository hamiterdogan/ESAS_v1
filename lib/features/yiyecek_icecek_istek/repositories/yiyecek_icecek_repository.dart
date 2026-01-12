import 'package:dio/dio.dart';
import 'package:esas_v1/core/models/result.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_ekle_req.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_istek_taleplerimi_getir_models.dart';
import 'package:esas_v1/features/yiyecek_icecek_istek/models/yiyecek_icecek_istek_detay_model.dart';

class YiyecekIcecekRepository {
  final Dio dio;

  YiyecekIcecekRepository({required this.dio});

  Future<Result<YiyecekIcecekIstekDetayRes>> getYiyecekIstekDetay(int id) async {
    try {
      final response = await dio.post(
        '/YiyecekIstek/YiyecekIstekDetay',
        data: {'id': id},
      );

      if (response.statusCode == 200) {
        return Success(YiyecekIcecekIstekDetayRes.fromJson(response.data));
      }
      return Failure('Hata: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Bağlantı hatası');
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<List<String>> getIkramTurleri() async {
    try {
      final response = await dio.get('/YiyecekIstek/IkramDoldur');

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

  Future<void> yiyecekIstekEkle(YiyecekIstekEkleReq req) async {
    try {
      final response = await dio.post(
        '/YiyecekIstek/YiyecekIstekEkle',
        data: req.toJson(),
      );

      if (response.statusCode != 200) {
        throw Exception('İstek gönderilemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('İstek gönderilirken hata oluştu: $e');
    }
  }

  Future<YiyecekIstekTaleplerimiGetirRes> getYiyecekIstekTaleplerim({
    required int tip,
  }) async {
    try {
      final response = await dio.post(
        '/YiyecekIstek/YiyecekIstekTaleplerimiGetir',
        data: YiyecekIstekTaleplerimiGetirReq(tip: tip).toJson(),
      );

      if (response.statusCode == 200) {
        return YiyecekIstekTaleplerimiGetirRes.fromJson(response.data);
      } else {
        throw Exception('Talepler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Talepler yüklenirken hata oluştu: $e');
    }
  }

  Future<Result<void>> deleteTalep({required int id}) async {
    try {
      await dio.delete(
        '/YiyecekIstek/YiyecekIstekSil',
        queryParameters: {'id': id},
      );
      return const Success(null);
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

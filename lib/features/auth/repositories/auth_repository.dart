import 'package:dio/dio.dart';
import 'package:esas_v1/features/auth/models/login_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://esasapi.eyuboglu.k12.tr/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        ),
      );

  /// Giriş yap. Başarılı → LoginResponse, 401 → null, diğer hata → exception.
  Future<LoginResponse?> girisYap({
    required String kullaniciAdi,
    required String sifre,
  }) async {
    try {
      final response = await _dio.post(
        '/Kullanici/GirisYap',
        data: LoginRequest(kullaniciAdi: kullaniciAdi, sifre: sifre).toJson(),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null; // Yanlış kullanıcı adı / şifre
      }
      rethrow;
    }
  }
}

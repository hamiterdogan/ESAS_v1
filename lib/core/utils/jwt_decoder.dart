import 'dart:convert';

class JwtDecoder {
  /// JWT token'dan payload'ı decode eder
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid JWT token');
      }

      // Payload (ikinci kısım)
      final payload = parts[1];

      // Base64 padding ekle
      var normalized = base64Url.normalize(payload);

      // Decode et
      final decoded = utf8.decode(base64Url.decode(normalized));

      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('JWT decode hatası: $e');
    }
  }

  /// JWT token'dan PersonelId'yi çıkarır
  static int? getPersonelId(String token) {
    try {
      final payload = decode(token);
      final personelIdStr = payload['PersonelId'];

      if (personelIdStr == null) return null;

      // String olarak geliyorsa int'e çevir
      if (personelIdStr is String) {
        return int.tryParse(personelIdStr);
      }

      // Zaten int ise direkt dön
      if (personelIdStr is int) {
        return personelIdStr;
      }

      return null;
    } catch (e) {
      print('❌ PersonelId çıkarma hatası: $e');
      return null;
    }
  }
}

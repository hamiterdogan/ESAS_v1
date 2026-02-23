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
      return null;
    }
  }

  /// JWT token'dan KullaniciAdi'yi çıkarır
  static String? getKullaniciAdi(String token) {
    try {
      final payload = decode(token);
      final kullaniciAdi = payload['KullaniciAdi'];

      if (kullaniciAdi == null) return null;

      return kullaniciAdi.toString();
    } catch (e) {
      return null;
    }
  }

  /// JWT token'ın son kullanma tarihini döndürür (exp claim'den).
  /// Token geçersizse null döner.
  static DateTime? getExpiration(String token) {
    try {
      if (token.isEmpty) return null;
      final payload = decode(token);
      final exp = payload['exp'];
      if (exp == null) return null;
      final expInt = exp is int ? exp : int.tryParse(exp.toString());
      if (expInt == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(expInt * 1000, isUtc: true);
    } catch (e) {
      return null;
    }
  }

  /// Token'ın süresi dolmuş mu?
  /// Boş token veya parse edilemeyen token → true (dolmuş sayılır)
  static bool isExpired(String token) {
    if (token.isEmpty) return true;
    final expiration = getExpiration(token);
    if (expiration == null) return true;
    return DateTime.now().toUtc().isAfter(expiration);
  }
}

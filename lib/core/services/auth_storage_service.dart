import 'package:shared_preferences/shared_preferences.dart';
import 'package:esas_v1/features/auth/models/login_model.dart';

/// Kullanıcı oturum bilgilerini saklar.
/// Token ve kullanıcı verileri → SharedPreferences
class AuthStorageService {
  static const _keyToken = 'auth_token';

  // SharedPreferences anahtarları
  static const _keyPersonelId = 'auth_personel_id';
  static const _keyAdi = 'auth_adi';
  static const _keySoyadi = 'auth_soyadi';
  static const _keyKullaniciAdi = 'auth_kullanici_adi';
  static const _keyEmail = 'auth_email';
  static const _keyDepartmanId = 'auth_departman_id';
  static const _keyGorevId = 'auth_gorev_id';
  static const _keyGorevYeriId = 'auth_gorev_yeri_id';

  // Geçmiş sürümlerde veya farklı noktalarda kullanılma ihtimali olan token anahtarları
  static const _legacyTokenKeys = [
    _keyToken,
    'token',
    'jwt_token',
    'access_token',
  ];

  // ---------------------------------------------------------------------------
  // Geçiş uyumluluğu: artık tüm kayıtlar SharedPreferences'ta tutuluyor.
  // ---------------------------------------------------------------------------
  Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null && token.isEmpty) {
      await prefs.remove(_keyToken);
    }
  }

  // ---------------------------------------------------------------------------
  // Kaydet
  // ---------------------------------------------------------------------------
  Future<void> saveLogin(LoginResponse response) async {
    // Eski/çakışan token kayıtlarını temizle, sonra yeni token'ı yaz
    await _clearTokenEverywhere();

    final prefs = await SharedPreferences.getInstance();
    final futures = [
      prefs.setString(_keyToken, response.token),
      prefs.setInt(_keyPersonelId, response.personelId),
      prefs.setString(_keyAdi, response.adi),
      prefs.setString(_keySoyadi, response.soyadi),
      prefs.setString(_keyKullaniciAdi, response.kullaniciAdi),
      response.email != null
          ? prefs.setString(_keyEmail, response.email!)
          : prefs.remove(_keyEmail),
      response.departmanId != null
          ? prefs.setInt(_keyDepartmanId, response.departmanId!)
          : prefs.remove(_keyDepartmanId),
      response.gorevId != null
          ? prefs.setInt(_keyGorevId, response.gorevId!)
          : prefs.remove(_keyGorevId),
      response.gorevYeriId != null
          ? prefs.setInt(_keyGorevYeriId, response.gorevYeriId!)
          : prefs.remove(_keyGorevYeriId),
    ];
    await Future.wait(futures);
  }

  // ---------------------------------------------------------------------------
  // Okuma metodları
  // ---------------------------------------------------------------------------

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<int?> getPersonelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPersonelId);
  }

  // Ad + Soyad birleşik
  Future<String?> getAdSoyad() async {
    final prefs = await SharedPreferences.getInstance();
    final adi = prefs.getString(_keyAdi) ?? '';
    final soyadi = prefs.getString(_keySoyadi) ?? '';
    final full = '$adi $soyadi'.trim();
    return full.isEmpty ? null : full;
  }

  Future<String?> getAdi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdi);
  }

  Future<String?> getSoyadi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySoyadi);
  }

  Future<String?> getKullaniciAdi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyKullaniciAdi);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<int?> getDepartmanId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDepartmanId);
  }

  Future<int?> getGorevId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGorevId);
  }

  Future<int?> getGorevYeriId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGorevYeriId);
  }

  // Oturum açık mı?
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Temizle (logout / token expire)
  // ---------------------------------------------------------------------------
  Future<void> clear() async {
    // Token'ı ve kullanıcı verilerini local kaynaklardan sil
    await _clearTokenEverywhere();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyPersonelId),
      prefs.remove(_keyAdi),
      prefs.remove(_keySoyadi),
      prefs.remove(_keyKullaniciAdi),
      prefs.remove(_keyEmail),
      prefs.remove(_keyDepartmanId),
      prefs.remove(_keyGorevId),
      prefs.remove(_keyGorevYeriId),
    ]);
  }

  Future<void> _clearTokenEverywhere() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait(_legacyTokenKeys.map(prefs.remove));
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:esas_v1/features/auth/models/login_model.dart';

/// Kullanıcı oturum bilgilerini SharedPreferences'a kaydeder / okur.
class AuthStorageService {
  static const _keyToken = 'auth_token';
  static const _keyPersonelId = 'auth_personel_id';
  static const _keyAdi = 'auth_adi';
  static const _keySoyadi = 'auth_soyadi';
  static const _keyKullaniciAdi = 'auth_kullanici_adi';
  static const _keyEmail = 'auth_email';

  // Kaydet
  Future<void> saveLogin(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyToken, response.token),
      prefs.setInt(_keyPersonelId, response.personelId),
      prefs.setString(_keyAdi, response.adi),
      prefs.setString(_keySoyadi, response.soyadi),
      prefs.setString(_keyKullaniciAdi, response.kullaniciAdi),
      if (response.email != null)
        prefs.setString(_keyEmail, response.email!)
      else
        prefs.remove(_keyEmail),
    ]);
  }

  // Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // PersonelId
  Future<int?> getPersonelId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPersonelId);
  }

  // Kullanıcı adı tam (Ad + Soyad)
  Future<String?> getAdSoyad() async {
    final prefs = await SharedPreferences.getInstance();
    final adi = prefs.getString(_keyAdi) ?? '';
    final soyadi = prefs.getString(_keySoyadi) ?? '';
    final full = '$adi $soyadi'.trim();
    return full.isEmpty ? null : full;
  }

  Future<String?> getKullaniciAdi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyKullaniciAdi);
  }

  // Oturum açık mı?
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Çıkış / tüm verileri sil
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyToken),
      prefs.remove(_keyPersonelId),
      prefs.remove(_keyAdi),
      prefs.remove(_keySoyadi),
      prefs.remove(_keyKullaniciAdi),
      prefs.remove(_keyEmail),
    ]);
  }
}

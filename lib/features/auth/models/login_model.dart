class LoginRequest {
  final String kullaniciAdi;
  final String sifre;

  LoginRequest({required this.kullaniciAdi, required this.sifre});

  Map<String, dynamic> toJson() => {
    'kullaniciAdi': kullaniciAdi,
    'sifre': sifre,
  };
}

class LoginResponse {
  final int personelId;
  final String adi;
  final String soyadi;
  final String? telefon;
  final String? email;
  final String kullaniciAdi;
  final int? departmanId;
  final int? gorevId;
  final int? gorevYeriId;
  final bool aktif;
  final bool basarili;
  final String token;

  LoginResponse({
    required this.personelId,
    required this.adi,
    required this.soyadi,
    this.telefon,
    this.email,
    required this.kullaniciAdi,
    this.departmanId,
    this.gorevId,
    this.gorevYeriId,
    required this.aktif,
    required this.basarili,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      personelId: json['personelId'] as int,
      adi: json['adi'] as String? ?? '',
      soyadi: json['soyadi'] as String? ?? '',
      telefon: json['telefon'] as String?,
      email: json['email'] as String?,
      kullaniciAdi: json['kullaniciAdi'] as String? ?? '',
      departmanId: json['departmanId'] as int?,
      gorevId: json['gorevId'] as int?,
      gorevYeriId: json['gorevYeriId'] as int?,
      aktif: json['aktif'] as bool? ?? false,
      basarili: json['basarili'] as bool? ?? false,
      token: json['token'] as String? ?? '',
    );
  }
}

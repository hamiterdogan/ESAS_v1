class Personel {
  final int personelId;
  final String ad;
  final String soyad;
  final String? email;
  final String? telefon;
  final String? unvan;
  final String? adres;
  final int? gorevId;
  final int? departmanId;
  final int? gorevYeriId;
  final bool? aktif;
  final int? ustId;

  Personel({
    required this.personelId,
    required this.ad,
    required this.soyad,
    this.email,
    this.telefon,
    this.unvan,
    this.adres,
    this.gorevId,
    this.departmanId,
    this.gorevYeriId,
    this.aktif,
    this.ustId,
  });

  factory Personel.fromJson(Map<String, dynamic> json) {
    return Personel(
      personelId: json['personelId'] ?? 0,
      ad: json['adi'] ?? '',
      soyad: json['soyadi'] ?? '',
      email: json['email'],
      telefon: json['telefon'],
      unvan: json['unvan'],
      adres: json['adres'],
      gorevId: json['gorevId'],
      departmanId: json['departmanId'],
      gorevYeriId: json['gorevYeriId'],
      aktif: json['aktif'],
      ustId: json['ustId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personelId': personelId,
      'adi': ad,
      'soyadi': soyad,
      'email': email,
      'telefon': telefon,
      'unvan': unvan,
      'adres': adres,
      'gorevId': gorevId,
      'departmanId': departmanId,
      'gorevYeriId': gorevYeriId,
      'aktif': aktif,
      'ustId': ustId,
    };
  }

  String get fullName {
    final parts = [ad.trim(), soyad.trim()].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'İsimsiz' : parts.join(' ');
  }
}

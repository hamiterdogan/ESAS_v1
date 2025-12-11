class PersonelBilgiResponse {
  final String adSoyad;
  final String ad;
  final String soyad;
  final int gorevId;
  final String gorev;
  final int gorevYeriId;
  final String gorevYeri;
  final String? dini;

  PersonelBilgiResponse({
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevId,
    required this.gorev,
    required this.gorevYeriId,
    required this.gorevYeri,
    this.dini,
  });

  factory PersonelBilgiResponse.fromJson(Map<String, dynamic> json) {
    return PersonelBilgiResponse(
      adSoyad: json['adSoyad'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      soyad: json['soyad'] as String? ?? '',
      gorevId: json['gorevId'] as int? ?? 0,
      gorev: json['gorev'] as String? ?? '',
      gorevYeriId: json['gorevYeriId'] as int? ?? 0,
      gorevYeri: json['gorevYeri'] as String? ?? '',
      dini: json['dini'] as String?,
    );
  }
}

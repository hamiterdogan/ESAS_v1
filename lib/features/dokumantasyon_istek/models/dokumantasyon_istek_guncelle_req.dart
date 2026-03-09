class DokumantasyonIstekGuncelleReq {
  final int id;
  final int? baskiAdedi;
  final String? kagitTalebi;
  final String? dokumanTuru;
  final int? sayfaSayisi;
  final int? toplamSayfa;
  final int? paket; // New field for A4 request

  DokumantasyonIstekGuncelleReq({
    required this.id,
    this.baskiAdedi,
    this.kagitTalebi,
    this.dokumanTuru,
    this.sayfaSayisi,
    this.toplamSayfa,
    this.paket,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      if (baskiAdedi != null) 'baskiAdedi': baskiAdedi,
      if (kagitTalebi != null) 'kagitTalebi': kagitTalebi,
      if (dokumanTuru != null) 'dokumanTuru': dokumanTuru,
      if (sayfaSayisi != null) 'sayfaSayisi': sayfaSayisi,
      if (toplamSayfa != null) 'toplamSayfa': toplamSayfa,
      if (paket != null) 'paket': paket,
    };
    for (final key in map.keys.toList()) {
      final val = map[key];
      if (val is String && (val.isEmpty || val.toLowerCase() == 'string')) {
        map[key] = null;
      }
    }
    return map;
  }
}

class SatinAlmaTalepListResponse {
  final List<SatinAlmaTalep> talepler;

  SatinAlmaTalepListResponse({required this.talepler});

  factory SatinAlmaTalepListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['talepler'] as List? ?? const [];
    return SatinAlmaTalepListResponse(
      talepler: list
          .map((e) => SatinAlmaTalep.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SatinAlmaTalep {
  final String onayTipi;
  final int onayKayitId;
  final String olusturmaTarihi;
  final String islemTarihi;
  final String onayDurumu;
  final String olusturanKisi;
  final String aciklama;
  final String saticiFirma;
  final int toplamTutar;
  final int satinAlmaAnaKategoriId;
  final int satinAlmaAltKategoriId;
  final String urunKategori;
  final String urunAltKategori;

  const SatinAlmaTalep({
    required this.onayTipi,
    required this.onayKayitId,
    required this.olusturmaTarihi,
    required this.islemTarihi,
    required this.onayDurumu,
    required this.olusturanKisi,
    required this.aciklama,
    required this.saticiFirma,
    required this.toplamTutar,
    required this.satinAlmaAnaKategoriId,
    required this.satinAlmaAltKategoriId,
    required this.urunKategori,
    required this.urunAltKategori,
  });

  factory SatinAlmaTalep.fromJson(Map<String, dynamic> json) {
    return SatinAlmaTalep(
      onayTipi: json['onayTipi']?.toString() ?? '',
      onayKayitId: _parseInt(json['onayKayitId'] ?? json['onayKayitId']),
      olusturmaTarihi: json['olusturmaTarihi']?.toString() ?? '',
      islemTarihi: json['islemTarihi']?.toString() ?? '',
      onayDurumu: json['onayDurumu']?.toString() ?? '',
      olusturanKisi: json['olusturanKisi']?.toString() ?? '',
      aciklama: json['aciklama']?.toString() ?? '',
      saticiFirma: json['saticiFirma']?.toString() ?? '',
      toplamTutar: _parseInt(json['toplamTutar']),
      satinAlmaAnaKategoriId: _parseInt(json['satinAlmaAnaKategoriId']),
      satinAlmaAltKategoriId: _parseInt(json['satinAlmaAltKategoriId']),
      urunKategori: _parseKategori(json),
      urunAltKategori: _parseAltKategori(json),
    );
  }

  static String _parseKategori(Map<String, dynamic> json) {
    return (json['urunKategori'] ?? json['anaKategori'] ?? '').toString();
  }

  static String _parseAltKategori(Map<String, dynamic> json) {
    return (json['urunAltKategori'] ?? json['altKategori'] ?? '').toString();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

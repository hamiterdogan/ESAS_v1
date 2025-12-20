class SatinAlmaAnaKategori {
  final int id;
  final String kategori;
  final bool aktif;

  SatinAlmaAnaKategori({
    required this.id,
    required this.kategori,
    required this.aktif,
  });

  factory SatinAlmaAnaKategori.fromJson(Map<String, dynamic> json) {
    return SatinAlmaAnaKategori(
      id: json['id'] as int,
      kategori: json['kategori'] as String,
      aktif: json['aktif'] as bool,
    );
  }
}

class SatinAlmaAltKategori {
  final int id;
  final int satinAlmaAnaKategoriId;
  final String altKategori;
  final bool aktif;

  SatinAlmaAltKategori({
    required this.id,
    required this.satinAlmaAnaKategoriId,
    required this.altKategori,
    required this.aktif,
  });

  factory SatinAlmaAltKategori.fromJson(Map<String, dynamic> json) {
    return SatinAlmaAltKategori(
      id: json['id'] as int,
      satinAlmaAnaKategoriId: json['satinAlmaAnaKategoriId'] as int,
      altKategori: json['altKategori'] as String,
      aktif: json['aktif'] as bool,
    );
  }
}

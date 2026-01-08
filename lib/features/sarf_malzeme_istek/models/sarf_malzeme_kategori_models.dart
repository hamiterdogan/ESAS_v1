class SarfMalzemeAnaKategori {
  final int id;
  final String kategori;
  final bool aktif;

  const SarfMalzemeAnaKategori({
    required this.id,
    required this.kategori,
    required this.aktif,
  });

  factory SarfMalzemeAnaKategori.fromJson(Map<String, dynamic> json) {
    return SarfMalzemeAnaKategori(
      id: (json['id'] as num?)?.toInt() ?? 0,
      kategori: (json['kategori'] ?? '').toString(),
      aktif: json['aktif'] == true,
    );
  }
}

class SarfMalzemeAnaKategoriResponse {
  final List<SarfMalzemeAnaKategori> temizlik;
  final List<SarfMalzemeAnaKategori> kirtasiye;
  final List<SarfMalzemeAnaKategori> promosyon;
  final List<SarfMalzemeAnaKategori> yiyecek;

  const SarfMalzemeAnaKategoriResponse({
    required this.temizlik,
    required this.kirtasiye,
    required this.promosyon,
    required this.yiyecek,
  });

  factory SarfMalzemeAnaKategoriResponse.fromJson(Map<String, dynamic> json) {
    List<SarfMalzemeAnaKategori> parseList(dynamic value) {
      if (value is! List) return const <SarfMalzemeAnaKategori>[];
      return value
          .whereType<Map>()
          .map(
            (e) =>
                SarfMalzemeAnaKategori.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }

    return SarfMalzemeAnaKategoriResponse(
      temizlik: parseList(json['temizlik']),
      kirtasiye: parseList(json['kirtasiye']),
      promosyon: parseList(json['promosyon']),
      yiyecek: parseList(json['yiyecek']),
    );
  }
}

class SarfMalzemeAltKategori {
  final int id;
  final String altKategori;
  final int anaKategoriId;
  final bool aktif;

  const SarfMalzemeAltKategori({
    required this.id,
    required this.altKategori,
    required this.anaKategoriId,
    required this.aktif,
  });

  factory SarfMalzemeAltKategori.fromJson(Map<String, dynamic> json) {
    return SarfMalzemeAltKategori(
      id: (json['id'] as num?)?.toInt() ?? 0,
      altKategori: (json['altKategori'] ?? '').toString(),
      anaKategoriId: (json['anaKategoriId'] as num?)?.toInt() ?? 0,
      aktif: json['aktif'] == true,
    );
  }
}

class SatinAlmaFiyatGecmisiItem {
  final int id;
  final int satinAlmaId;
  final int personelId;
  final String adSoyad;
  final String sonTeslimTarihi;
  final String saticiFirma;
  final double genelToplam;
  final bool pesin;
  final int? odemeVadesiGun;
  final int odemeSekliId;
  final String odemeSekli;
  final String islemTarihi;

  SatinAlmaFiyatGecmisiItem({
    required this.id,
    required this.satinAlmaId,
    required this.personelId,
    required this.adSoyad,
    required this.sonTeslimTarihi,
    required this.saticiFirma,
    required this.genelToplam,
    required this.pesin,
    this.odemeVadesiGun,
    required this.odemeSekliId,
    required this.odemeSekli,
    required this.islemTarihi,
  });

  factory SatinAlmaFiyatGecmisiItem.fromJson(Map<String, dynamic> json) {
    return SatinAlmaFiyatGecmisiItem(
      id: json['id'] ?? 0,
      satinAlmaId: json['satinAlmaId'] ?? 0,
      personelId: json['personelId'] ?? 0,
      adSoyad: json['adSoyad'] ?? '',
      sonTeslimTarihi: json['sonTeslimTarihi'] ?? '',
      saticiFirma: json['saticiFirma'] ?? '',
      genelToplam: (json['genelToplam'] ?? 0).toDouble(),
      pesin: json['pesin'] ?? false,
      odemeVadesiGun: json['odemeVadesiGun'],
      odemeSekliId: json['odemeSekliId'] ?? 0,
      odemeSekli: json['odemeSekli'] ?? '',
      islemTarihi: json['islemTarihi'] ?? '',
    );
  }
}

class SatinAlmaFiyatGecmisiResponse {
  final List<SatinAlmaFiyatGecmisiItem> fiyatGecmisi;

  SatinAlmaFiyatGecmisiResponse({required this.fiyatGecmisi});

  factory SatinAlmaFiyatGecmisiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['fiyatGecmisi'] as List?;
    List<SatinAlmaFiyatGecmisiItem> itemsList = list != null
        ? list.map((i) => SatinAlmaFiyatGecmisiItem.fromJson(i)).toList()
        : [];
    return SatinAlmaFiyatGecmisiResponse(fiyatGecmisi: itemsList);
  }
}

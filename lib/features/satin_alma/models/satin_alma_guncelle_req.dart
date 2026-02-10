class SatinAlmaGuncelleReq {
  final int satinAlmaId;
  final int? odemeSekliId;
  final int? personelId;
  final bool? pesin;
  final int? odemeVadesiGun;
  final String? saticiFirma;
  final DateTime? sonTeslimTarihi;
  final List<UrunSatirGuncelle> urunSatir;
  final String? saticiTel;
  final String? webSitesi;

  SatinAlmaGuncelleReq({
    required this.satinAlmaId,
    this.odemeSekliId,
    this.personelId,
    this.pesin,
    this.odemeVadesiGun,
    this.saticiFirma,
    this.sonTeslimTarihi,
    required this.urunSatir,
    this.saticiTel,
    this.webSitesi,
  });

  Map<String, dynamic> toJson() {
    return {
      'satinAlmaId': satinAlmaId,
      if (odemeSekliId != null) 'odemeSekliId': odemeSekliId,
      if (personelId != null) 'personelId': personelId,
      if (pesin != null) 'pesin': pesin,
      if (odemeVadesiGun != null) 'odemeVadesiGun': odemeVadesiGun,
      if (saticiFirma != null) 'saticiFirma': saticiFirma,
      if (sonTeslimTarihi != null)
        'sonTeslimTarihi': sonTeslimTarihi!.toIso8601String(),
      'urunSatir': urunSatir.map((e) => e.toJson()).toList(),
      if (saticiTel != null) 'saticiTel': saticiTel,
      if (webSitesi != null) 'webSitesi': webSitesi,
    };
  }
}

class UrunSatirGuncelle {
  final int id;
  final int satinAlmaAnaKategoriId;
  final int satinAlmaAltKategoriId;
  final String urunDetay;
  final int miktar;
  final int birimId;
  final String paraBirimi;
  final String? digerUrun;
  final double birimFiyati;

  UrunSatirGuncelle({
    required this.id,
    required this.satinAlmaAnaKategoriId,
    required this.satinAlmaAltKategoriId,
    required this.urunDetay,
    required this.miktar,
    required this.birimId,
    required this.paraBirimi,
    this.digerUrun,
    required this.birimFiyati,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'satinAlmaAnaKategoriId': satinAlmaAnaKategoriId,
      'satinAlmaAltKategoriId': satinAlmaAltKategoriId,
      'urunDetay': urunDetay,
      'miktar': miktar,
      'birimId': birimId,
      'paraBirimi': paraBirimi,
      if (digerUrun != null) 'digerUrun': digerUrun,
      'birimFiyati': birimFiyati,
    };
  }
}

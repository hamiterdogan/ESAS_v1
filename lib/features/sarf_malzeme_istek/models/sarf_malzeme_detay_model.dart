class SarfMalzemeDetayResponse {
  final int id;
  final int personelId;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevi;
  final String gorevYeri;
  final List<int> binaId;
  final String talebinAmaci;
  final List<SarfMalzemeDetayUrun> urunlerSatir;
  final String? dosyaAdi;
  final String? dosyaAciklama;
  final bool surecTamamlandi;

  SarfMalzemeDetayResponse({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevi,
    required this.gorevYeri,
    required this.binaId,
    required this.talebinAmaci,
    required this.urunlerSatir,
    this.dosyaAdi,
    this.dosyaAciklama,
    required this.surecTamamlandi,
  });

  factory SarfMalzemeDetayResponse.fromJson(Map<String, dynamic> json) {
    return SarfMalzemeDetayResponse(
      id: json['id'] as int,
      personelId: json['personelId'] as int,
      adSoyad: json['adSoyad'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      soyad: json['soyad'] as String? ?? '',
      gorevi: json['gorevi'] as String? ?? '',
      gorevYeri: json['gorevYeri'] as String? ?? '',
      binaId: (json['binaId'] as List?)?.map((e) => e as int).toList() ?? [],
      talebinAmaci: json['talebinAmaci'] as String? ?? '',
      urunlerSatir: (json['urunlerSatir'] as List?)
              ?.map((e) => SarfMalzemeDetayUrun.fromJson(e))
              .toList() ??
          [],
      dosyaAdi: json['dosyaAdi'] as String?,
      dosyaAciklama: json['dosyaAciklama'] as String?,
      surecTamamlandi: json['surecTamamlandi'] as bool? ?? false,
    );
  }
}

class SarfMalzemeDetayUrun {
  final int id;
  final int satinAlmaAnaKategoriId;
  final int? satinAlmaAltKategoriId;
  final String satinAlmaAnaKategori;
  final String? satinAlmaAltKategori;
  final String urunDetay;
  final double miktar;
  final int birimId;

  SarfMalzemeDetayUrun({
    required this.id,
    required this.satinAlmaAnaKategoriId,
    this.satinAlmaAltKategoriId,
    required this.satinAlmaAnaKategori,
    this.satinAlmaAltKategori,
    required this.urunDetay,
    required this.miktar,
    required this.birimId,
  });

  factory SarfMalzemeDetayUrun.fromJson(Map<String, dynamic> json) {
    // Handle miktar which might be int or double
    double parseMiktar(dynamic val) {
      if (val is int) return val.toDouble();
      if (val is double) return val;
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return SarfMalzemeDetayUrun(
      id: json['id'] as int,
      satinAlmaAnaKategoriId: json['satinAlmaAnaKategoriId'] as int,
      satinAlmaAltKategoriId: json['satinAlmaAltKategoriId'] as int?,
      satinAlmaAnaKategori: json['satinAlmaAnaKategori'] as String? ?? '',
      satinAlmaAltKategori: json['satinAlmaAltKategori'] as String?,
      urunDetay: json['urunDetay'] as String? ?? '',
      miktar: parseMiktar(json['miktar']),
      birimId: json['birimId'] as int? ?? 0,
    );
  }
}

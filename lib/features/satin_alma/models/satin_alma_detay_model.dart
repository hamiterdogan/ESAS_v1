class SatinAlmaDetayResponse {
  final int id;
  final int personelId;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevi;
  final String gorevYeri;
  final List<int> binaId;
  final String sonTeslimTarihi;
  final String saticiFirma;
  final String? saticiTel;
  final String? webSitesi;
  final String aliminAmaci;
  final double genelToplam;
  final int odemeSekliId;
  final bool pesin;
  final int odemeVadesiGun;
  final String? dosyaAdi;
  final String? dosyaAciklama;
  final String? muhasebeDosyaAdi;
  final String? fiyatArastirAciklama;
  final bool surecTamamlandi;
  final List<SatinAlmaDetayUrunSatir> urunlerSatir;

  SatinAlmaDetayResponse({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevi,
    required this.gorevYeri,
    required this.binaId,
    required this.sonTeslimTarihi,
    required this.saticiFirma,
    this.saticiTel,
    this.webSitesi,
    required this.aliminAmaci,
    required this.genelToplam,
    required this.odemeSekliId,
    required this.pesin,
    required this.odemeVadesiGun,
    this.dosyaAdi,
    this.dosyaAciklama,
    this.muhasebeDosyaAdi,
    this.fiyatArastirAciklama,
    required this.surecTamamlandi,
    required this.urunlerSatir,
  });

  factory SatinAlmaDetayResponse.fromJson(Map<String, dynamic> json) {
    return SatinAlmaDetayResponse(
      id: _toInt(json['id']),
      personelId: _toInt(json['personelId']),
      adSoyad: json['adSoyad'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      soyad: json['soyad'] as String? ?? '',
      gorevi: json['gorevi'] as String? ?? '',
      gorevYeri: json['gorevYeri'] as String? ?? '',
      binaId: (json['binaId'] as List?)?.map((e) => _toInt(e)).toList() ?? [],
      sonTeslimTarihi: json['sonTeslimTarihi'] as String? ?? '',
      saticiFirma: json['saticiFirma'] as String? ?? '',
      saticiTel: json['saticiTel'] as String?,
      webSitesi: json['webSitesi'] as String?,
      aliminAmaci: json['aliminAmaci'] as String? ?? '',
      genelToplam: (json['genelToplam'] as num?)?.toDouble() ?? 0.0,
      odemeSekliId: _toInt(json['odemeSekliId']),
      pesin: json['pesin'] as bool? ?? false,
      odemeVadesiGun: _toInt(json['odemeVadesiGun']),
      dosyaAdi: json['dosyaAdi'] as String?,
      dosyaAciklama: json['dosyaAciklama'] as String?,
      muhasebeDosyaAdi: json['muhasebeDosyaAdi'] as String?,
      fiyatArastirAciklama: json['fiyatArastirAciklama'] as String?,
      surecTamamlandi: json['surecTamamlandi'] as bool? ?? false,
      urunlerSatir:
          (json['urunlerSatir'] as List?)
              ?.map(
                (e) =>
                    SatinAlmaDetayUrunSatir.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class SatinAlmaDetayUrunSatir {
  final int id;
  final int satinAlmaAnaKategoriId;
  final int satinAlmaAltKategoriId;
  final String satinAlmaAnaKategori;
  final String satinAlmaAltKategori;
  final String urunDetay;
  final int miktar;
  final int birimId;
  final String paraBirimi;
  final String? digerUrun;
  final double birimFiyati;
  final double dovizKuru;

  SatinAlmaDetayUrunSatir({
    required this.id,
    required this.satinAlmaAnaKategoriId,
    required this.satinAlmaAltKategoriId,
    required this.satinAlmaAnaKategori,
    required this.satinAlmaAltKategori,
    required this.urunDetay,
    required this.miktar,
    required this.birimId,
    required this.paraBirimi,
    this.digerUrun,
    required this.birimFiyati,
    required this.dovizKuru,
  });

  factory SatinAlmaDetayUrunSatir.fromJson(Map<String, dynamic> json) {
    return SatinAlmaDetayUrunSatir(
      id: _toInt(json['id']),
      satinAlmaAnaKategoriId: _toInt(json['satinAlmaAnaKategoriId']),
      satinAlmaAltKategoriId: _toInt(json['satinAlmaAltKategoriId']),
      satinAlmaAnaKategori: json['satinAlmaAnaKategori'] as String? ?? '',
      satinAlmaAltKategori: json['satinAlmaAltKategori'] as String? ?? '',
      urunDetay: json['urunDetay'] as String? ?? '',
      miktar: _toInt(json['miktar']),
      birimId: _toInt(json['birimId']),
      paraBirimi: json['paraBirimi'] as String? ?? '',
      digerUrun: json['digerUrun']?.toString(),
      birimFiyati: (json['birimFiyati'] as num?)?.toDouble() ?? 0.0,
      dovizKuru: (json['dovizKuru'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

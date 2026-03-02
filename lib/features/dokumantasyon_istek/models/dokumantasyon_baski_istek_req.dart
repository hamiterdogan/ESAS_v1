class DokumantasyonBaskiIstekReq {
  final DateTime teslimTarihi;
  final int baskiAdedi;
  final String kagitTalebi; // Baskı Boyutu (A3, A4)
  final String dokumanTuru; // İçerik (KTT, Kitapçık vb.)
  final String aciklama;
  final String baskiTuru; // Siyah-Beyaz Baskı veya Renkli Baskı
  final bool onluArkali;
  final bool kopyaElden;
  final List<String>? formFile;
  final String dosyaAciklama;
  final int sayfaSayisi;
  final int toplamSayfa;
  final int ogrenciSayisi;
  final List<OkulSatirItem> okullarSatir;
  final String teslimAlinacakYer;
  final String driveLink;

  // New fields for JSON payload
  final String departman;
  final int paket;
  final bool a4Talebi;

  DokumantasyonBaskiIstekReq({
    required this.teslimTarihi,
    required this.baskiAdedi,
    required this.kagitTalebi,
    required this.dokumanTuru,
    required this.aciklama,
    required this.baskiTuru,
    required this.onluArkali,
    required this.kopyaElden,
    this.formFile,
    required this.dosyaAciklama,
    required this.sayfaSayisi,
    required this.toplamSayfa,
    required this.ogrenciSayisi,
    required this.okullarSatir,
    required this.teslimAlinacakYer,
    this.driveLink = '',
    this.departman = '', // Default to empty based on sample
    this.paket = 0, // Default to 0 based on sample
    this.a4Talebi = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'teslimTarihi': teslimTarihi.toIso8601String(),
      'baskiAdedi': baskiAdedi,
      'kagitTalebi': kagitTalebi,
      'dokumanTuru': dokumanTuru,
      'departman': departman,
      'paket': paket,
      'a4Talebi': a4Talebi,
      'aciklama': aciklama,
      'baskiTuru': baskiTuru,
      'onluArkali': onluArkali,
      'kopyaElden': kopyaElden,
      'sayfaSayisi': sayfaSayisi,
      'toplamSayfa': toplamSayfa,
      'olusturmaTarihi': DateTime.now().toIso8601String(),
      'okullarSatir': okullarSatir.map((e) => e.toJson()).toList(),
      'ogrenciSayisi': ogrenciSayisi,
      'teslimAlinacakYer': teslimAlinacakYer,
      'driveLink': driveLink,
    };
  }
}

class OkulSatirItem {
  final String okulKodu;
  final String sinif;
  final String seviye;
  // Sample shows numara, adi, soyadi as well
  final String numara;
  final String adi;
  final String soyadi;

  OkulSatirItem({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
    this.numara = '',
    this.adi = '',
    this.soyadi = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'okulKodu': okulKodu,
      'sinif': sinif,
      'seviye': seviye,
      'numara': numara,
      'adi': adi,
      'soyadi': soyadi,
    };
  }
}

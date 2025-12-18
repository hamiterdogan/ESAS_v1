import 'dart:io';

class DokumantasyonBaskiIstekReq {
  final DateTime teslimTarihi;
  final int baskiAdedi;
  final String kagitTalebi; // Baskı Boyutu (A3, A4)
  final String dokumanTuru; // İçerik (KTT, Kitapçık vb.)
  final String aciklama;
  final String baskiTuru; // Siyah-Beyaz Baskı veya Renkli Baskı
  final bool onluArkali;
  final bool kopyaElden;
  final List<String>? formFile; // Yüklenen dosyaların isimleri (User spec: isimleri dizi olarak)
  // Note: Actual files might need to be passed separately to the repository for FormData creation
  final String dosyaAciklama;
  final int sayfaSayisi;
  final int toplamSayfa;
  final int ogrenciSayisi;
  final List<OkulSatirItem> okullarSatir;

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
  });

  Map<String, dynamic> toJson() {
    return {
      'TeslimTarihi': teslimTarihi.toIso8601String(),
      'BaskiAdedi': baskiAdedi,
      'kagitTalebi': kagitTalebi,
      'DokumanTuru': dokumanTuru,
      'Aciklama': aciklama,
      'BaskiTuru': baskiTuru,
      'OnluArkali': onluArkali,
      'KopyaElden': kopyaElden,
      'FormFile': formFile,
      'DosyaAciklama': dosyaAciklama,
      'SayfaSayisi': sayfaSayisi,
      'ToplamSayfa': toplamSayfa,
      'OgrenciSayisi': ogrenciSayisi,
      'OkullarSatir': okullarSatir.map((e) => e.toJson()).toList(),
    };
  }
}

class OkulSatirItem {
  final String okulKodu;
  final String sinif;
  final String seviye;

  OkulSatirItem({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
  });

  Map<String, dynamic> toJson() {
    return {
      'okulKodu': okulKodu,
      'sinif': sinif,
      'seviye': seviye,
    };
  }
}

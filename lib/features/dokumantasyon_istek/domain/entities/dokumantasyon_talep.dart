import 'dart:io';

class DokumantasyonTalep {
  final DateTime teslimTarihi;
  final int baskiAdedi;
  final String kagitTalebi;
  final String dokumanTuru;
  final String aciklama;
  final String baskiTuru;
  final bool onluArkali;
  final bool kopyaElden;
  final List<File> files;
  final String dosyaAciklama;
  final int sayfaSayisi;
  final int toplamSayfa;
  final int ogrenciSayisi;
  final List<OkulSatirEntity> okullarSatir;
  final String departman;
  final int paket;
  final bool a4Talebi;

  const DokumantasyonTalep({
    required this.teslimTarihi,
    required this.baskiAdedi,
    required this.kagitTalebi,
    required this.dokumanTuru,
    required this.aciklama,
    required this.baskiTuru,
    required this.onluArkali,
    required this.kopyaElden,
    required this.files,
    required this.dosyaAciklama,
    required this.sayfaSayisi,
    required this.toplamSayfa,
    required this.ogrenciSayisi,
    required this.okullarSatir,
    required this.departman,
    required this.paket,
    required this.a4Talebi,
  });
}

class OkulSatirEntity {
  final String okulKodu;
  final String sinif;
  final String seviye;
  final int numara;
  final String adi;
  final String soyadi;

  const OkulSatirEntity({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
    this.numara = 0,
    this.adi = '',
    this.soyadi = '',
  });
}

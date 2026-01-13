import 'dart:io';

class SatinAlmaTalep {
  final List<File> files;
  final bool pesin;
  final DateTime sonTeslimTarihi;
  final String aliminAmaci;
  final int odemeSekliId;
  final String webSitesi;
  final String saticiTel;
  final List<int> binaId;
  final int odemeVadesiGun;
  final List<SatinAlmaUrunSatirEntity> urunSatirlar;
  final String saticiFirma;
  final double genelToplam;
  final String dosyaAciklama;

  const SatinAlmaTalep({
    required this.files,
    required this.pesin,
    required this.sonTeslimTarihi,
    required this.aliminAmaci,
    required this.odemeSekliId,
    required this.webSitesi,
    required this.saticiTel,
    required this.binaId,
    required this.odemeVadesiGun,
    required this.urunSatirlar,
    required this.saticiFirma,
    required this.genelToplam,
    required this.dosyaAciklama,
  });
}

class SatinAlmaUrunSatirEntity {
  final int? satinAlmaAltKategoriId;
  final String digerUrun;
  final int? birimId;
  final int? satinAlmaAnaKategoriId;
  final double birimFiyati;
  final String urunDetay;
  final int miktar;
  final String? paraBirimi;

  const SatinAlmaUrunSatirEntity({
    this.satinAlmaAltKategoriId,
    this.digerUrun = '',
    this.birimId,
    this.satinAlmaAnaKategoriId,
    this.birimFiyati = 0,
    required this.urunDetay,
    required this.miktar,
    this.paraBirimi,
  });
}

import 'package:file_picker/file_picker.dart';

class SatinAlmaEkleReq {
  final List<PlatformFile> formFiles;
  final bool pesin;
  final DateTime sonTeslimTarihi;
  final String aliminAmaci;
  final int odemeSekliId;
  final String webSitesi;
  final String saticiTel;
  final List<int> binaIds;
  final int odemeVadesiGun;
  final List<SatinAlmaUrunSatir> urunSatirlar;
  final String saticiFirma;
  final double genelToplam;
  final String dosyaAciklama;

  SatinAlmaEkleReq({
    required this.formFiles,
    required this.pesin,
    required this.sonTeslimTarihi,
    required this.aliminAmaci,
    required this.odemeSekliId,
    required this.webSitesi,
    required this.saticiTel,
    required this.binaIds,
    required this.odemeVadesiGun,
    required this.urunSatirlar,
    required this.saticiFirma,
    required this.genelToplam,
    required this.dosyaAciklama,
  });

  Map<String, dynamic> toJson() {
    return {
      'pesin': pesin,
      'sonTeslimTarihi': sonTeslimTarihi.toIso8601String(),
      'aliminAmaci': aliminAmaci,
      'odemeSekliId': odemeSekliId,
      'webSitesi': webSitesi,
      'saticiTel': saticiTel,
      'binaIds': binaIds,
      'odemeVadesiGun': odemeVadesiGun,
      'urunSatir': urunSatirlar.map((u) => u.toJson()).toList(),
      'saticiFirma': saticiFirma,
      'genelToplam': genelToplam,
      'dosyaAciklama': dosyaAciklama,
      'formFiles': formFiles
          .map((file) => {'name': file.name, 'size': file.size})
          .toList(),
    };
  }
}

class SatinAlmaUrunSatir {
  final int? satinAlmaAltKategoriId;
  final String digerUrun;
  final int? birimId;
  final int? satinAlmaAnaKategoriId;
  final double birimFiyati;
  final String urunDetay;
  final int miktar;
  final String?
  paraBirimi; // ID as string per instructions/curl ambiguity, likely ID
  final int id; // 0 for new

  SatinAlmaUrunSatir({
    this.satinAlmaAltKategoriId,
    this.digerUrun = '',
    this.birimId,
    this.satinAlmaAnaKategoriId,
    required this.birimFiyati,
    required this.urunDetay,
    required this.miktar,
    this.paraBirimi,
    this.id = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'satinAlmaAltKategoriId': satinAlmaAltKategoriId ?? 0,
      'digerUrun': digerUrun,
      'birimId': birimId ?? 0,
      'satinAlmaAnaKategoriId': satinAlmaAnaKategoriId ?? 0,
      'birimFiyati': birimFiyati,
      'urunDetay': urunDetay,
      'miktar': miktar,
      'paraBirimi': paraBirimi,
      'id': id,
    };
  }
}

import 'package:file_picker/file_picker.dart';

class SatinAlmaEkleReq {
  final List<PlatformFile> formFiles;
  final bool pesin;
  final DateTime sonTeslimTarihi;
  final String aliminAmaci;
  final int odemeSekliId;
  final String webSitesi;
  final String saticiTel;
  final List<int> binaId;
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
    required this.binaId,
    required this.odemeVadesiGun,
    required this.urunSatirlar,
    required this.saticiFirma,
    required this.genelToplam,
    required this.dosyaAciklama,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'binaId': binaId,
      'sonTeslimTarihi': sonTeslimTarihi.toIso8601String(),
      'aliminAmaci': aliminAmaci,
      'genelToplam': genelToplam,
      'urunSatir': urunSatirlar.map((u) => u.toJson()).toList(),
      'odemeSekliId': odemeSekliId,
      'pesin': pesin,
      'odemeVadesiGun': odemeVadesiGun,
    };

    // Optional: Satıcı Firma
    if (saticiFirma.isNotEmpty) {
      map['saticiFirma'] = saticiFirma;
    }

    // Optional: Satıcı Tel
    if (saticiTel.isNotEmpty) {
      map['saticiTel'] = saticiTel;
    }

    // Optional: Web Sitesi
    if (webSitesi.isNotEmpty) {
      map['webSitesi'] = webSitesi;
    }

    return map;
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
    final map = <String, dynamic>{
      'satinAlmaAnaKategoriId': satinAlmaAnaKategoriId ?? 0,
      'satinAlmaAltKategoriId': satinAlmaAltKategoriId ?? 0,
      'urunDetay': urunDetay,
      'miktar': miktar,
      'birimId': birimId ?? 0,
      'birimFiyati': birimFiyati,
    };

    // Optional: Para Birimi (Kod - BirimAdi değil)
    if (paraBirimi != null && paraBirimi!.isNotEmpty) {
      map['paraBirimi'] = paraBirimi;
    }

    return map;
  }
}

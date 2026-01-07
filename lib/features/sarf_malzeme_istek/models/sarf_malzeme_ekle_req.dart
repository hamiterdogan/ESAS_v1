import 'package:file_picker/file_picker.dart';

class SarfMalzemeEkleReq {
  final List<int> binaId;
  final String talebinAmaci;
  final String talepTuru;
  final List<SarfMalzemeUrunSatir> urunSatir;
  // Included for file upload logic after creation, though not part of the initial JSON body
  final List<PlatformFile> formFiles;
  final String dosyaAciklama;

  SarfMalzemeEkleReq({
    required this.binaId,
    required this.talebinAmaci,
    required this.talepTuru,
    required this.urunSatir,
    this.formFiles = const [],
    this.dosyaAciklama = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'binaId': binaId,
      'talebinAmaci': talebinAmaci,
      'talepTuru': talepTuru,
      'urunSatir': urunSatir.map((e) => e.toJson()).toList(),
    };
  }
}

class SarfMalzemeUrunSatir {
  final int id;
  final int satinAlmaAnaKategoriId;
  final int? satinAlmaAltKategoriId;
  final String urunDetay;
  final int miktar;
  final int birimId;

  SarfMalzemeUrunSatir({
    this.id = 0,
    required this.satinAlmaAnaKategoriId,
    this.satinAlmaAltKategoriId,
    required this.urunDetay,
    required this.miktar,
    required this.birimId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'satinAlmaAnaKategoriId': satinAlmaAnaKategoriId,
      'satinAlmaAltKategoriId': satinAlmaAltKategoriId ?? 0,
      'urunDetay': urunDetay,
      'miktar': miktar,
      'birimId': birimId,
    };
  }
}

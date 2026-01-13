import 'package:dio/dio.dart';
import 'package:esas_v1/features/dokumantasyon_istek/domain/entities/dokumantasyon_talep.dart';

class DokumantasyonTalepModel extends DokumantasyonTalep {
  const DokumantasyonTalepModel({
    required super.teslimTarihi,
    required super.baskiAdedi,
    required super.kagitTalebi,
    required super.dokumanTuru,
    required super.aciklama,
    required super.baskiTuru,
    required super.onluArkali,
    required super.kopyaElden,
    required super.files,
    required super.dosyaAciklama,
    required super.sayfaSayisi,
    required super.toplamSayfa,
    required super.ogrenciSayisi,
    required super.okullarSatir,
    required super.departman,
    required super.paket,
    required super.a4Talebi,
  });

  factory DokumantasyonTalepModel.fromEntity(DokumantasyonTalep entity) {
    return DokumantasyonTalepModel(
      teslimTarihi: entity.teslimTarihi,
      baskiAdedi: entity.baskiAdedi,
      kagitTalebi: entity.kagitTalebi,
      dokumanTuru: entity.dokumanTuru,
      aciklama: entity.aciklama,
      baskiTuru: entity.baskiTuru,
      onluArkali: entity.onluArkali,
      kopyaElden: entity.kopyaElden,
      files: entity.files,
      dosyaAciklama: entity.dosyaAciklama,
      sayfaSayisi: entity.sayfaSayisi,
      toplamSayfa: entity.toplamSayfa,
      ogrenciSayisi: entity.ogrenciSayisi,
      okullarSatir: entity.okullarSatir,
      departman: entity.departman,
      paket: entity.paket,
      a4Talebi: entity.a4Talebi,
    );
  }

  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
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
      'ogrenciSayisi': ogrenciSayisi,
      'dosyaAciklama': dosyaAciklama,
    };

    final formData = FormData.fromMap(map);

    // Files
    for (var file in files) {
       String fileName = file.path.split('/').last;
       formData.files.add(MapEntry(
         'formFile', 
         await MultipartFile.fromFile(file.path, filename: fileName),
       ));
    }
    
    // Nested Data (okullarSatir)
    // Assuming backend handles indexed fields 
    for (int i = 0; i < okullarSatir.length; i++) {
        final item = okullarSatir[i];
        formData.fields.add(MapEntry('okullarSatir[$i].okulKodu', item.okulKodu));
        formData.fields.add(MapEntry('okullarSatir[$i].sinif', item.sinif));
        formData.fields.add(MapEntry('okullarSatir[$i].seviye', item.seviye));
        formData.fields.add(MapEntry('okullarSatir[$i].numara', item.numara.toString()));
        formData.fields.add(MapEntry('okullarSatir[$i].adi', item.adi));
        formData.fields.add(MapEntry('okullarSatir[$i].soyadi', item.soyadi));
    }

    return formData;
  }
}

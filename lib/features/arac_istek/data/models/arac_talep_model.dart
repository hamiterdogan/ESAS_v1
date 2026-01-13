import 'package:esas_v1/features/arac_istek/domain/entities/arac_talep.dart';

class AracTalepModel extends AracTalep {
  const AracTalepModel({
    required super.personelId,
    required super.gidilecekTarih,
    required super.gidisSaat,
    required super.gidisDakika,
    required super.donusSaat,
    required super.donusDakika,
    required super.aracTuru,
    required super.yolcuPersonelSatir,
    required super.yolcuDepartmanId,
    required super.okullarSatir,
    required super.gidilecekYerSatir,
    required super.yolcuSayisi,
    required super.mesafe,
    required super.istekNedeni,
    required super.istekNedeniDiger,
    required super.aciklama,
    required super.tasinacakYuk,
    required super.meb,
  });

  factory AracTalepModel.fromEntity(AracTalep entity) {
    return AracTalepModel(
      personelId: entity.personelId,
      gidilecekTarih: entity.gidilecekTarih,
      gidisSaat: entity.gidisSaat,
      gidisDakika: entity.gidisDakika,
      donusSaat: entity.donusSaat,
      donusDakika: entity.donusDakika,
      aracTuru: entity.aracTuru,
      yolcuPersonelSatir: entity.yolcuPersonelSatir,
      yolcuDepartmanId: entity.yolcuDepartmanId,
      okullarSatir: entity.okullarSatir,
      gidilecekYerSatir: entity.gidilecekYerSatir,
      yolcuSayisi: entity.yolcuSayisi,
      mesafe: entity.mesafe,
      istekNedeni: entity.istekNedeni,
      istekNedeniDiger: entity.istekNedeniDiger,
      aciklama: entity.aciklama,
      tasinacakYuk: entity.tasinacakYuk,
      meb: entity.meb,
    );
  }

  Map<String, dynamic> toJson() {
    String formatDate(DateTime date) => date.toUtc().toIso8601String();

    return {
      'personelId': personelId,
      'gidilecekTarih': formatDate(gidilecekTarih),
      'gidisSaat': gidisSaat,
      'gidisDakika': gidisDakika,
      'donusSaat': donusSaat,
      'donusDakika': donusDakika,
      'aracTuru': aracTuru,
      'yolcuPersonelSatir': yolcuPersonelSatir.map((e) => {
        'personelId': e.personelId,
        'perAdi': e.perAdi,
        'gorevi': e.gorevi,
        'gorevYeri': e.gorevYeri,
      }).toList(),
      'yolcuDepartmanId': yolcuDepartmanId,
      'okullarSatir': okullarSatir.map((e) => {
        'okulKodu': e.okulKodu,
        'sinif': e.sinif,
        'seviye': e.seviye,
        'numara': e.numara,
        'adi': e.adi,
        'soyadi': e.soyadi,
      }).toList(),
      'gidilecekYerSatir': gidilecekYerSatir.map((e) => {
        'gidilecekYer': e.gidilecekYer,
        'semt': e.semt,
      }).toList(),
      'yolcuSayisi': yolcuSayisi,
      'mesafe': mesafe,
      'istekNedeni': istekNedeni,
      'istekNedeniDiger': istekNedeniDiger,
      'aciklama': aciklama,
      'tasinacakYuk': tasinacakYuk,
      'meb': meb,
    };
  }
}

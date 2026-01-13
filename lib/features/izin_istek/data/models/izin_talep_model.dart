import 'package:esas_v1/features/izin_istek/domain/entities/izin_talep.dart';

class IzinTalepModel extends IzinTalep {
  const IzinTalepModel({
    required super.izinSebebiId,
    required super.izinBaslangicTarihi,
    required super.izinBitisTarihi,
    required super.aciklama,
    required super.izindeBulunacagiAdres,
    super.doktorRaporu,
    super.izinBaslangicSaat,
    super.izinBaslangicDakika,
    super.izinBitisSaat,
    super.izinBitisDakika,
    super.hesaplananIzinGunu,
    super.hesaplananIzinSaati,
    super.izindeGirilmeyenToplamDersSaati,
    super.telefon,
    super.adSoyad,
    super.baskaPersonelId,
    super.dolduranPersonelId,
    super.diniGun,
    super.dogumTarihi,
    super.evlilikTarihi,
    super.esAdi,
  });

  factory IzinTalepModel.fromEntity(IzinTalep entity) {
    return IzinTalepModel(
      izinSebebiId: entity.izinSebebiId,
      izinBaslangicTarihi: entity.izinBaslangicTarihi,
      izinBitisTarihi: entity.izinBitisTarihi,
      aciklama: entity.aciklama,
      izindeBulunacagiAdres: entity.izindeBulunacagiAdres,
      doktorRaporu: entity.doktorRaporu,
      izinBaslangicSaat: entity.izinBaslangicSaat,
      izinBaslangicDakika: entity.izinBaslangicDakika,
      izinBitisSaat: entity.izinBitisSaat,
      izinBitisDakika: entity.izinBitisDakika,
      hesaplananIzinGunu: entity.hesaplananIzinGunu,
      hesaplananIzinSaati: entity.hesaplananIzinSaati,
      izindeGirilmeyenToplamDersSaati: entity.izindeGirilmeyenToplamDersSaati,
      telefon: entity.telefon,
      adSoyad: entity.adSoyad,
      baskaPersonelId: entity.baskaPersonelId,
      dolduranPersonelId: entity.dolduranPersonelId,
      diniGun: entity.diniGun,
      dogumTarihi: entity.dogumTarihi,
      evlilikTarihi: entity.evlilikTarihi,
      esAdi: entity.esAdi,
    );
  }

 Map<String, dynamic> toJson() {
    String formatDate(DateTime date) {
      return date.toUtc().toIso8601String();
    }

    final Map<String, dynamic> baseData = {
      'IzinSebebiId': izinSebebiId,
      'IzinBaslangicTarihi': formatDate(izinBaslangicTarihi),
      'IzinBitisTarihi': formatDate(izinBitisTarihi),
      'Aciklama': aciklama,
      'IzindeBulunacagiAdres': izindeBulunacagiAdres,
      'IzindeGirilmeyenToplamDersSaati': izindeGirilmeyenToplamDersSaati ?? 0,
      'BaskaPersonelId': baskaPersonelId ?? 0,
      'DolduranPersonelId': dolduranPersonelId ?? 0,
      'DoktorRaporu': izinSebebiId == 4 ? (doktorRaporu ?? false) : false,
      'FormFile': '',
      'FilePath': '',
      'DosyaAciklama': '',
      'DiniGun': diniGun ?? '',
      'Hastalik': '',
      'EsAdi': esAdi ?? '',
      'EvlilikTarihi': evlilikTarihi != null
          ? formatDate(evlilikTarihi!)
          : formatDate(DateTime.now()),
      'DogumTarihi': dogumTarihi != null
          ? formatDate(dogumTarihi!)
          : formatDate(DateTime.now()),
    };

    // simplified switch, logic copied from request model
    final extraData = <String, dynamic>{
        'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
        'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
        'IzinBitisSaat': izinBitisSaat ?? 17,
        'IzinBitisDakika': izinBitisDakika ?? 30,
    };
    
    return {...baseData, ...extraData};
  }
}

class IzinTalep {
  final int izinSebebiId;
  final DateTime izinBaslangicTarihi;
  final DateTime izinBitisTarihi;
  final String aciklama;
  final String izindeBulunacagiAdres;
  final bool? doktorRaporu;
  final int? izinBaslangicSaat;
  final int? izinBaslangicDakika;
  final int? izinBitisSaat;
  final int? izinBitisDakika;
  final int? hesaplananIzinGunu;
  final int? hesaplananIzinSaati;
  final int? izindeGirilmeyenToplamDersSaati;
  final String? telefon;
  final String? adSoyad;
  final int? baskaPersonelId;
  final int? dolduranPersonelId;
  final String? diniGun;
  final DateTime? dogumTarihi;
  final DateTime? evlilikTarihi;
  final String? esAdi;

  const IzinTalep({
    required this.izinSebebiId,
    required this.izinBaslangicTarihi,
    required this.izinBitisTarihi,
    required this.aciklama,
    required this.izindeBulunacagiAdres,
    this.doktorRaporu,
    this.izinBaslangicSaat,
    this.izinBaslangicDakika,
    this.izinBitisSaat,
    this.izinBitisDakika,
    this.hesaplananIzinGunu,
    this.hesaplananIzinSaati,
    this.izindeGirilmeyenToplamDersSaati,
    this.telefon,
    this.adSoyad,
    this.baskaPersonelId,
    this.dolduranPersonelId,
    this.diniGun,
    this.dogumTarihi,
    this.evlilikTarihi,
    this.esAdi,
  });
}

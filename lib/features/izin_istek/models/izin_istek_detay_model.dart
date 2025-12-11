class IzinIstekDetayResponse {
  final int id;
  final int personelId;
  final bool doktorRaporu;
  final DateTime izinBaslangicTarihi;
  final String izinBaslangicSaati;
  final DateTime izinBitisTarihi;
  final String izinBitisSaati;
  final DateTime? evlilikTarihi;
  final DateTime? dogumTarihi;
  final int? hesaplananIzinGunu;
  final int hesaplananIzinSaati;
  final String? hesaplananSaatDakika;
  final int? izindeGirilmeyenToplamDersSaati;
  final String izindeBulunacagiAdres;
  final String aciklama;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevYeri;
  final String gorevi;
  final int baskaPersonelId;
  final int izinSebebiId;
  final String izinSebebi;
  final String? dosyaAdi;
  final String? dosyaAciklama;
  final String? departman;
  final String? diniGun;
  final String? esAdi;
  final String? tcKimlik;
  final String? telefon;
  final String? hastalik;

  IzinIstekDetayResponse({
    required this.id,
    required this.personelId,
    required this.doktorRaporu,
    required this.izinBaslangicTarihi,
    required this.izinBaslangicSaati,
    required this.izinBitisTarihi,
    required this.izinBitisSaati,
    this.evlilikTarihi,
    this.dogumTarihi,
    this.hesaplananIzinGunu,
    required this.hesaplananIzinSaati,
    this.hesaplananSaatDakika,
    this.izindeGirilmeyenToplamDersSaati,
    required this.izindeBulunacagiAdres,
    required this.aciklama,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevYeri,
    required this.gorevi,
    required this.baskaPersonelId,
    required this.izinSebebiId,
    required this.izinSebebi,
    this.dosyaAdi,
    this.dosyaAciklama,
    this.departman,
    this.diniGun,
    this.esAdi,
    this.tcKimlik,
    this.telefon,
    this.hastalik,
  });

  factory IzinIstekDetayResponse.fromJson(Map<String, dynamic> json) {
    return IzinIstekDetayResponse(
      id: json['id'] as int? ?? 0,
      personelId: json['personelId'] as int? ?? 0,
      doktorRaporu: json['doktorRaporu'] as bool? ?? false,
      izinBaslangicTarihi: DateTime.parse(
        json['izinBaslangicTarihi'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      izinBaslangicSaati: json['izinBaslangicSaati'] as String? ?? '00:00:00',
      izinBitisTarihi: DateTime.parse(
        json['izinBitisTarihi'] as String? ?? DateTime.now().toIso8601String(),
      ),
      izinBitisSaati: json['izinBitisSaati'] as String? ?? '00:00:00',
      evlilikTarihi: json['evlilikTarihi'] != null
          ? DateTime.parse(json['evlilikTarihi'] as String)
          : null,
      dogumTarihi: json['dogumTarihi'] != null
          ? DateTime.parse(json['dogumTarihi'] as String)
          : null,
      hesaplananIzinGunu: json['hesaplananIzinGunu'] as int?,
      hesaplananIzinSaati: json['hesaplananIzinSaati'] as int? ?? 0,
      hesaplananSaatDakika: json['hesaplananSaatDakika'] as String?,
      izindeGirilmeyenToplamDersSaati:
          json['izindeGirilmeyenToplamDersSaati'] as int?,
      izindeBulunacagiAdres: json['izindeBulunacagiAdres'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      adSoyad: json['adSoyad'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      soyad: json['soyad'] as String? ?? '',
      gorevYeri: json['gorevYeri'] as String? ?? '',
      gorevi: json['gorevi'] as String? ?? '',
      baskaPersonelId: json['baskaPersonelId'] as int? ?? 0,
      izinSebebiId: json['izinSebebiId'] as int? ?? 0,
      izinSebebi: json['izinSebebi'] as String? ?? '',
      dosyaAdi: json['dosyaAdi'] as String?,
      dosyaAciklama: json['dosyaAciklama'] as String?,
      departman: json['departman'] as String?,
      diniGun: json['diniGun'] as String?,
      esAdi: json['esAdi'] as String?,
      tcKimlik: json['tcKimlik'] as String?,
      telefon: json['telefon'] as String?,
      hastalik: json['hastalik'] as String?,
    );
  }
}

// ===========================
// İZİN SEBEBİ (DROPDOWN İÇİN)
// ===========================
class IzinSebebi {
  final int izinSebebiId;
  final String izinNedeni;
  final int izinKacGunSonraBaslayacak;
  final bool saatGoster; // true: saat/dakika göster, false: sadece gün

  const IzinSebebi({
    required this.izinSebebiId,
    required this.izinNedeni,
    required this.izinKacGunSonraBaslayacak,
    required this.saatGoster,
  });

  factory IzinSebebi.fromJson(Map<String, dynamic> json) {
    return IzinSebebi(
      izinSebebiId: json['izinSebebiId'] as int,
      izinNedeni: json['izinNedeni'] as String,
      izinKacGunSonraBaslayacak: json['izinKacGunSonraBaslayacak'] as int,
      saatGoster: json['saatGoster'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'izinSebebiId': izinSebebiId,
      'izinNedeni': izinNedeni,
      'izinKacGunSonraBaslayacak': izinKacGunSonraBaslayacak,
      'saatGoster': saatGoster,
    };
  }
}

// ===========================
// DİNİ GÜN (DROPDOWN İÇİN)
// ===========================
class DiniGun {
  final String izinGunu;

  const DiniGun({required this.izinGunu});

  factory DiniGun.fromJson(Map<String, dynamic> json) {
    return DiniGun(izinGunu: json['izinGunu'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'izinGunu': izinGunu};
  }
}

// ===========================
// İZİN İSTEK EKLEME (POST REQUEST)
// ===========================
class IzinIstekEkleRequest {
  final int izinSebebiId;
  final bool doktorRaporu;
  final DateTime izinBaslangicTarihi;
  final int izinBaslangicSaat;
  final int izinBaslangicDakika;
  final DateTime izinBitisTarihi;
  final int izinBitisSaat;
  final int izinBitisDakika;
  final DateTime? evlilikTarihi; // Evlenme izni için
  final DateTime? dogumTarihi; // Doğum izni için
  final int hesaplananIzinGunu;
  final int hesaplananIzinSaati;
  final int izindeGirilmeyenToplamDersSaati;
  final String izindeBulunacagiAdres;
  final String telefon;
  final String aciklama;
  final String adSoyad;
  final int baskaPersonelId;
  final int dolduranPersonelId;
  final String? filePath; // Dosya yolu (doktor raporu vb.)
  final String? dosyaAciklama;
  final String? izinGunu; // Hesaplanan gün sayısı (string olarak)
  final String? diniGun; // Seçilen dini gün
  final String? esAdi; // Evlilik için eş adı
  final String? hastalik; // Hastalık açıklaması

  const IzinIstekEkleRequest({
    required this.izinSebebiId,
    required this.doktorRaporu,
    required this.izinBaslangicTarihi,
    required this.izinBaslangicSaat,
    required this.izinBaslangicDakika,
    required this.izinBitisTarihi,
    required this.izinBitisSaat,
    required this.izinBitisDakika,
    this.evlilikTarihi,
    this.dogumTarihi,
    required this.hesaplananIzinGunu,
    required this.hesaplananIzinSaati,
    required this.izindeGirilmeyenToplamDersSaati,
    required this.izindeBulunacagiAdres,
    required this.telefon,
    required this.aciklama,
    required this.adSoyad,
    required this.baskaPersonelId,
    required this.dolduranPersonelId,
    this.filePath,
    this.dosyaAciklama,
    this.izinGunu,
    this.diniGun,
    this.esAdi,
    this.hastalik,
  });

  Map<String, dynamic> toJson() {
    return {
      'izinSebebiId': izinSebebiId,
      'doktorRaporu': doktorRaporu,
      'izinBaslangicTarihi': izinBaslangicTarihi.toIso8601String(),
      'izinBaslangicSaat': izinBaslangicSaat,
      'izinBaslangicDakika': izinBaslangicDakika,
      'izinBitisTarihi': izinBitisTarihi.toIso8601String(),
      'izinBitisSaat': izinBitisSaat,
      'izinBitisDakika': izinBitisDakika,
      'evlilikTarihi': evlilikTarihi?.toIso8601String(),
      'dogumTarihi': dogumTarihi?.toIso8601String(),
      'hesaplananIzinGunu': hesaplananIzinGunu,
      'hesaplananIzinSaati': hesaplananIzinSaati,
      'izindeGirilmeyenToplamDersSaati': izindeGirilmeyenToplamDersSaati,
      'izindeBulunacagiAdres': izindeBulunacagiAdres,
      'telefon': telefon,
      'aciklama': aciklama,
      'adSoyad': adSoyad,
      'baskaPersonelId': baskaPersonelId,
      'dolduranPersonelId': dolduranPersonelId,
      'filePath': filePath,
      'dosyaAciklama': dosyaAciklama,
      'izinGunu': izinGunu,
      'diniGun': diniGun,
      'esAdi': esAdi,
      'hastalik': hastalik,
    };
  }
}

// ===========================
// İZİN İSTEK DETAY (GET RESPONSE)
// ===========================
class IzinIstekDetay {
  final int id;
  final int personelId;
  final bool doktorRaporu;
  final DateTime izinBaslangicTarihi;
  final String izinBaslangicSaati; // "08:00:00"
  final DateTime izinBitisTarihi;
  final String izinBitisSaati; // "16:00:00"
  final DateTime? evlilikTarihi;
  final DateTime? dogumTarihi;
  final int hesaplananIzinGunu;
  final int hesaplananIzinSaati;
  final String? hesaplananSaatDakika;
  final int izindeGirilmeyenToplamDersSaati;
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
  final String departman;
  final String? diniGun;
  final String? esAdi;
  final String? tcKimlik;
  final String? telefon;
  final String? hastalik;

  const IzinIstekDetay({
    required this.id,
    required this.personelId,
    required this.doktorRaporu,
    required this.izinBaslangicTarihi,
    required this.izinBaslangicSaati,
    required this.izinBitisTarihi,
    required this.izinBitisSaati,
    this.evlilikTarihi,
    this.dogumTarihi,
    required this.hesaplananIzinGunu,
    required this.hesaplananIzinSaati,
    this.hesaplananSaatDakika,
    required this.izindeGirilmeyenToplamDersSaati,
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
    required this.departman,
    this.diniGun,
    this.esAdi,
    this.tcKimlik,
    this.telefon,
    this.hastalik,
  });

  factory IzinIstekDetay.fromJson(Map<String, dynamic> json) {
    return IzinIstekDetay(
      id: json['id'] as int,
      personelId: json['personelId'] as int,
      doktorRaporu: json['doktorRaporu'] as bool,
      izinBaslangicTarihi: DateTime.parse(
        json['izinBaslangicTarihi'] as String,
      ),
      izinBaslangicSaati: json['izinBaslangicSaati'] as String,
      izinBitisTarihi: DateTime.parse(json['izinBitisTarihi'] as String),
      izinBitisSaati: json['izinBitisSaati'] as String,
      evlilikTarihi: json['evlilikTarihi'] != null
          ? DateTime.parse(json['evlilikTarihi'] as String)
          : null,
      dogumTarihi: json['dogumTarihi'] != null
          ? DateTime.parse(json['dogumTarihi'] as String)
          : null,
      hesaplananIzinGunu: json['hesaplananIzinGunu'] as int,
      hesaplananIzinSaati: json['hesaplananIzinSaati'] as int,
      hesaplananSaatDakika: json['hesaplananSaatDakika'] as String?,
      izindeGirilmeyenToplamDersSaati:
          json['izindeGirilmeyenToplamDersSaati'] as int,
      izindeBulunacagiAdres: json['izindeBulunacagiAdres'] as String,
      aciklama: json['aciklama'] as String,
      adSoyad: json['adSoyad'] as String,
      ad: json['ad'] as String,
      soyad: json['soyad'] as String,
      gorevYeri: json['gorevYeri'] as String,
      gorevi: json['gorevi'] as String,
      baskaPersonelId: json['baskaPersonelId'] as int,
      izinSebebiId: json['izinSebebiId'] as int,
      izinSebebi: json['izinSebebi'] as String,
      dosyaAdi: json['dosyaAdi'] as String?,
      dosyaAciklama: json['dosyaAciklama'] as String?,
      departman: json['departman'] as String,
      diniGun: json['diniGun'] as String?,
      esAdi: json['esAdi'] as String?,
      tcKimlik: json['tcKimlik'] as String?,
      telefon: json['telefon'] as String?,
      hastalik: json['hastalik'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personelId': personelId,
      'doktorRaporu': doktorRaporu,
      'izinBaslangicTarihi': izinBaslangicTarihi.toIso8601String(),
      'izinBaslangicSaati': izinBaslangicSaati,
      'izinBitisTarihi': izinBitisTarihi.toIso8601String(),
      'izinBitisSaati': izinBitisSaati,
      'evlilikTarihi': evlilikTarihi?.toIso8601String(),
      'dogumTarihi': dogumTarihi?.toIso8601String(),
      'hesaplananIzinGunu': hesaplananIzinGunu,
      'hesaplananIzinSaati': hesaplananIzinSaati,
      'hesaplananSaatDakika': hesaplananSaatDakika,
      'izindeGirilmeyenToplamDersSaati': izindeGirilmeyenToplamDersSaati,
      'izindeBulunacagiAdres': izindeBulunacagiAdres,
      'aciklama': aciklama,
      'adSoyad': adSoyad,
      'ad': ad,
      'soyad': soyad,
      'gorevYeri': gorevYeri,
      'gorevi': gorevi,
      'baskaPersonelId': baskaPersonelId,
      'izinSebebiId': izinSebebiId,
      'izinSebebi': izinSebebi,
      'dosyaAdi': dosyaAdi,
      'dosyaAciklama': dosyaAciklama,
      'departman': departman,
      'diniGun': diniGun,
      'esAdi': esAdi,
      'tcKimlik': tcKimlik,
      'telefon': telefon,
      'hastalik': hastalik,
    };
  }
}

// ===========================
// BAŞARI RESPONSE (SİLME İÇİN)
// ===========================
class IzinIstekSilResponse {
  final bool basarili;

  const IzinIstekSilResponse({required this.basarili});

  factory IzinIstekSilResponse.fromJson(Map<String, dynamic> json) {
    return IzinIstekSilResponse(basarili: json['basarili'] as bool);
  }

  Map<String, dynamic> toJson() {
    return {'basarili': basarili};
  }
}

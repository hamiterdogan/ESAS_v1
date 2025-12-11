class IzinIstekEkleReq {
  final int izinSebebiId;
  final DateTime izinBaslangicTarihi;
  final DateTime izinBitisTarihi;
  final String aciklama;
  final String izindeBulunacagiAdres;

  // Opsiyonel alanlar
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

  IzinIstekEkleReq({
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

  factory IzinIstekEkleReq.fromJson(Map<String, dynamic> json) {
    return IzinIstekEkleReq(
      izinSebebiId: json['izinSebebiId'] as int? ?? 0,
      izinBaslangicTarihi: json['izinBaslangicTarihi'] != null
          ? DateTime.tryParse(json['izinBaslangicTarihi'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      izinBitisTarihi: json['izinBitisTarihi'] != null
          ? DateTime.tryParse(json['izinBitisTarihi'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      aciklama: json['aciklama'] as String? ?? '',
      izindeBulunacagiAdres: json['izindeBulunacagiAdres'] as String? ?? '',
      doktorRaporu: json['doktorRaporu'] as bool?,
      izinBaslangicSaat: json['izinBaslangicSaat'] as int?,
      izinBaslangicDakika: json['izinBaslangicDakika'] as int?,
      izinBitisSaat: json['izinBitisSaat'] as int?,
      izinBitisDakika: json['izinBitisDakika'] as int?,
      hesaplananIzinGunu: json['hesaplananIzinGunu'] as int?,
      hesaplananIzinSaati: json['hesaplananIzinSaati'] as int?,
      izindeGirilmeyenToplamDersSaati:
          json['izindeGirilmeyenToplamDersSaati'] as int?,
      telefon: json['telefon'] as String?,
      adSoyad: json['adSoyad'] as String?,
      baskaPersonelId: json['baskaPersonelId'] as int?,
      dolduranPersonelId: json['dolduranPersonelId'] as int?,
      diniGun: json['diniGun'] as String?,
      dogumTarihi: json['dogumTarihi'] != null
          ? DateTime.tryParse(json['dogumTarihi'].toString())
          : null,
      evlilikTarihi: json['evlilikTarihi'] != null
          ? DateTime.tryParse(json['evlilikTarihi'].toString())
          : null,
      esAdi: json['esAdi'] as String?,
    );
  }

  /// İzin türüne göre sadece gerekli alanları döndürür
  /// izinSebebiId değerleri:
  /// 1: Yıllık İzin, 2: Evlilik İzni, 3: Vefat İzni, 4: Hastalık İzni,
  /// 5: Mazeret İzni, 6: Dini İzin, 7: Doğum İzni, 8: Kurum Görevlendirmesi
  Map<String, dynamic> toJson() {
    // Tarih formatı: 2025-11-28T09:48:53.737Z (ISO 8601 with Z suffix)
    String formatDate(DateTime date) {
      return date.toUtc().toIso8601String();
    }

    // Temel alanlar (tüm izin türlerinde ortak) - curl formatına göre
    final Map<String, dynamic> baseData = {
      'IzinSebebiId': izinSebebiId,
      'IzinBaslangicTarihi': formatDate(izinBaslangicTarihi),
      'IzinBitisTarihi': formatDate(izinBitisTarihi),
      'Aciklama': aciklama,
      'IzindeBulunacagiAdres': izindeBulunacagiAdres,
      'IzindeGirilmeyenToplamDersSaati': izindeGirilmeyenToplamDersSaati ?? 0,
      'BaskaPersonelId': baskaPersonelId ?? 0,
      'DolduranPersonelId': dolduranPersonelId ?? 0,
      // DoktorRaporu: Hastalık İzni (id=4) için toggle değerine göre, diğerleri için false
      'DoktorRaporu': izinSebebiId == 4 ? (doktorRaporu ?? false) : false,
      // Varsayılan değerler (curl'deki gibi)
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

    switch (izinSebebiId) {
      case 1: // Yıllık İzin
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };

      case 2: // Evlilik İzni
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
          'EvlilikTarihi': evlilikTarihi != null
              ? formatDate(evlilikTarihi!)
              : formatDate(DateTime.now()),
          'EsAdi': esAdi ?? '',
        };

      case 3: // Vefat İzni
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };

      case 4: // Hastalık İzni
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };

      case 5: // Mazeret İzni
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };

      case 6: // Dini İzin
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
          'DiniGun': diniGun ?? '',
        };

      case 7: // Doğum İzni
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
          'DogumTarihi': dogumTarihi != null
              ? formatDate(dogumTarihi!)
              : formatDate(DateTime.now()),
        };

      case 8: // Kurum Görevlendirmesi
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };

      default:
        return {
          ...baseData,
          'IzinBaslangicSaat': izinBaslangicSaat ?? 8,
          'IzinBaslangicDakika': izinBaslangicDakika ?? 0,
          'IzinBitisSaat': izinBitisSaat ?? 17,
          'IzinBitisDakika': izinBitisDakika ?? 30,
        };
    }
  }

  /// FormData için Map döndürür (multipart/form-data olarak gönderilmek üzere)
  Map<String, dynamic> toFormDataMap() {
    return toJson();
  }
}

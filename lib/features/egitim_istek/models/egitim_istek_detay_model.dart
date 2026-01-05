class EgitimIstekPersonelItem {
  final int egitimIstekId;
  final int personelId;
  final String adiSoyadi;
  final String gorevi;
  final String gorevYeri;
  final int calistigiSure;

  const EgitimIstekPersonelItem({
    required this.egitimIstekId,
    required this.personelId,
    required this.adiSoyadi,
    required this.gorevi,
    required this.gorevYeri,
    required this.calistigiSure,
  });

  factory EgitimIstekPersonelItem.fromJson(Map<String, dynamic> json) {
    return EgitimIstekPersonelItem(
      egitimIstekId: (json['egitimIstekId'] as num?)?.toInt() ?? 0,
      personelId: (json['personelId'] as num?)?.toInt() ?? 0,
      adiSoyadi: (json['adiSoyadi'] ?? '').toString(),
      gorevi: (json['gorevi'] ?? '').toString(),
      gorevYeri: (json['gorevYeri'] ?? '').toString(),
      calistigiSure: (json['calistigiSure'] as num?)?.toInt() ?? 0,
    );
  }
}

class EgitimIstekDetayResponse {
  final int id;
  final int personelId;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevYeri;
  final String gorevi;

  final List<EgitimIstekPersonelItem> paylasimYapilacakPersoneller;
  final List<EgitimIstekPersonelItem> egitimAlacakPersoneller;

  final String egitimBaslangicTarihi;
  final String egitimBitisTarihi;
  final String egitimBaslangicSaati;
  final String egitimBitisSaati;

  final String egitimSuresiGun;
  final String egitimSuresiSaat;
  final int girilmeyenToplamDersSaati;

  final String egitiminAdi;
  final String sirketAdi;
  final String egitimIcerigi;
  final String webSitesi;

  final String egitimYeri;
  final String ulke;
  final String sehir;
  final String adres;

  final num egitimUcreti;
  final int egitimParaBirimiId;
  final String? egitimParaBirimiSembol;

  final num ulasimUcreti;
  final int ulasimParaBirimiId;
  final String? ulasimParaBirimiSembol;

  final num konaklamaUcreti;
  final int konaklamaParaBirimiId;
  final String? konaklamaParaBirimiSembol;

  final num yemekUcreti;
  final int yemekParaBirimiId;
  final String? yemekParaBirimiSembol;

  final num toplamUcret;
  final num genelToplamUcret;
  final num kurumunKarsiladigiUcret;
  final bool ucretsiz;

  final int odemeSekliId;
  final String? odemeSekli;
  final bool pesin;
  final int vadeGun;

  final String ekBilgi;
  final String unvan;
  final String hesapNo;

  final String paylasimBaslangicTarihi;
  final String paylasimBitisTarihi;
  final String paylasimBaslangicSaati;
  final String paylasimBitisSaati;
  final String paylasimYeri;

  final String protokolTipi;
  final String? dosyaAdi;
  final String? dosyaAciklama;

  final String departman;
  final String egitimTuru;
  final bool protokolImza;
  final bool online;
  final bool topluIstek;
  final String egitiminAdiDiger;

  const EgitimIstekDetayResponse({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevYeri,
    required this.gorevi,
    required this.paylasimYapilacakPersoneller,
    required this.egitimAlacakPersoneller,
    required this.egitimBaslangicTarihi,
    required this.egitimBitisTarihi,
    required this.egitimBaslangicSaati,
    required this.egitimBitisSaati,
    required this.egitimSuresiGun,
    required this.egitimSuresiSaat,
    required this.girilmeyenToplamDersSaati,
    required this.egitiminAdi,
    required this.sirketAdi,
    required this.egitimIcerigi,
    required this.webSitesi,
    required this.egitimYeri,
    required this.ulke,
    required this.sehir,
    required this.adres,
    required this.egitimUcreti,
    required this.egitimParaBirimiId,
    required this.egitimParaBirimiSembol,
    required this.ulasimUcreti,
    required this.ulasimParaBirimiId,
    required this.ulasimParaBirimiSembol,
    required this.konaklamaUcreti,
    required this.konaklamaParaBirimiId,
    required this.konaklamaParaBirimiSembol,
    required this.yemekUcreti,
    required this.yemekParaBirimiId,
    required this.yemekParaBirimiSembol,
    required this.toplamUcret,
    required this.genelToplamUcret,
    required this.kurumunKarsiladigiUcret,
    required this.ucretsiz,
    required this.odemeSekliId,
    required this.odemeSekli,
    required this.pesin,
    required this.vadeGun,
    required this.ekBilgi,
    required this.unvan,
    required this.hesapNo,
    required this.paylasimBaslangicTarihi,
    required this.paylasimBitisTarihi,
    required this.paylasimBaslangicSaati,
    required this.paylasimBitisSaati,
    required this.paylasimYeri,
    required this.protokolTipi,
    required this.dosyaAdi,
    required this.dosyaAciklama,
    required this.departman,
    required this.egitimTuru,
    required this.protokolImza,
    required this.online,
    required this.topluIstek,
    required this.egitiminAdiDiger,
  });

  factory EgitimIstekDetayResponse.fromJson(Map<String, dynamic> json) {
    final paylasimList =
        (json['paylasimYapilacakPersoneller'] as List?)
            ?.whereType<Map>()
            .map(
              (e) =>
                  EgitimIstekPersonelItem.fromJson(e.cast<String, dynamic>()),
            )
            .toList() ??
        const <EgitimIstekPersonelItem>[];

    final egitimAlacakList =
        (json['egitimAlacakPersoneller'] as List?)
            ?.whereType<Map>()
            .map(
              (e) =>
                  EgitimIstekPersonelItem.fromJson(e.cast<String, dynamic>()),
            )
            .toList() ??
        const <EgitimIstekPersonelItem>[];

    return EgitimIstekDetayResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      personelId: (json['personelId'] as num?)?.toInt() ?? 0,
      adSoyad: (json['adSoyad'] ?? '').toString(),
      ad: (json['ad'] ?? '').toString(),
      soyad: (json['soyad'] ?? '').toString(),
      gorevYeri: (json['gorevYeri'] ?? '').toString(),
      gorevi: (json['gorevi'] ?? '').toString(),
      paylasimYapilacakPersoneller: paylasimList,
      egitimAlacakPersoneller: egitimAlacakList,
      egitimBaslangicTarihi: (json['egitimBaslangicTarihi'] ?? '').toString(),
      egitimBitisTarihi: (json['egitimBitisTarihi'] ?? '').toString(),
      egitimBaslangicSaati: (json['egitimBaslangicSaati'] ?? '').toString(),
      egitimBitisSaati: (json['egitimBitisSaati'] ?? '').toString(),
      egitimSuresiGun: (json['egitimSuresiGun'] ?? '').toString(),
      egitimSuresiSaat: (json['egitimSuresiSaat'] ?? '').toString(),
      girilmeyenToplamDersSaati:
          (json['girilmeyenToplamDersSaati'] as num?)?.toInt() ?? 0,
      egitiminAdi: (json['egitiminAdi'] ?? '').toString(),
      sirketAdi: (json['sirketAdi'] ?? '').toString(),
      egitimIcerigi: (json['egitimIcerigi'] ?? '').toString(),
      webSitesi: (json['webSitesi'] ?? '').toString(),
      egitimYeri: (json['egitimYeri'] ?? '').toString(),
      ulke: (json['ulke'] ?? '').toString(),
      sehir: (json['sehir'] ?? '').toString(),
      adres: (json['adres'] ?? '').toString(),
      egitimUcreti: (json['egitimUcreti'] as num?) ?? 0,
      egitimParaBirimiId: (json['egitimParaBirimiId'] as num?)?.toInt() ?? 0,
      egitimParaBirimiSembol: json['egitimParaBirimiSembol']?.toString(),
      ulasimUcreti: (json['ulasimUcreti'] as num?) ?? 0,
      ulasimParaBirimiId: (json['ulasimParaBirimiId'] as num?)?.toInt() ?? 0,
      ulasimParaBirimiSembol: json['ulasimParaBirimiSembol']?.toString(),
      konaklamaUcreti: (json['konaklamaUcreti'] as num?) ?? 0,
      konaklamaParaBirimiId:
          (json['konaklamaParaBirimiId'] as num?)?.toInt() ?? 0,
      konaklamaParaBirimiSembol: json['konaklamaParaBirimiSembol']?.toString(),
      yemekUcreti: (json['yemekUcreti'] as num?) ?? 0,
      yemekParaBirimiId: (json['yemekParaBirimiId'] as num?)?.toInt() ?? 0,
      yemekParaBirimiSembol: json['yemekParaBirimiSembol']?.toString(),
      toplamUcret: (json['toplamUcret'] as num?) ?? 0,
      genelToplamUcret: (json['genelToplamUcret'] as num?) ?? 0,
      kurumunKarsiladigiUcret: (json['kurumunKarsiladigiUcret'] as num?) ?? 0,
      ucretsiz: json['ucretsiz'] == true,
      odemeSekliId: (json['odemeSekliId'] as num?)?.toInt() ?? 0,
      odemeSekli: json['odemeSekli']?.toString(),
      pesin: json['pesin'] == true,
      vadeGun: (json['vadeGun'] as num?)?.toInt() ?? 0,
      ekBilgi: (json['ekBilgi'] ?? '').toString(),
      unvan: (json['unvan'] ?? '').toString(),
      hesapNo: (json['hesapNo'] ?? '').toString(),
      paylasimBaslangicTarihi: (json['paylasimBaslangicTarihi'] ?? '')
          .toString(),
      paylasimBitisTarihi: (json['paylasimBitisTarihi'] ?? '').toString(),
      paylasimBaslangicSaati: (json['paylasimBaslangicSaati'] ?? '').toString(),
      paylasimBitisSaati: (json['paylasimBitisSaati'] ?? '').toString(),
      paylasimYeri: (json['paylasimYeri'] ?? '').toString(),
      protokolTipi: (json['protokolTipi'] ?? '').toString(),
      dosyaAdi: json['dosyaAdi']?.toString(),
      dosyaAciklama: json['dosyaAciklama']?.toString(),
      departman: (json['departman'] ?? '').toString(),
      egitimTuru: (json['egitimTuru'] ?? '').toString(),
      protokolImza: json['protokolImza'] == true,
      online: json['online'] == true,
      topluIstek: json['topluIstek'] == true,
      egitiminAdiDiger: (json['egitiminAdiDiger'] ?? '').toString(),
    );
  }
}

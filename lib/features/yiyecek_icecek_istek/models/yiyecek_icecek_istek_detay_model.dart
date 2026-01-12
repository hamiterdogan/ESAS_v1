class YiyecekIcecekIstekDetayReq {
  final int id;

  YiyecekIcecekIstekDetayReq({required this.id});

  Map<String, dynamic> toJson() => {
    'id': id,
  };
}

class IkramSatir {
  final int id;
  final int yiyecekIcecekIstekId;
  final bool cay;
  final bool kahve;
  final bool mesrubat;
  final bool kasarliSimit;
  final bool kruvasan;
  final bool kurabiye;
  final bool ogleYemegi;
  final bool kokteyl;
  final bool aksamYemegi;
  final bool kumanya;
  final bool diger;
  final String? digerIkram;
  final int kiKatilimci; // Staff participant count
  final int kdKatilimci; // External participant count
  final int toplamKatilimci;
  final String baslangicSaati;
  final String bitisSaati;

  IkramSatir({
    required this.id,
    required this.yiyecekIcecekIstekId,
    required this.cay,
    required this.kahve,
    required this.mesrubat,
    required this.kasarliSimit,
    required this.kruvasan,
    required this.kurabiye,
    required this.ogleYemegi,
    required this.kokteyl,
    required this.aksamYemegi,
    required this.kumanya,
    required this.diger,
    this.digerIkram,
    required this.kiKatilimci,
    required this.kdKatilimci,
    required this.toplamKatilimci,
    required this.baslangicSaati,
    required this.bitisSaati,
  });

  factory IkramSatir.fromJson(Map<String, dynamic> json) {
    return IkramSatir(
      id: json['id'] as int? ?? 0,
      yiyecekIcecekIstekId: json['yiyecekIcecekIstekId'] as int? ?? 0,
      cay: json['cay'] as bool? ?? false,
      kahve: json['kahve'] as bool? ?? false,
      mesrubat: json['mesrubat'] as bool? ?? false,
      kasarliSimit: json['kasarliSimit'] as bool? ?? false,
      kruvasan: json['kruvasan'] as bool? ?? false,
      kurabiye: json['kurabiye'] as bool? ?? false,
      ogleYemegi: json['ogleYemegi'] as bool? ?? false,
      kokteyl: json['kokteyl'] as bool? ?? false,
      aksamYemegi: json['aksamYemegi'] as bool? ?? false,
      kumanya: json['kumanya'] as bool? ?? false,
      diger: json['diger'] as bool? ?? false,
      digerIkram: json['digerIkram'] as String?,
      kiKatilimci: json['kiKatilimci'] as int? ?? 0,
      kdKatilimci: json['kdKatilimci'] as int? ?? 0,
      toplamKatilimci: json['toplamKatilimci'] as int? ?? 0,
      baslangicSaati: json['baslangicSaati'] as String? ?? '',
      bitisSaati: json['bitisSaati'] as String? ?? '',
    );
  }
}

class YiyecekIcecekIstekDetayRes {
  final int id;
  final int personelId;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevi;
  final String gorevYeri;
  final List<IkramSatir> ikramSatir;
  final String etkinlikTarihi; // Using String to preserve format, can parse later
  final String donem;
  final String etkinlikAdi;
  final String? etkinlikAdiDiger;
  final String ikramYeri;
  final String aciklama;
  final String alinanYer;

  YiyecekIcecekIstekDetayRes({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevi,
    required this.gorevYeri,
    required this.ikramSatir,
    required this.etkinlikTarihi,
    required this.donem,
    required this.etkinlikAdi,
    this.etkinlikAdiDiger,
    required this.ikramYeri,
    required this.aciklama,
    required this.alinanYer,
  });

  factory YiyecekIcecekIstekDetayRes.fromJson(Map<String, dynamic> json) {
    return YiyecekIcecekIstekDetayRes(
      id: json['id'] as int? ?? 0,
      personelId: json['personelId'] as int? ?? 0,
      adSoyad: json['adSoyad'] as String? ?? '',
      ad: json['ad'] as String? ?? '',
      soyad: json['soyad'] as String? ?? '',
      gorevi: json['gorevi'] as String? ?? '',
      gorevYeri: json['gorevYeri'] as String? ?? '',
      ikramSatir: (json['ikramSatir'] as List<dynamic>?)
          ?.map((e) => IkramSatir.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      etkinlikTarihi: json['etkinlikTarihi'] as String? ?? '',
      donem: json['donem'] as String? ?? '',
      etkinlikAdi: json['etkinlikAdi'] as String? ?? '',
      etkinlikAdiDiger: json['etkinlikAdiDiger'] as String?,
      ikramYeri: json['ikramYeri'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      alinanYer: json['alinanYer'] as String? ?? '',
    );
  }
}

class YiyecekIstekEkleReq {
  final List<int> binaId;
  final List<IkramRequest> ikramlar;
  final String etkinlikTarihi;
  final String donem;
  final String etkinlikAdi;
  final String etkinlikAdiDiger;
  final String ikramYeri;
  final String aciklama;

  YiyecekIstekEkleReq({
    required this.binaId,
    required this.ikramlar,
    required this.etkinlikTarihi,
    required this.donem,
    required this.etkinlikAdi,
    required this.etkinlikAdiDiger,
    required this.ikramYeri,
    required this.aciklama,
  });

  Map<String, dynamic> toJson() {
    return {
      'binaId': binaId,
      'ikramlar': ikramlar.map((e) => e.toJson()).toList(),
      'etkinlikTarihi': etkinlikTarihi,
      'donem': donem,
      'etkinlikAdi': etkinlikAdi,
      'etkinlikAdiDiger': etkinlikAdiDiger,
      'ikramYeri': ikramYeri,
      'aciklama': aciklama,
    };
  }
}

class IkramRequest {
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
  final String digerIkram;
  final int kiKatilimci;
  final int kdKatilimci;
  final int toplamKatilimci;
  final String baslangicSaat;
  final String baslangicDakika;
  final String bitisSaat;
  final String bitisDakika;

  IkramRequest({
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
    required this.digerIkram,
    required this.kiKatilimci,
    required this.kdKatilimci,
    required this.toplamKatilimci,
    required this.baslangicSaat,
    required this.baslangicDakika,
    required this.bitisSaat,
    required this.bitisDakika,
  });

  Map<String, dynamic> toJson() {
    return {
      'cay': cay,
      'kahve': kahve,
      'mesrubat': mesrubat,
      'kasarliSimit': kasarliSimit,
      'kruvasan': kruvasan,
      'kurabiye': kurabiye,
      'ogleYemegi': ogleYemegi,
      'kokteyl': kokteyl,
      'aksamYemegi': aksamYemegi,
      'kumanya': kumanya,
      'diger': diger,
      'digerIkram': digerIkram,
      'kiKatilimci': kiKatilimci,
      'kdKatilimci': kdKatilimci,
      'toplamKatilimci': toplamKatilimci,
      'baslangicSaat': baslangicSaat,
      'baslangicDakika': baslangicDakika,
      'bitisSaat': bitisSaat,
      'bitisDakika': bitisDakika,
    };
  }
}

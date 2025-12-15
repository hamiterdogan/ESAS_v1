class AracIstekEkleReq {
  final int personelId;
  final DateTime gidilecekTarih;
  final String gidisSaat;
  final String gidisDakika;
  final String donusSaat;
  final String donusDakika;
  final String aracTuru;
  final List<AracIstekYolcuPersonelSatir> yolcuPersonelSatir;
  final List<int> yolcuDepartmanId;
  final List<AracIstekOkulSatir> okullarSatir;
  final List<AracIstekGidilecekYerSatir> gidilecekYerSatir;
  final int yolcuSayisi;
  final int mesafe;
  final String istekNedeni;
  final String istekNedeniDiger;
  final String aciklama;
  final String tasinacakYuk;
  final bool meb;

  const AracIstekEkleReq({
    required this.personelId,
    required this.gidilecekTarih,
    required this.gidisSaat,
    required this.gidisDakika,
    required this.donusSaat,
    required this.donusDakika,
    required this.aracTuru,
    required this.yolcuPersonelSatir,
    required this.yolcuDepartmanId,
    required this.okullarSatir,
    required this.gidilecekYerSatir,
    required this.yolcuSayisi,
    required this.mesafe,
    required this.istekNedeni,
    required this.istekNedeniDiger,
    required this.aciklama,
    required this.tasinacakYuk,
    required this.meb,
  });

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
      'yolcuPersonelSatir': yolcuPersonelSatir.map((e) => e.toJson()).toList(),
      'yolcuDepartmanId': yolcuDepartmanId,
      'okullarSatir': okullarSatir.map((e) => e.toJson()).toList(),
      'gidilecekYerSatir': gidilecekYerSatir.map((e) => e.toJson()).toList(),
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

class AracIstekYolcuPersonelSatir {
  final int personelId;
  final String perAdi;
  final String gorevi;
  final String gorevYeri;

  const AracIstekYolcuPersonelSatir({
    required this.personelId,
    required this.perAdi,
    required this.gorevi,
    required this.gorevYeri,
  });

  Map<String, dynamic> toJson() {
    return {
      'personelId': personelId,
      'perAdi': perAdi,
      'gorevi': gorevi,
      'gorevYeri': gorevYeri,
    };
  }
}

class AracIstekOkulSatir {
  final String okulKodu;
  final String sinif;
  final String seviye;
  final int numara;
  final String adi;
  final String soyadi;

  const AracIstekOkulSatir({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
    required this.numara,
    required this.adi,
    required this.soyadi,
  });

  Map<String, dynamic> toJson() {
    return {
      'okulKodu': okulKodu,
      'sinif': sinif,
      'seviye': seviye,
      'numara': numara,
      'adi': adi,
      'soyadi': soyadi,
    };
  }
}

class AracIstekGidilecekYerSatir {
  final String gidilecekYer;
  final String semt;

  const AracIstekGidilecekYerSatir({
    required this.gidilecekYer,
    required this.semt,
  });

  Map<String, dynamic> toJson() {
    return {'gidilecekYer': gidilecekYer, 'semt': semt};
  }
}

class AracTalep {
  final int personelId;
  final DateTime gidilecekTarih;
  final String gidisSaat;
  final String gidisDakika;
  final String donusSaat;
  final String donusDakika;
  final String aracTuru;
  final List<YolcuPersonel> yolcuPersonelSatir;
  final List<int> yolcuDepartmanId;
  final List<OkulSatir> okullarSatir;
  final List<GidilecekYerSatir> gidilecekYerSatir;
  final int yolcuSayisi;
  final int mesafe;
  final String istekNedeni;
  final String istekNedeniDiger;
  final String aciklama;
  final String tasinacakYuk;
  final bool meb;

  const AracTalep({
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
}

class YolcuPersonel {
  final int personelId;
  final String perAdi;
  final String gorevi;
  final String gorevYeri;

  const YolcuPersonel({
    required this.personelId,
    required this.perAdi,
    required this.gorevi,
    required this.gorevYeri,
  });
}

class OkulSatir {
  final String okulKodu;
  final String sinif;
  final String seviye;
  final int numara;
  final String adi;
  final String soyadi;

  const OkulSatir({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
    required this.numara,
    required this.adi,
    required this.soyadi,
  });
}

class GidilecekYerSatir {
  final String gidilecekYer;
  final String semt;

  const GidilecekYerSatir({
    required this.gidilecekYer,
    required this.semt,
  });
}

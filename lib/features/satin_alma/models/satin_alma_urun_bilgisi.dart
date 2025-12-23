class SatinAlmaUrunBilgisi {
  const SatinAlmaUrunBilgisi({
    this.anaKategori,
    this.anaKategoriId,
    this.altKategori,
    this.altKategoriId,
    this.urunDetay,
    this.aciklama,
    this.miktar,
    this.olcuBirimi,
    this.olcuBirimiId,
    this.olcuBirimiKisaltma,
    this.paraBirimi,
    this.paraBirimiId,
    this.paraBirimiKod,
    this.dovizKuru,
    this.fiyatAna,
    this.fiyatKusurat,
    this.toplamFiyat,
    this.tlKurFiyati,
    required this.toplamTlFiyati,
  });

  final String? anaKategori;
  final int? anaKategoriId;
  final String? altKategori;
  final int? altKategoriId;
  final String? urunDetay;
  final String? aciklama;
  final int? miktar;
  final String? olcuBirimi;
  final int? olcuBirimiId;
  final String? olcuBirimiKisaltma;
  final String? paraBirimi;
  final int? paraBirimiId;
  final String? paraBirimiKod;
  final double? dovizKuru;
  final String? fiyatAna;
  final String? fiyatKusurat;
  final String? toplamFiyat;
  final String? tlKurFiyati;
  final String toplamTlFiyati;
}

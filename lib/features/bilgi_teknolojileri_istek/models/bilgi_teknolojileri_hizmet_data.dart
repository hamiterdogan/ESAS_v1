class BilgiTeknolojileriHizmetData {
  final List<String> binaAdlari;
  final String tarih;
  final String kategori;
  final String aciklama;

  BilgiTeknolojileriHizmetData({
    required this.binaAdlari,
    required this.tarih,
    required this.kategori,
    required this.aciklama,
  });

  @override
  String toString() =>
      'BilgiTeknolojileriHizmetData(binaAdlari: $binaAdlari, tarih: $tarih, kategori: $kategori, aciklama: $aciklama)';
}

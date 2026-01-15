class BilgiTeknolojileriHizmetData {
  final String kategori;
  final String hizmetDetayi;
  final String aciklama;

  BilgiTeknolojileriHizmetData({
    required this.kategori,
    this.hizmetDetayi = '',
    required this.aciklama,
  });

  @override
  String toString() =>
      'BilgiTeknolojileriHizmetData(kategori: $kategori, hizmetDetayi: $hizmetDetayi, aciklama: $aciklama)';
}

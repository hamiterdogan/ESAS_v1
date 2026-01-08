class YiyecekIcecekIkramData {
  final int kurumIciAdet;
  final int kurumDisiAdet;

  final String baslangicSaati;
  final String bitisSaati;
  final List<String> secilenIkramlar;

  YiyecekIcecekIkramData({
    required this.kurumIciAdet,
    required this.kurumDisiAdet,
    required this.baslangicSaati,
    required this.bitisSaati,
    required this.secilenIkramlar,
  });

  int get toplamAdet => kurumIciAdet + kurumDisiAdet;

  @override
  String toString() =>
      'Kurum İçi: $kurumIciAdet, Kurum Dışı: $kurumDisiAdet, Başlangıç: $baslangicSaati, Bitiş: $bitisSaati, İkramlar: ${secilenIkramlar.join(", ")}';
}

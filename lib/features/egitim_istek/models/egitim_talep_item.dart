class EgitimTalepItem {
  final int onayKayitId;
  final String egitimAdi;
  final String baslangicTarihi;
  final String onayDurumu;

  EgitimTalepItem({
    required this.onayKayitId,
    required this.egitimAdi,
    required this.baslangicTarihi,
    required this.onayDurumu,
  });

  factory EgitimTalepItem.fromJson(Map<String, dynamic> json) {
    return EgitimTalepItem(
      onayKayitId: json['onayKayitId'] ?? json['onayKayitId'] ?? 0,
      egitimAdi: json['egitimAdi'] ?? '',
      baslangicTarihi: json['baslangicTarihi'] ?? '',
      onayDurumu: json['onayDurumu'] ?? '',
    );
  }
}

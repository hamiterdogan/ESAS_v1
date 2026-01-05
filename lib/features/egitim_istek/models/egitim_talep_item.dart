class EgitimTalepItem {
  final int onayKayitID;
  final String egitimAdi;
  final String baslangicTarihi;
  final String onayDurumu;

  EgitimTalepItem({
    required this.onayKayitID,
    required this.egitimAdi,
    required this.baslangicTarihi,
    required this.onayDurumu,
  });

  factory EgitimTalepItem.fromJson(Map<String, dynamic> json) {
    return EgitimTalepItem(
      onayKayitID: json['onayKayitID'] ?? 0,
      egitimAdi: json['egitimAdi'] ?? '',
      baslangicTarihi: json['baslangicTarihi'] ?? '',
      onayDurumu: json['onayDurumu'] ?? '',
    );
  }
}

class GidilecekYer {
  final String id;
  final String ad;

  GidilecekYer({
    required this.id,
    required this.ad,
  });

  factory GidilecekYer.fromJson(Map<String, dynamic> json) {
    // API örneğinde alanlar: { "gidilecekYer": "0", "semt": "Yeditepe Üni. Kayışdağı kampüs" }
    final idVal = json['gidilecekYer'] ?? json['id'] ?? json['kod'] ?? '';
    final adVal = json['semt'] ??
        json['ad'] ??
        json['adSoyad'] ??
        json['gidilecekYerAdi'] ??
        json['yerAdi'] ??
        json['lokasyon'] ??
        json['yer'] ??
        '';

    return GidilecekYer(
      id: idVal.toString().trim(),
      ad: adVal.toString().trim().isNotEmpty
          ? adVal.toString().trim()
          : idVal.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gidilecekYer': id,
        'semt': ad,
      };
}


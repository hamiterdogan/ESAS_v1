class SarfMalzemeTalep {
  final String onayTipi;
  final int onayKayitId;
  final DateTime olusturmaTarihi;
  final DateTime islemTarihi;
  final String onayDurumu;
  final String olusturanKisi;
  final String aciklama;
  final String sarfMalzemeTuru;

  const SarfMalzemeTalep({
    required this.onayTipi,
    required this.onayKayitId,
    required this.olusturmaTarihi,
    required this.islemTarihi,
    required this.onayDurumu,
    required this.olusturanKisi,
    required this.aciklama,
    required this.sarfMalzemeTuru,
  });

  factory SarfMalzemeTalep.fromJson(Map<String, dynamic> json) {
    return SarfMalzemeTalep(
      onayTipi: json['onayTipi'] as String? ?? '',
      onayKayitId: json['onayKayitId'] as int? ?? 0,
      olusturmaTarihi: json['olusturmaTarihi'] != null
          ? DateTime.tryParse(json['olusturmaTarihi'] as String) ?? DateTime(1)
          : DateTime(1),
      islemTarihi: json['islemTarihi'] != null
          ? DateTime.tryParse(json['islemTarihi'] as String) ?? DateTime(1)
          : DateTime(1),
      onayDurumu: json['onayDurumu'] as String? ?? '',
      olusturanKisi: json['olusturanKisi'] as String? ?? '',
      aciklama: json['aciklama'] as String? ?? '',
      sarfMalzemeTuru: json['sarfMalzemeTuru'] as String? ?? '',
    );
  }
}

class SarfMalzemeTalepResponse {
  final List<SarfMalzemeTalep> talepler;

  const SarfMalzemeTalepResponse({required this.talepler});

  factory SarfMalzemeTalepResponse.fromJson(Map<String, dynamic> json) {
    final taleplerJson = json['talepler'] as List<dynamic>? ?? [];
    return SarfMalzemeTalepResponse(
      talepler: taleplerJson
          .map((e) => SarfMalzemeTalep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

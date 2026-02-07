
class SatinAlmaFiyatArastirmaPersonel {
  final int personelId;
  final int gorevId;
  final String adi;
  final String soyadi;

  SatinAlmaFiyatArastirmaPersonel({
    required this.personelId,
    required this.gorevId,
    required this.adi,
    required this.soyadi,
  });

  factory SatinAlmaFiyatArastirmaPersonel.fromJson(Map<String, dynamic> json) {
    return SatinAlmaFiyatArastirmaPersonel(
      personelId: json['personelId'] as int? ?? 0,
      gorevId: json['gorevId'] as int? ?? 0,
      adi: json['adi'] as String? ?? '',
      soyadi: json['soyadi'] as String? ?? '',
    );
  }
}

class SatinAlmaFiyatArastirmaListResponse {
  final List<SatinAlmaFiyatArastirmaPersonel> fiyatArastirPersoneller;

  SatinAlmaFiyatArastirmaListResponse({required this.fiyatArastirPersoneller});

  factory SatinAlmaFiyatArastirmaListResponse.fromJson(Map<String, dynamic> json) {
    return SatinAlmaFiyatArastirmaListResponse(
      fiyatArastirPersoneller: (json['fiyatArastirPersoneller'] as List<dynamic>?)
              ?.map((e) => SatinAlmaFiyatArastirmaPersonel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

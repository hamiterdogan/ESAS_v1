class SatinAlmaOlcuBirim {
  final int id;
  final String birimAdi;
  final String kisaltma;

  SatinAlmaOlcuBirim({
    required this.id,
    required this.birimAdi,
    required this.kisaltma,
  });

  factory SatinAlmaOlcuBirim.fromJson(Map<String, dynamic> json) {
    return SatinAlmaOlcuBirim(
      id: json['id'] as int? ?? 0,
      birimAdi: json['birimAdi'] as String? ?? '',
      kisaltma: json['kisaltma'] as String? ?? '',
    );
  }
}

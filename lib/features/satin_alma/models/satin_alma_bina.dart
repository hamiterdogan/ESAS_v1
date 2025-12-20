class SatinAlmaBina {
  final int id;
  final String binaAdi;
  final String binaKodu;

  const SatinAlmaBina({
    required this.id,
    required this.binaAdi,
    required this.binaKodu,
  });

  factory SatinAlmaBina.fromJson(Map<String, dynamic> json) {
    return SatinAlmaBina(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      binaAdi: json['binaAdi']?.toString() ?? '-',
      binaKodu: json['binaKodu']?.toString() ?? '',
    );
  }
}

class ParaBirimi {
  final int id;
  final String kod;
  final String birimAdi;
  final String sembol;

  ParaBirimi({
    required this.id,
    required this.kod,
    required this.birimAdi,
    required this.sembol,
  });

  factory ParaBirimi.fromJson(Map<String, dynamic> json) {
    return ParaBirimi(
      id: json['id'] as int? ?? 0,
      kod: json['kod'] as String? ?? '',
      birimAdi: json['birimAdi'] as String? ?? '',
      sembol: json['sembol'] as String? ?? '',
    );
  }
}

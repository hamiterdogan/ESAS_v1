class OdemeTuru {
  final int id;
  final String isim;

  OdemeTuru({
    required this.id,
    required this.isim,
  });

  factory OdemeTuru.fromJson(Map<String, dynamic> json) {
    return OdemeTuru(
      id: json['id'] as int? ?? 0,
      isim: json['isim'] as String? ?? '',
    );
  }
}

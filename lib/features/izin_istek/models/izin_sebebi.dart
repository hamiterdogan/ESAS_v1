class IzinSebebi {
  final int id;
  final String ad;

  IzinSebebi({
    required this.id,
    required this.ad,
  });

  factory IzinSebebi.fromJson(Map<String, dynamic> json) {
    return IzinSebebi(
      id: json['id'] as int? ?? 0,
      ad: json['ad'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad': ad,
    };
  }
}

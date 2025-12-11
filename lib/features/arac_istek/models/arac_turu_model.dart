class AracTuru {
  final int id;
  final String tur;

  AracTuru({required this.id, required this.tur});

  factory AracTuru.fromJson(Map<String, dynamic> json) {
    return AracTuru(
      id: json['id'] as int? ?? 0,
      tur: json['tur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'tur': tur};
  }
}

/// Görev Yeri modeli - GorevYeriDoldur endpoint'inden dönen veri
class GorevYeri {
  final int id;
  final String gorevYeriAdi;

  GorevYeri({required this.id, required this.gorevYeriAdi});

  factory GorevYeri.fromJson(Map<String, dynamic> json) {
    return GorevYeri(
      id: json['id'] as int? ?? 0,
      gorevYeriAdi: json['gorevYeriAdi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'gorevYeriAdi': gorevYeriAdi};
  }
}

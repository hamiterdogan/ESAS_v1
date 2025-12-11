/// Görev modeli - GorevDoldur endpoint'inden dönen veri
class Gorev {
  final int gorevId;
  final String gorevAdi;

  Gorev({required this.gorevId, required this.gorevAdi});

  factory Gorev.fromJson(Map<String, dynamic> json) {
    return Gorev(
      gorevId: json['gorevId'] as int? ?? 0,
      gorevAdi: json['gorevAdi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'gorevId': gorevId, 'gorevAdi': gorevAdi};
  }
}

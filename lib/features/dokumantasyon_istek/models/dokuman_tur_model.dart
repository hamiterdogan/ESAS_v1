class DokumanTurModel {
  final int id;
  final String tur;

  DokumanTurModel({required this.id, required this.tur});

  factory DokumanTurModel.fromJson(Map<String, dynamic> json) {
    return DokumanTurModel(
      id: json['id'],
      tur: json['tur'],
    );
  }
}

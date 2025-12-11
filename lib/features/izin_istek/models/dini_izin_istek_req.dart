class DiniIzinIstekReq {
  final int personelId;
  final int izinSebebiId; // Dini izin sebep ID'si
  final DateTime baslangicTarih;
  final DateTime bitisTarih;
  final String aciklama;
  final String izindeKaldigiAdres;
  final int girileymeyenDersSaati;

  DiniIzinIstekReq({
    required this.personelId,
    required this.izinSebebiId,
    required this.baslangicTarih,
    required this.bitisTarih,
    required this.aciklama,
    required this.izindeKaldigiAdres,
    required this.girileymeyenDersSaati,
  });

  factory DiniIzinIstekReq.fromJson(Map<String, dynamic> json) {
    return DiniIzinIstekReq(
      personelId: json['personelId'] as int? ?? 0,
      izinSebebiId: json['izinSebebiId'] as int? ?? 0,
      baslangicTarih: json['baslangicTarih'] != null
          ? DateTime.tryParse(json['baslangicTarih'].toString()) ??
                DateTime.now()
          : DateTime.now(),
      bitisTarih: json['bitisTarih'] != null
          ? DateTime.tryParse(json['bitisTarih'].toString()) ?? DateTime.now()
          : DateTime.now(),
      aciklama: json['aciklama'] as String? ?? '',
      izindeKaldigiAdres: json['izindeKaldigiAdres'] as String? ?? '',
      girileymeyenDersSaati: json['girileymeyenDersSaati'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'personelId': personelId,
      'izinSebebiId': izinSebebiId,
      'baslangicTarih': baslangicTarih.toIso8601String(),
      'bitisTarih': bitisTarih.toIso8601String(),
      'aciklama': aciklama,
      'izindeKaldigiAdres': izindeKaldigiAdres,
      'girileymeyenDersSaati': girileymeyenDersSaati,
    };
  }
}

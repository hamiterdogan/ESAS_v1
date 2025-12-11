class IzinIstekDetay {
  final int id;
  final int personelId;
  final String? personelAdi;
  final int? izinSebebiId;
  final String? izinSebebiAd;
  final DateTime? baslangicTarih;
  final DateTime? bitisTarih;
  final String? aciklama;
  final String? onayDurumu;
  final String? onayanPersonel;
  final String? onaySebebi;

  IzinIstekDetay({
    required this.id,
    required this.personelId,
    this.personelAdi,
    this.izinSebebiId,
    this.izinSebebiAd,
    this.baslangicTarih,
    this.bitisTarih,
    this.aciklama,
    this.onayDurumu,
    this.onayanPersonel,
    this.onaySebebi,
  });

  factory IzinIstekDetay.fromJson(Map<String, dynamic> json) {
    return IzinIstekDetay(
      id: json['id'] as int? ?? 0,
      personelId: json['personelId'] as int? ?? 0,
      personelAdi: json['personelAdi'] as String?,
      izinSebebiId: json['izinSebebiId'] as int?,
      izinSebebiAd: json['izinSebebiAd'] as String?,
      baslangicTarih: json['baslangicTarih'] != null
          ? DateTime.tryParse(json['baslangicTarih'].toString())
          : null,
      bitisTarih: json['bitisTarih'] != null
          ? DateTime.tryParse(json['bitisTarih'].toString())
          : null,
      aciklama: json['aciklama'] as String?,
      onayDurumu: json['onayDurumu'] as String?,
      onayanPersonel: json['onayanPersonel'] as String?,
      onaySebebi: json['onaySebebi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personelId': personelId,
      'personelAdi': personelAdi,
      'izinSebebiId': izinSebebiId,
      'izinSebebiAd': izinSebebiAd,
      'baslangicTarih': baslangicTarih?.toIso8601String(),
      'bitisTarih': bitisTarih?.toIso8601String(),
      'aciklama': aciklama,
      'onayDurumu': onayDurumu,
      'onayanPersonel': onayanPersonel,
      'onaySebebi': onaySebebi,
    };
  }
}

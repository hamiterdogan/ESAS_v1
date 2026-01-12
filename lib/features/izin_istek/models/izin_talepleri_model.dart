// Yeni endpoint: IzinTaleplerimiGetir
// URL: /api/IzinIstek/IzinTaleplerimiGetir

class IzinTalepleriResponse {
  final List<IzinTalep> talepler;

  IzinTalepleriResponse({required this.talepler});

  factory IzinTalepleriResponse.fromJson(Map<String, dynamic> json) {
    return IzinTalepleriResponse(
      talepler: (json['talepler'] as List)
          .map((e) => IzinTalep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class IzinTalep {
  final String onayTipi;
  final int onayKayitId;
  final String olusturmaTarihi;
  final String islemTarihi;
  final String onayDurumu;
  final String olusturanKisi;
  final int izinSebebiId;
  final String izinTuru;

  IzinTalep({
    required this.onayTipi,
    required this.onayKayitId,
    required this.olusturmaTarihi,
    required this.islemTarihi,
    required this.onayDurumu,
    required this.olusturanKisi,
    required this.izinSebebiId,
    required this.izinTuru,
  });

  factory IzinTalep.fromJson(Map<String, dynamic> json) {
    return IzinTalep(
      onayTipi: json['onayTipi'] as String? ?? 'İzin İstek',
      onayKayitId:
          json['onayKayitId'] as int? ?? json['onayKayitId'] as int? ?? 0,
      olusturmaTarihi: json['olusturmaTarihi'] as String? ?? '',
      islemTarihi: json['islemTarihi'] as String? ?? '',
      onayDurumu: json['onayDurumu'] as String? ?? '',
      olusturanKisi: json['olusturanKisi'] as String? ?? '',
      izinSebebiId: json['izinSebebiId'] as int? ?? 0,
      izinTuru: json['izinTuru'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onayTipi': onayTipi,
      'onayKayitId': onayKayitId,
      'olusturmaTarihi': olusturmaTarihi,
      'islemTarihi': islemTarihi,
      'onayDurumu': onayDurumu,
      'olusturanKisi': olusturanKisi,
      'izinSebebiId': izinSebebiId,
      'izinTuru': izinTuru,
    };
  }
}

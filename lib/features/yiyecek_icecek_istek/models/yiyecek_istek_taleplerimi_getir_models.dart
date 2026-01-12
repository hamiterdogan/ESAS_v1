class YiyecekIstekTaleplerimiGetirReq {
  final int tip; // 0: Devam Eden, 1: Tamamlanan

  YiyecekIstekTaleplerimiGetirReq({required this.tip});

  Map<String, dynamic> toJson() {
    return {
      'tip': tip,
    };
  }
}

class YiyecekIstekTalep {
  final String onayTipi;
  final int onayKayitId;
  final String olusturmaTarihi;
  final String islemTarihi;
  final String onayDurumu;
  final String olusturanKisi;
  final String etkinlikAdi;
  final String donem;
  final String aciklama;

  YiyecekIstekTalep({
    required this.onayTipi,
    required this.onayKayitId,
    required this.olusturmaTarihi,
    required this.islemTarihi,
    required this.onayDurumu,
    required this.olusturanKisi,
    required this.etkinlikAdi,
    required this.donem,
    required this.aciklama,
  });

  factory YiyecekIstekTalep.fromJson(Map<String, dynamic> json) {
    return YiyecekIstekTalep(
      onayTipi: json['onayTipi']?.toString() ?? '',
      onayKayitId: json['onayKayitId'] is int ? json['onayKayitId'] : 0,
      olusturmaTarihi: json['olusturmaTarihi']?.toString() ?? '',
      islemTarihi: json['islemTarihi']?.toString() ?? '',
      onayDurumu: json['onayDurumu']?.toString() ?? '',
      olusturanKisi: json['olusturanKisi']?.toString() ?? '',
      etkinlikAdi: json['etkinlikAdi']?.toString() ?? '',
      donem: json['donem']?.toString() ?? '',
      aciklama: json['aciklama']?.toString() ?? '',
    );
  }
}

class YiyecekIstekTaleplerimiGetirRes {
  final List<YiyecekIstekTalep> talepler;

  YiyecekIstekTaleplerimiGetirRes({required this.talepler});

  factory YiyecekIstekTaleplerimiGetirRes.fromJson(Map<String, dynamic> json) {
    final list = json['talepler'] as List<dynamic>? ?? [];
    return YiyecekIstekTaleplerimiGetirRes(
      talepler: list.map((e) => YiyecekIstekTalep.fromJson(e)).toList(),
    );
  }
}

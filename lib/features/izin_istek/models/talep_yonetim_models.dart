// Request model
class TalepGetirRequest {
  final int tip; // 1: Devam eden, 2: Tamamlanan
  final int personelId;
  final String onayTipi;
  final String? talepDurumu;
  final int talepEdenPerId;
  final int gorevYeriId;
  final int gorevId;
  final String? talepBaslangicTarihi;
  final String? talepBitisTarihi;
  final int oturumGorevId;

  TalepGetirRequest({
    this.tip = 1,
    this.personelId = 0,
    this.onayTipi = 'İzin İstek',
    this.talepDurumu,
    this.talepEdenPerId = 0,
    this.gorevYeriId = 0,
    this.gorevId = 0,
    this.talepBaslangicTarihi,
    this.talepBitisTarihi,
    this.oturumGorevId = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'tip': tip,
      'personelId': personelId,
      'onayTipi': onayTipi,
      'talepDurumu': talepDurumu,
      'talepEdenPerId': talepEdenPerId,
      'gorevYeriId': gorevYeriId,
      'gorevId': gorevId,
      'talepBaslangicTarihi': talepBaslangicTarihi,
      'talepBitisTarihi': talepBitisTarihi,
      'oturumGorevId': oturumGorevId,
    };
  }
}

// Response model
class TalepYonetimResponse {
  final List<Talep> talepler;

  TalepYonetimResponse({required this.talepler});

  factory TalepYonetimResponse.fromJson(Map<String, dynamic> json) {
    return TalepYonetimResponse(
      talepler: (json['talepler'] as List)
          .map((e) => Talep.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Single talep model
class Talep {
  final String onayTipi;
  final int onayKayitID;
  final String olusturmaTarihi;
  final String islemTarihi;
  final String onayDurumu;
  final String? beklemeDurumu;
  final String olusturanKisi;
  final String? gorevYeri;
  final String? gorevi;
  final String? cevapVeren;
  final String? className;
  final bool arsiv;
  final bool geriGonderildi;
  final int onaySirasi;
  final int onaySureciId;
  final String? actionAdi;
  final int toplamTutar;
  final String? bekletKademe;
  final String? okundu;
  final String? aracTuru;

  Talep({
    required this.onayTipi,
    required this.onayKayitID,
    required this.olusturmaTarihi,
    required this.islemTarihi,
    required this.onayDurumu,
    this.beklemeDurumu,
    required this.olusturanKisi,
    this.gorevYeri,
    this.gorevi,
    this.cevapVeren,
    this.className,
    required this.arsiv,
    required this.geriGonderildi,
    required this.onaySirasi,
    required this.onaySureciId,
    this.actionAdi,
    required this.toplamTutar,
    this.bekletKademe,
    this.okundu,
    this.aracTuru,
  });

  // Yardımcı metod: num (int veya double) değeri int'e dönüştürür
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory Talep.fromJson(Map<String, dynamic> json) {
    return Talep(
      onayTipi: json['onayTipi']?.toString() ?? '',
      onayKayitID: _parseIntSafe(json['onayKayitID']),
      olusturmaTarihi: json['olusturmaTarihi']?.toString() ?? '',
      islemTarihi: json['islemTarihi']?.toString() ?? '',
      onayDurumu: json['onayDurumu']?.toString() ?? '',
      beklemeDurumu: json['beklemeDurumu']?.toString(),
      olusturanKisi: json['olusturanKisi']?.toString() ?? '',
      gorevYeri: json['gorevYeri']?.toString(),
      gorevi: json['gorevi']?.toString(),
      cevapVeren: json['cevapVeren']?.toString(),
      className: json['className']?.toString(),
      arsiv: json['arsiv'] as bool? ?? false,
      geriGonderildi: json['geriGonderildi'] as bool? ?? false,
      onaySirasi: _parseIntSafe(json['onaySirasi']),
      onaySureciId: _parseIntSafe(json['onaySureciId']),
      actionAdi: json['actionAdi']?.toString(),
      toplamTutar: _parseIntSafe(json['toplamTutar']),
      bekletKademe: json['bekletKademe']?.toString(),
      okundu: json['okundu']?.toString(),
      aracTuru: json['aracTuru']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onayTipi': onayTipi,
      'onayKayitID': onayKayitID,
      'olusturmaTarihi': olusturmaTarihi,
      'islemTarihi': islemTarihi,
      'onayDurumu': onayDurumu,
      'beklemeDurumu': beklemeDurumu,
      'olusturanKisi': olusturanKisi,
      'gorevYeri': gorevYeri,
      'gorevi': gorevi,
      'cevapVeren': cevapVeren,
      'className': className,
      'arsiv': arsiv,
      'geriGonderildi': geriGonderildi,
      'onaySirasi': onaySirasi,
      'onaySureciId': onaySureciId,
      'actionAdi': actionAdi,
      'toplamTutar': toplamTutar,
      'bekletKademe': bekletKademe,
      'okundu': okundu,
      'aracTuru': aracTuru,
    };
  }
}

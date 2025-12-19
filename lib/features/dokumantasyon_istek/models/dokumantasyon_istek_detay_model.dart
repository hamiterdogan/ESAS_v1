class DokumantasyonIstekDetayResponse {
  final int id;
  final int personelId;
  final DateTime? teslimTarihi;
  final int? baskiAdedi;
  final String kagitTalebi;
  final String? dokumanTuru;
  final String? departman;
  final int? paket;
  final bool a4Talebi;
  final String aciklama;
  final String baskiTuru;
  final bool onluArkali;
  final bool kopyaElden;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String? gorevYeri;
  final String? gorevi;
  final String? dosyaAdi;
  final String? dosyaAciklama;
  final int? sayfaSayisi;
  final int? toplamSayfa;
  final List<DokumantasyonOkulSatir> okullarSatir;
  final int? ogrenciSayisi;
  final DateTime? olusturmaTarihi;

  const DokumantasyonIstekDetayResponse({
    required this.id,
    required this.personelId,
    required this.teslimTarihi,
    required this.baskiAdedi,
    required this.kagitTalebi,
    required this.dokumanTuru,
    required this.departman,
    required this.paket,
    required this.a4Talebi,
    required this.aciklama,
    required this.baskiTuru,
    required this.onluArkali,
    required this.kopyaElden,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevYeri,
    required this.gorevi,
    required this.dosyaAdi,
    required this.dosyaAciklama,
    required this.sayfaSayisi,
    required this.toplamSayfa,
    required this.okullarSatir,
    required this.ogrenciSayisi,
    required this.olusturmaTarihi,
  });

  factory DokumantasyonIstekDetayResponse.fromJson(Map<String, dynamic> json) {
    // Some endpoints wrap response with { data: { ... } }
    final map = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'])
        : json;

    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final okullar =
        (map['okullarSatir'] as List?)
            ?.map(
              (e) => DokumantasyonOkulSatir.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        const <DokumantasyonOkulSatir>[];

    return DokumantasyonIstekDetayResponse(
      id: _parseInt(map['id']) ?? 0,
      personelId: _parseInt(map['personelId']) ?? 0,
      teslimTarihi: _parseDate(map['teslimTarihi']),
      baskiAdedi: _parseInt(map['baskiAdedi']),
      kagitTalebi: map['kagitTalebi']?.toString() ?? '-',
      dokumanTuru: map['dokumanTuru']?.toString(),
      departman: map['departman']?.toString(),
      paket: _parseInt(map['paket']),
      a4Talebi: map['a4Talebi'] as bool? ?? false,
      aciklama: map['aciklama']?.toString() ?? '',
      baskiTuru: map['baskiTuru']?.toString() ?? '',
      onluArkali: map['onluArkali'] as bool? ?? false,
      kopyaElden: map['kopyaElden'] as bool? ?? false,
      adSoyad: map['adSoyad']?.toString() ?? '',
      ad: map['ad']?.toString() ?? '',
      soyad: map['soyad']?.toString() ?? '',
      gorevYeri: map['gorevYeri']?.toString(),
      gorevi: map['gorevi']?.toString(),
      dosyaAdi: map['dosyaAdi']?.toString(),
      dosyaAciklama: map['dosyaAciklama']?.toString(),
      sayfaSayisi: _parseInt(map['sayfaSayisi']),
      toplamSayfa: _parseInt(map['toplamSayfa']),
      okullarSatir: okullar,
      ogrenciSayisi: _parseInt(map['ogrenciSayisi']),
      olusturmaTarihi: _parseDate(map['olusturmaTarihi']),
    );
  }

  List<String> get dosyaAdlari {
    if (dosyaAdi == null || dosyaAdi!.isEmpty) return const [];
    return dosyaAdi!
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class DokumantasyonOkulSatir {
  final String? okulKodu;
  final String? sinif;
  final String? seviye;
  final String? numara;
  final String? adi;
  final String? soyadi;

  const DokumantasyonOkulSatir({
    required this.okulKodu,
    required this.sinif,
    required this.seviye,
    required this.numara,
    required this.adi,
    required this.soyadi,
  });

  factory DokumantasyonOkulSatir.fromJson(Map<String, dynamic> json) {
    return DokumantasyonOkulSatir(
      okulKodu: json['okulKodu']?.toString(),
      sinif: json['sinif']?.toString(),
      seviye: json['seviye']?.toString(),
      numara: json['numara']?.toString(),
      adi: json['adi']?.toString(),
      soyadi: json['soyadi']?.toString(),
    );
  }
}

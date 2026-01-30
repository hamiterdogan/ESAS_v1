class TeknikDestekDetayResponse {
  final int id;
  final int personelId;
  final String adSoyad;
  final String ad;
  final String soyad;
  final String gorevi;
  final String gorevYeri;
  final String bina;
  final String hizmetTuru;
  final String aciklama;
  final String sonTarih;
  final List<TeknikDestekDetayHizmet> hizmetler;
  final String? dosyaAdi;
  final String? dosyaAciklama;
  final bool surecTamamlandi;
  final List<TeknikDestekCozum> cozumler;

  TeknikDestekDetayResponse({
    required this.id,
    required this.personelId,
    required this.adSoyad,
    required this.ad,
    required this.soyad,
    required this.gorevi,
    required this.gorevYeri,
    required this.bina,
    required this.hizmetTuru,
    required this.aciklama,
    required this.sonTarih,
    required this.hizmetler,
    this.dosyaAdi,
    this.dosyaAciklama,
    required this.surecTamamlandi,
    required this.cozumler,
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  static List<TeknikDestekDetayHizmet> _parseHizmetler(
    Map<String, dynamic> json,
  ) {
    final raw =
        json['hizmetler'] ??
        json['hizmetlerSatir'] ??
        json['hizmetSatir'] ??
        json['hizmetList'] ??
        json['hizmetDetaylari'];
    if (raw is List) {
      return raw
          .map(
            (e) => TeknikDestekDetayHizmet.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return <TeknikDestekDetayHizmet>[];
  }

  static List<TeknikDestekCozum> _parseCozumler(Map<String, dynamic> json) {
    final raw = json['cozumler'];
    if (raw is List) {
      return raw
          .map(
            (e) => TeknikDestekCozum.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return <TeknikDestekCozum>[];
  }

  factory TeknikDestekDetayResponse.fromJson(Map<String, dynamic> json) {
    return TeknikDestekDetayResponse(
      id: _parseInt(json['id'] ?? json['Id'] ?? json['onayKayitId']),
      personelId: _parseInt(json['personelId'] ?? json['PersonelId']),
      adSoyad: _readString(json, ['adSoyad', 'adsoyad', 'adSoyadStr']),
      ad: _readString(json, ['ad', 'adi', 'adStr']),
      soyad: _readString(json, ['soyad', 'soyadi', 'soyadStr']),
      gorevi: _readString(json, ['gorevi', 'gorev', 'gorevAdi']),
      gorevYeri: _readString(json, ['gorevYeri', 'gorevYeriAdi']),
      bina: _readString(json, ['bina', 'binaAdi', 'binaAd']),
      hizmetTuru: _readString(json, [
        'hizmetTuru',
        'hizmetTuruAdi',
        'hizmetAdi',
        'hizmetTur',
      ]),
      aciklama: _readString(json, [
        'aciklama',
        'aciklamaMetni',
        'talepAciklama',
      ]),
      sonTarih: _readString(json, ['sonTarih', 'sonTarihStr', 'terminTarihi']),
      hizmetler: _parseHizmetler(json),
      cozumler: _parseCozumler(json),
      dosyaAdi: json['dosyaAdi']?.toString(),
      dosyaAciklama: json['dosyaAciklama']?.toString(),
      surecTamamlandi:
          (json['surecTamamlandi'] as bool?) ??
          (json['tamamlandi'] as bool?) ??
          false,
    );
  }
}

class TeknikDestekDetayHizmet {
  final String hizmetKategori;
  final String hizmetDetay;

  TeknikDestekDetayHizmet({
    required this.hizmetKategori,
    required this.hizmetDetay,
  });

  factory TeknikDestekDetayHizmet.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) return value.toString();
      }
      return '';
    }

    return TeknikDestekDetayHizmet(
      hizmetKategori: readString([
        'hizmetKategori',
        'kategori',
        'hizmet',
        'hizmetKategoriAdi',
      ]),
      hizmetDetay: readString([
        'hizmetDetay',
        'detay',
        'aciklama',
        'hizmetDetayAciklama',
      ]),
    );
  }
}

class TeknikDestekCozum {
  final int id;
  final String? aciklama;
  final String? yazanKisi;
  final String? tarih;
  final String? ekliDosya;

  TeknikDestekCozum({
    required this.id,
    this.aciklama,
    this.yazanKisi,
    this.tarih,
    this.ekliDosya,
  });

  factory TeknikDestekCozum.fromJson(Map<String, dynamic> json) {
    return TeknikDestekCozum(
      id: json['id'] as int? ?? 0,
      aciklama: json['aciklama'] as String?,
      yazanKisi: json['yazanKisi'] as String?,
      tarih: json['tarih'] as String?,
      ekliDosya: json['ekliDosya'] as String?,
    );
  }
}

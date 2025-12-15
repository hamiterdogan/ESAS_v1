/// Araç talep formu için kullanılan model sınıfları
library;

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? -1;
  return -1;
}

/// Gidilecek yer dropdown item
class GidilecekYerItem {
  final dynamic id;
  final String yerAdi;

  GidilecekYerItem({required this.id, required this.yerAdi});

  factory GidilecekYerItem.fromJson(Map<String, dynamic> json) {
    return GidilecekYerItem(
      id: json['id'] ?? json['ID'] ?? -1,
      yerAdi:
          (json['yerAdi'] ?? json['YerAdi'] ?? json['ad'] ?? json['Ad'] ?? '')
              .toString(),
    );
  }
}

/// Görev yeri dropdown item
class GorevYeriItem {
  final int id;
  final String gorevYeriAdi;

  GorevYeriItem({required this.id, required this.gorevYeriAdi});

  factory GorevYeriItem.fromJson(Map<String, dynamic> json) {
    return GorevYeriItem(
      id: _asInt(
        json['id'] ??
            json['ID'] ??
            json['gorevYeriId'] ??
            json['GorevYeriId'] ??
            -1,
      ),
      gorevYeriAdi:
          (json['gorevYeriAdi'] ??
                  json['GorevYeriAdi'] ??
                  json['gorevYeri'] ??
                  json['GorevYeri'] ??
                  json['ad'] ??
                  json['Ad'] ??
                  '')
              .toString(),
    );
  }
}

/// Görev dropdown item
class GorevItem {
  final int id;
  final String gorevAdi;
  final int? gorevYeriId;

  GorevItem({
    required this.id,
    required this.gorevAdi,
    required this.gorevYeriId,
  });

  factory GorevItem.fromJson(Map<String, dynamic> json) {
    return GorevItem(
      id: _asInt(json['id'] ?? json['ID'] ?? json['gorevId'] ?? -1),
      gorevAdi:
          (json['gorev'] ??
                  json['Gorev'] ??
                  json['gorevAdi'] ??
                  json['Ad'] ??
                  '')
              .toString(),
      gorevYeriId: _asInt(
        json['gorevYeriId'] ?? json['GorevYeriId'] ?? json['gorevYeriID'] ?? -1,
      ),
    );
  }
}

/// Personel seçim item
class PersonelItem {
  final int personelId;
  final String adi;
  final String soyadi;
  final int? gorevId;
  final int? gorevYeriId;

  PersonelItem({
    required this.personelId,
    required this.adi,
    required this.soyadi,
    required this.gorevId,
    required this.gorevYeriId,
  });

  factory PersonelItem.fromJson(Map<String, dynamic> json) {
    return PersonelItem(
      personelId: _asInt(
        json['personelId'] ?? json['PersonelId'] ?? json['id'] ?? json['ID'],
      ),
      adi: (json['adi'] ?? json['Ad'] ?? '').toString(),
      soyadi: (json['soyadi'] ?? json['Soyad'] ?? json['Soyadi'] ?? '')
          .toString(),
      gorevId: _asInt(
        json['gorevId'] ?? json['GorevId'] ?? json['gorevID'] ?? -1,
      ),
      gorevYeriId: _asInt(
        json['gorevYeriId'] ?? json['GorevYeriId'] ?? json['gorevYeriID'] ?? -1,
      ),
    );
  }
}

/// Araç istek nedeni dropdown item
class AracIstekNedeniItem {
  final dynamic id;
  final String ad;

  AracIstekNedeniItem({required this.id, required this.ad});

  factory AracIstekNedeniItem.fromJson(Map<String, dynamic> json) {
    return AracIstekNedeniItem(
      id: json['id'] ?? json['ID'] ?? -1,
      ad:
          (json['istekNedeni'] ??
                  json['IstekNedeni'] ??
                  json['ad'] ??
                  json['Ad'] ??
                  json['name'] ??
                  json['Name'] ??
                  '')
              .toString(),
    );
  }
}

/// Öğrenci filtre item
class FilterOgrenciItem {
  final String okulKodu;
  final String seviye;
  final String sinif;
  final int numara;
  final String adi;
  final String soyadi;

  FilterOgrenciItem({
    required this.okulKodu,
    this.seviye = '',
    required this.sinif,
    required this.numara,
    required this.adi,
    required this.soyadi,
  });

  factory FilterOgrenciItem.fromJson(Map<String, dynamic> json) {
    return FilterOgrenciItem(
      okulKodu: (json['okulKodu'] ?? '').toString(),
      seviye: (json['seviye'] ?? '').toString(),
      sinif: (json['sinif'] ?? '').toString(),
      numara: _asInt(json['numara'] ?? -1),
      adi: (json['adi'] ?? '').toString(),
      soyadi: (json['soyadi'] ?? '').toString(),
    );
  }
}

/// Öğrenci filtre API yanıtı
class OgrenciFilterResponse {
  final List<String> okulKodu;
  final List<String> seviye;
  final List<String> sinif;
  final List<String> kulup;
  final List<String> takim;
  final List<FilterOgrenciItem> ogrenci;

  OgrenciFilterResponse({
    required this.okulKodu,
    required this.seviye,
    required this.sinif,
    required this.kulup,
    required this.takim,
    required this.ogrenci,
  });

  factory OgrenciFilterResponse.fromJson(Map<String, dynamic> json) {
    return OgrenciFilterResponse(
      okulKodu: List<String>.from(
        (json['okulKodu'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      seviye: List<String>.from(
        (json['seviye'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      sinif: List<String>.from(
        (json['sinif'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      kulup: List<String>.from(
        (json['kulup'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      takim: List<String>.from(
        (json['takim'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
      ),
      ogrenci: List<FilterOgrenciItem>.from(
        (json['ogrenci'] as List<dynamic>?)?.map(
              (e) => FilterOgrenciItem.fromJson(e as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }
}

/// Personel seçimi için gerekli tüm veriler
class PersonelSecimData {
  final List<PersonelItem> personeller;
  final List<GorevItem> gorevler;
  final List<GorevYeriItem> gorevYerleri;

  PersonelSecimData({
    required this.personeller,
    required this.gorevler,
    required this.gorevYerleri,
  });
}

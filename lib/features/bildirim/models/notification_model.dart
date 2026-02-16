/// Bildirim modeli - API'den gelen bildirim verileri
class BildirimModel {
  final int id;
  final String baslik;
  final String mesaj;
  final String bildirimTipi; // talep türü route path (ör: "satin_alma")
  final int? talepId;
  final String? onayTipi;
  final int? onayKayitId;
  final String aksiyonTipi; // "onay_bekliyor", "bilgilendirme", "gorev_atama"
  final bool okundu;
  final DateTime olusturmaTarihi;
  final String? gonderenAd;

  BildirimModel({
    required this.id,
    required this.baslik,
    required this.mesaj,
    required this.bildirimTipi,
    this.talepId,
    this.onayTipi,
    this.onayKayitId,
    required this.aksiyonTipi,
    required this.okundu,
    required this.olusturmaTarihi,
    this.gonderenAd,
  });

  factory BildirimModel.fromJson(Map<String, dynamic> json) {
    return BildirimModel(
      id: json['id'] as int,
      baslik: json['baslik'] as String? ?? '',
      mesaj: json['mesaj'] as String? ?? '',
      bildirimTipi: json['bildirimTipi'] as String? ?? '',
      talepId: json['talepId'] as int?,
      onayTipi: json['onayTipi'] as String?,
      onayKayitId: json['onayKayitId'] as int?,
      aksiyonTipi: json['aksiyonTipi'] as String? ?? 'bilgilendirme',
      okundu: json['okundu'] as bool? ?? false,
      olusturmaTarihi: DateTime.tryParse(json['olusturmaTarihi'] as String? ?? '') ?? DateTime.now(),
      gonderenAd: json['gonderenAd'] as String?,
    );
  }

  /// Bildirim actionable mi (onay/red yapılabilir mi)?
  bool get isActionable => aksiyonTipi == 'onay_bekliyor';

  /// Deep link route path
  String? get deepLinkRoute {
    if (talepId == null) return null;
    
    switch (bildirimTipi) {
      case 'satin_alma':
        return '/satin_alma/detay/$talepId';
      case 'arac_istek':
        return '/arac/detay/$talepId';
      case 'izin_istek':
        return '/izin/detay/$talepId';
      case 'dokumantasyon_istek':
        return '/dokumantasyon/detay/$talepId';
      case 'egitim_istek':
        return '/egitim_istek/detay/$talepId';
      case 'yiyecek_icecek_istek':
        return '/yiyecek_icecek_istek/detay/$talepId';
      case 'bilgi_teknolojileri':
        return '/bilgi_teknolojileri';
      case 'teknik_destek':
        return '/teknik_destek';
      case 'sarf_malzeme_istek':
        return '/sarf_malzeme_istek';
      default:
        return null;
    }
  }
}

/// Bildirim listesi API response modeli
class BildirimListResponse {
  final List<BildirimModel> bildirimler;
  final int toplamSayfa;
  final int toplamKayit;
  final int okunmamisSayisi;

  BildirimListResponse({
    required this.bildirimler,
    required this.toplamSayfa,
    required this.toplamKayit,
    required this.okunmamisSayisi,
  });

  factory BildirimListResponse.fromJson(Map<String, dynamic> json) {
    return BildirimListResponse(
      bildirimler: (json['bildirimler'] as List<dynamic>?)
              ?.map((e) => BildirimModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      toplamSayfa: json['toplamSayfa'] as int? ?? 0,
      toplamKayit: json['toplamKayit'] as int? ?? 0,
      okunmamisSayisi: json['okunmamisSayisi'] as int? ?? 0,
    );
  }
}

/// Token kayıt response
class TokenKaydetResponse {
  final bool basarili;
  final String? mesaj;

  TokenKaydetResponse({required this.basarili, this.mesaj});

  factory TokenKaydetResponse.fromJson(Map<String, dynamic> json) {
    return TokenKaydetResponse(
      basarili: json['basarili'] as bool? ?? false,
      mesaj: json['mesaj'] as String?,
    );
  }
}

/// Bildirim aksiyon (onay/red) response
class BildirimAksiyonResponse {
  final bool basarili;
  final String? mesaj;

  BildirimAksiyonResponse({required this.basarili, this.mesaj});

  factory BildirimAksiyonResponse.fromJson(Map<String, dynamic> json) {
    return BildirimAksiyonResponse(
      basarili: json['basarili'] as bool? ?? false,
      mesaj: json['mesaj'] as String?,
    );
  }
}
